#!/usr/bin/env python3
"""Google Calendar + Google Tasks bridge for the Quickshell shell.

All Google I/O lives here (QML has no usable loopback HTTP server and
token-refresh in QML is fragile). One-shot subcommands, stdlib only — same
shape as the niri-*.py helpers next door.

  scripts/gcal.py <subcommand> [args]

Data dir: ~/.config/quickshell/google/  (mode 700)
  client.json     {client_id, client_secret}         written by Settings
  <email>.json    {email, refresh_token, token, expiry, scopes, needsReauth}
  data.json       merged synced state — the shell reads this
  colors.json     cached Google colour palette

Subcommands (JSON on stdout; exit 0 ok, 1 error with {"error": "..."}):
  accounts
  login
  logout       <email>
  sync         [--days-back N] [--days-fwd N]
  event-add    <account> <calendarId>  --title T [--start ISO --end ISO |
                                        --all-day YYYY-MM-DD] [--location L] [--desc D]
  event-edit   <account> <calendarId> <eventId>  [same flags]
  event-delete <account> <calendarId> <eventId>
  task-add     <account> <listId>  --title T [--due YYYY-MM-DD] [--notes N] [--parent ID]
  task-edit    <account> <listId> <taskId>  [--title T] [--due YYYY-MM-DD | --clear-due] [--notes N]
  task-toggle  <account> <listId> <taskId>  <completed|needsAction>
  task-delete  <account> <listId> <taskId>

Secrets (client_secret, refresh/access tokens) are only ever read from files,
never passed on argv.
"""
import argparse
import base64
import glob
import hashlib
import http.server
import json
import os
import secrets
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
from datetime import datetime, timedelta, timezone

HOME = os.path.expanduser("~")
DATA_DIR = os.path.join(HOME, ".config", "quickshell", "google")
CLIENT_FILE = os.path.join(DATA_DIR, "client.json")
DATA_FILE = os.path.join(DATA_DIR, "data.json")
COLORS_FILE = os.path.join(DATA_DIR, "colors.json")
RESERVED = {"client", "data", "colors"}

AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URL = "https://oauth2.googleapis.com/token"
REVOKE_URL = "https://oauth2.googleapis.com/revoke"
USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo"
CAL_BASE = "https://www.googleapis.com/calendar/v3"
TASKS_BASE = "https://tasks.googleapis.com/tasks/v1"
SCOPES = [
    "openid",
    "email",
    "https://www.googleapis.com/auth/calendar",
    "https://www.googleapis.com/auth/tasks",
]


# --------------------------------------------------------------------------- io
def die(msg):
    print(json.dumps({"error": str(msg)}))
    sys.exit(1)


def out(obj):
    print(json.dumps(obj))
    sys.exit(0)


def log(*a):
    print("[gcal]", *a, file=sys.stderr)


def ensure_dir():
    os.makedirs(DATA_DIR, exist_ok=True)
    try:
        os.chmod(DATA_DIR, 0o700)
    except OSError:
        pass


def read_json(path, default=None):
    try:
        with open(path, "r") as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def write_json(path, obj, mode=0o600):
    ensure_dir()
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(obj, f, indent=2)
    os.replace(tmp, path)
    try:
        os.chmod(path, mode)
    except OSError:
        pass


def account_path(email):
    return os.path.join(DATA_DIR, email + ".json")


def list_account_files():
    files = []
    for p in sorted(glob.glob(os.path.join(DATA_DIR, "*.json"))):
        name = os.path.splitext(os.path.basename(p))[0]
        if name in RESERVED:
            continue
        files.append(p)
    return files


def load_client():
    c = read_json(CLIENT_FILE)
    if not c or not c.get("client_id") or not c.get("client_secret"):
        die("no client.json — add your OAuth Client ID / secret in Settings › Calendar")
    return c


# ------------------------------------------------------------------------- http
class ApiError(Exception):
    def __init__(self, status, body):
        super().__init__(f"HTTP {status}: {body}")
        self.status = status
        self.body = body


def _request(method, url, headers=None, data=None):
    req = urllib.request.Request(url, method=method, data=data, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()
            if not raw:
                return None
            return json.loads(raw)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")
        raise ApiError(e.code, body)
    except urllib.error.URLError as e:
        raise ApiError(0, str(e.reason))


def form_post(url, fields):
    data = urllib.parse.urlencode(fields).encode()
    return _request("POST", url, {"Content-Type": "application/x-www-form-urlencoded"}, data)


def api(method, url, token, body=None):
    headers = {"Authorization": "Bearer " + token}
    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode()
    return _request(method, url, headers, data)


# ------------------------------------------------------------------------ token
def token_valid(acc):
    return acc.get("token") and acc.get("expiry", 0) > time.time() + 60


def refresh_token(acc):
    """Refresh acc['token'] in place. Sets needsReauth on invalid_grant."""
    client = load_client()
    try:
        res = form_post(TOKEN_URL, {
            "client_id": client["client_id"],
            "client_secret": client["client_secret"],
            "grant_type": "refresh_token",
            "refresh_token": acc["refresh_token"],
        })
    except ApiError as e:
        if "invalid_grant" in (e.body or ""):
            acc["needsReauth"] = True
            write_json(account_path(acc["email"]), acc)
            raise ApiError(e.status, "invalid_grant — sign in again")
        raise
    acc["token"] = res["access_token"]
    acc["expiry"] = time.time() + int(res.get("expires_in", 3600))
    acc["needsReauth"] = False
    if res.get("refresh_token"):
        acc["refresh_token"] = res["refresh_token"]
    write_json(account_path(acc["email"]), acc)
    return acc


def valid_token(acc):
    if not token_valid(acc):
        refresh_token(acc)
    return acc["token"]


def api_auth(method, url, acc, body=None):
    """api() that refreshes once on a 401."""
    token = valid_token(acc)
    try:
        return api(method, url, token, body)
    except ApiError as e:
        if e.status == 401:
            refresh_token(acc)
            return api(method, url, acc["token"], body)
        raise


# ------------------------------------------------------------------------- auth
class _Catch(http.server.BaseHTTPRequestHandler):
    result = {}

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        q = urllib.parse.parse_qs(parsed.query)
        if "code" in q or "error" in q:
            _Catch.result = {k: v[0] for k, v in q.items()}
            msg = b"<h2>You can close this tab.</h2>"
        else:
            msg = b"<h2>Waiting for Google...</h2>"
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(msg)

    def log_message(self, *a):
        pass


def cmd_login():
    client = load_client()
    verifier = base64.urlsafe_b64encode(secrets.token_bytes(64)).rstrip(b"=").decode()
    challenge = base64.urlsafe_b64encode(
        hashlib.sha256(verifier.encode()).digest()
    ).rstrip(b"=").decode()
    state = secrets.token_urlsafe(16)

    httpd = http.server.HTTPServer(("127.0.0.1", 0), _Catch)
    _Catch.result = {}
    port = httpd.server_address[1]
    redirect_uri = f"http://127.0.0.1:{port}/"

    params = {
        "client_id": client["client_id"],
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": " ".join(SCOPES),
        "code_challenge": challenge,
        "code_challenge_method": "S256",
        "state": state,
        "access_type": "offline",
        "prompt": "consent",
    }
    url = AUTH_URL + "?" + urllib.parse.urlencode(params)
    log("opening browser for consent")
    webbrowser.open(url)

    deadline = time.time() + 180
    httpd.timeout = 2
    while not _Catch.result and time.time() < deadline:
        httpd.handle_request()
    httpd.server_close()

    res = _Catch.result
    if not res:
        die("timed out waiting for the browser")
    if res.get("error"):
        die("consent denied: " + res["error"])
    if res.get("state") != state:
        die("state mismatch — aborted")

    try:
        tok = form_post(TOKEN_URL, {
            "client_id": client["client_id"],
            "client_secret": client["client_secret"],
            "grant_type": "authorization_code",
            "code": res["code"],
            "code_verifier": verifier,
            "redirect_uri": redirect_uri,
        })
    except ApiError as e:
        die("token exchange failed: " + (e.body or str(e)))

    if not tok.get("refresh_token"):
        die("Google returned no refresh token — remove the app's access at "
            "myaccount.google.com/permissions and try again")

    info = _request("GET", USERINFO_URL,
                    {"Authorization": "Bearer " + tok["access_token"]})
    email = (info or {}).get("email")
    if not email:
        die("could not read the account email")

    acc = {
        "email": email,
        "refresh_token": tok["refresh_token"],
        "token": tok["access_token"],
        "expiry": time.time() + int(tok.get("expires_in", 3600)),
        "scopes": tok.get("scope", "").split(),
        "needsReauth": False,
    }
    write_json(account_path(email), acc)
    out({"ok": True, "email": email})


def cmd_logout(email):
    acc = read_json(account_path(email))
    if acc and acc.get("refresh_token"):
        try:
            form_post(REVOKE_URL, {"token": acc["refresh_token"]})
        except ApiError:
            pass
    try:
        os.remove(account_path(email))
    except OSError:
        pass
    out({"ok": True})


def cmd_accounts():
    res = []
    for p in list_account_files():
        acc = read_json(p) or {}
        res.append({
            "email": acc.get("email", os.path.splitext(os.path.basename(p))[0]),
            "expired": not token_valid(acc),
            "needsReauth": bool(acc.get("needsReauth")),
        })
    out(res)


# ------------------------------------------------------------------------ sync
def get_colors(any_acc):
    cached = read_json(COLORS_FILE)
    if cached and cached.get("_fetched", 0) > time.time() - 86400:
        return cached
    try:
        c = api_auth("GET", CAL_BASE + "/colors", any_acc)
        c["_fetched"] = time.time()
        write_json(COLORS_FILE, c)
        return c
    except ApiError:
        return cached or {"event": {}, "calendar": {}}


def paged(method, url, acc):
    """Yield every item across all pages of a Google list endpoint."""
    page_token = None
    while True:
        u = url
        if page_token:
            u += ("&" if "?" in u else "?") + "pageToken=" + page_token
        res = api_auth(method, u, acc) or {}
        for item in res.get("items", []):
            yield item
        page_token = res.get("nextPageToken")
        if not page_token:
            break


def rfc3339(dt):
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sync_account(acc, colors, time_min, time_max):
    email = acc["email"]
    ev_colors = (colors or {}).get("event", {})
    calendars, events, task_lists, tasks = [], [], [], []

    for cal in paged("GET", CAL_BASE + "/users/me/calendarList", acc):
        cid = cal["id"]
        key = email + " " + cid
        role = cal.get("accessRole", "reader")
        cal_bg = cal.get("backgroundColor", "#4285f4")
        calendars.append({
            "key": key, "id": cid, "accountEmail": email,
            "summary": cal.get("summaryOverride") or cal.get("summary", cid),
            "primary": bool(cal.get("primary")),
            "bg": cal_bg, "fg": cal.get("foregroundColor", "#ffffff"),
            "accessRole": role,
            "selected": cal.get("selected", True),
        })
        if not cal.get("selected", True):
            continue
        url = (CAL_BASE + "/calendars/" + urllib.parse.quote(cid, safe="")
               + "/events?singleEvents=true&orderBy=startTime&maxResults=2500"
               + "&timeMin=" + urllib.parse.quote(time_min)
               + "&timeMax=" + urllib.parse.quote(time_max))
        for ev in paged("GET", url, acc):
            if ev.get("status") == "cancelled":
                continue
            s, e = ev.get("start", {}), ev.get("end", {})
            all_day = "date" in s
            ev_bg = cal_bg
            if ev.get("colorId") and str(ev["colorId"]) in ev_colors:
                ev_bg = ev_colors[str(ev["colorId"])].get("background", cal_bg)
            events.append({
                "key": email + " " + ev["id"],
                "id": ev["id"],
                "calendarKey": key, "calendarId": cid, "accountEmail": email,
                "title": ev.get("summary", "(no title)"),
                "description": ev.get("description", ""),
                "location": ev.get("location", ""),
                "start": s.get("date") or s.get("dateTime", ""),
                "end": e.get("date") or e.get("dateTime", ""),
                "allDay": all_day,
                "recurringEventId": ev.get("recurringEventId", ""),
                "htmlLink": ev.get("htmlLink", ""),
                "bg": ev_bg,
                "editable": role in ("owner", "writer"),
            })

    for tl in paged("GET", TASKS_BASE + "/users/@me/lists", acc):
        lid = tl["id"]
        lkey = email + " " + lid
        task_lists.append({
            "key": lkey, "id": lid, "accountEmail": email,
            "title": tl.get("title", lid),
        })
        turl = (TASKS_BASE + "/lists/" + urllib.parse.quote(lid, safe="")
                + "/tasks?showCompleted=true&showHidden=false&maxResults=100")
        for t in paged("GET", turl, acc):
            tasks.append({
                "key": email + " " + t["id"],
                "id": t["id"],
                "taskListKey": lkey, "taskListId": lid, "accountEmail": email,
                "title": t.get("title", ""),
                "notes": t.get("notes", ""),
                "due": t.get("due", ""),
                "status": t.get("status", "needsAction"),
                "completed": t.get("completed", ""),
                "position": t.get("position", ""),
                "parent": t.get("parent", ""),
            })

    return calendars, events, task_lists, tasks


def cmd_sync(days_back, days_fwd):
    files = list_account_files()
    now = datetime.now(timezone.utc)
    time_min = rfc3339(now - timedelta(days=days_back))
    time_max = rfc3339(now + timedelta(days=days_fwd))

    data = {
        "syncedAt": rfc3339(now),
        "accounts": [], "calendars": [], "events": [],
        "taskLists": [], "tasks": [],
    }
    colors = None
    for p in files:
        acc = read_json(p)
        if not acc:
            continue
        email = acc.get("email", "?")
        try:
            if colors is None:
                colors = get_colors(acc)
            c, e, tl, t = sync_account(acc, colors, time_min, time_max)
            data["calendars"] += c
            data["events"] += e
            data["taskLists"] += tl
            data["tasks"] += t
            data["accounts"].append({"email": email, "error": None})
        except ApiError as err:
            log("sync failed for", email, "-", err)
            reason = "reauth" if "invalid_grant" in str(err) else str(err)[:200]
            data["accounts"].append({"email": email, "error": reason})

    data["events"].sort(key=lambda x: x["start"])
    write_json(DATA_FILE, data, mode=0o600)
    out({"ok": True, "accounts": len(data["accounts"]),
         "events": len(data["events"]), "tasks": len(data["tasks"])})


# ---------------------------------------------------------------- event / task
def load_acc_or_die(email):
    acc = read_json(account_path(email))
    if not acc:
        die("no such account: " + email)
    return acc


def _event_body(a, existing=None):
    body = {}
    if a.title is not None:
        body["summary"] = a.title
    if a.location is not None:
        body["location"] = a.location
    if a.desc is not None:
        body["description"] = a.desc
    if a.all_day:
        end = a.all_day_end or a.all_day
        body["start"] = {"date": a.all_day}
        body["end"] = {"date": end}
    elif a.start or a.end:
        if a.start:
            body["start"] = {"dateTime": _norm_dt(a.start)}
        if a.end:
            body["end"] = {"dateTime": _norm_dt(a.end)}
    return body


def _norm_dt(s):
    """Accept 'YYYY-MM-DDTHH:MM' (local) or a full RFC3339 string."""
    s = s.strip()
    try:
        if len(s) == 16:
            dt = datetime.fromisoformat(s).astimezone()
            return dt.isoformat()
    except ValueError:
        pass
    return s


def cmd_event_add(a):
    acc = load_acc_or_die(a.account)
    body = _event_body(a)
    if not body.get("start"):
        die("event needs --start/--end or --all-day")
    url = CAL_BASE + "/calendars/" + urllib.parse.quote(a.calendarId, safe="") + "/events"
    res = api_auth("POST", url, acc, body)
    out({"ok": True, "id": res.get("id")})


def cmd_event_edit(a):
    acc = load_acc_or_die(a.account)
    body = _event_body(a)
    if not body:
        die("nothing to change")
    url = (CAL_BASE + "/calendars/" + urllib.parse.quote(a.calendarId, safe="")
           + "/events/" + urllib.parse.quote(a.eventId, safe=""))
    res = api_auth("PATCH", url, acc, body)
    out({"ok": True, "id": res.get("id")})


def cmd_event_delete(a):
    acc = load_acc_or_die(a.account)
    url = (CAL_BASE + "/calendars/" + urllib.parse.quote(a.calendarId, safe="")
           + "/events/" + urllib.parse.quote(a.eventId, safe=""))
    api_auth("DELETE", url, acc)
    out({"ok": True})


def _due_rfc(day):
    return day + "T00:00:00.000Z"


def cmd_task_add(a):
    acc = load_acc_or_die(a.account)
    body = {"title": a.title}
    if a.notes is not None:
        body["notes"] = a.notes
    if a.due:
        body["due"] = _due_rfc(a.due)
    url = TASKS_BASE + "/lists/" + urllib.parse.quote(a.listId, safe="") + "/tasks"
    if a.parent:
        url += "?parent=" + urllib.parse.quote(a.parent, safe="")
    res = api_auth("POST", url, acc, body)
    out({"ok": True, "id": res.get("id")})


def cmd_task_edit(a):
    acc = load_acc_or_die(a.account)
    body = {}
    if a.title is not None:
        body["title"] = a.title
    if a.notes is not None:
        body["notes"] = a.notes
    if a.clear_due:
        body["due"] = None
    elif a.due:
        body["due"] = _due_rfc(a.due)
    if not body:
        die("nothing to change")
    url = (TASKS_BASE + "/lists/" + urllib.parse.quote(a.listId, safe="")
           + "/tasks/" + urllib.parse.quote(a.taskId, safe=""))
    api_auth("PATCH", url, acc, body)
    out({"ok": True})


def cmd_task_toggle(a):
    acc = load_acc_or_die(a.account)
    if a.status == "completed":
        body = {"status": "completed"}
    else:
        body = {"status": "needsAction", "completed": None}
    url = (TASKS_BASE + "/lists/" + urllib.parse.quote(a.listId, safe="")
           + "/tasks/" + urllib.parse.quote(a.taskId, safe=""))
    api_auth("PATCH", url, acc, body)
    out({"ok": True})


def cmd_task_delete(a):
    acc = load_acc_or_die(a.account)
    url = (TASKS_BASE + "/lists/" + urllib.parse.quote(a.listId, safe="")
           + "/tasks/" + urllib.parse.quote(a.taskId, safe=""))
    api_auth("DELETE", url, acc)
    out({"ok": True})


# ------------------------------------------------------------------------- main
def build_parser():
    p = argparse.ArgumentParser(prog="gcal.py", description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("accounts")
    sub.add_parser("login")
    lo = sub.add_parser("logout")
    lo.add_argument("email")

    sy = sub.add_parser("sync")
    sy.add_argument("--days-back", type=int, default=7)
    sy.add_argument("--days-fwd", type=int, default=60)

    def ev_flags(sp):
        sp.add_argument("--title")
        sp.add_argument("--start")
        sp.add_argument("--end")
        sp.add_argument("--all-day", dest="all_day")
        sp.add_argument("--all-day-end", dest="all_day_end")
        sp.add_argument("--location")
        sp.add_argument("--desc")

    ea = sub.add_parser("event-add")
    ea.add_argument("account"); ea.add_argument("calendarId"); ev_flags(ea)
    ee = sub.add_parser("event-edit")
    ee.add_argument("account"); ee.add_argument("calendarId"); ee.add_argument("eventId"); ev_flags(ee)
    ed = sub.add_parser("event-delete")
    ed.add_argument("account"); ed.add_argument("calendarId"); ed.add_argument("eventId")

    ta = sub.add_parser("task-add")
    ta.add_argument("account"); ta.add_argument("listId")
    ta.add_argument("--title", required=True)
    ta.add_argument("--due"); ta.add_argument("--notes"); ta.add_argument("--parent")
    te = sub.add_parser("task-edit")
    te.add_argument("account"); te.add_argument("listId"); te.add_argument("taskId")
    te.add_argument("--title"); te.add_argument("--due")
    te.add_argument("--clear-due", action="store_true"); te.add_argument("--notes")
    tt = sub.add_parser("task-toggle")
    tt.add_argument("account"); tt.add_argument("listId"); tt.add_argument("taskId")
    tt.add_argument("status", choices=["completed", "needsAction"])
    td = sub.add_parser("task-delete")
    td.add_argument("account"); td.add_argument("listId"); td.add_argument("taskId")

    return p


def main():
    a = build_parser().parse_args()
    ensure_dir()
    try:
        if a.cmd == "accounts":
            cmd_accounts()
        elif a.cmd == "login":
            cmd_login()
        elif a.cmd == "logout":
            cmd_logout(a.email)
        elif a.cmd == "sync":
            cmd_sync(a.days_back, a.days_fwd)
        elif a.cmd == "event-add":
            cmd_event_add(a)
        elif a.cmd == "event-edit":
            cmd_event_edit(a)
        elif a.cmd == "event-delete":
            cmd_event_delete(a)
        elif a.cmd == "task-add":
            cmd_task_add(a)
        elif a.cmd == "task-edit":
            cmd_task_edit(a)
        elif a.cmd == "task-toggle":
            cmd_task_toggle(a)
        elif a.cmd == "task-delete":
            cmd_task_delete(a)
    except ApiError as e:
        die(e)
    except BrokenPipeError:
        pass


if __name__ == "__main__":
    main()
