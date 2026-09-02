# Google Calendar + Tasks setup

The shell talks to Google with **your own** OAuth client — there's no shared
app to sign into. One-time, ~10 minutes.

## 1. Create a project

1. Go to <https://console.cloud.google.com/> and create a new project
   (top bar → project picker → *New project*). Name it anything.

## 2. Enable the APIs

In *APIs & Services → Library*, enable both:

- **Google Calendar API**
- **Google Tasks API**

## 3. Configure the OAuth consent screen

*APIs & Services → OAuth consent screen*

- User type: **External**, *Create*.
- App name / support email / developer email: fill in (anything sane).
- *Scopes*: you can leave this empty — the shell requests its scopes at
  sign-in time.
- *Test users*: add your own Google address(es).
- Save.

> **Publish the app.** On the consent screen, click **Publish app** (→ *In
> production*). No Google review or verification is required for personal use
> (under 100 users). If you leave it in *Testing*, Google **expires the refresh
> token after 7 days** and you have to reconnect every week.

## 4. Create the OAuth client

*APIs & Services → Credentials → Create credentials → OAuth client ID*

- Application type: **Desktop app**
- Name: anything
- *Create* → a dialog shows the **Client ID** and **Client secret**.

The shell uses a loopback redirect (`http://127.0.0.1:<random-port>/`), which
Desktop-app clients allow automatically — nothing to configure.

## 5. Connect it in the shell

1. Open **Settings → Calendar**.
2. Paste the **Client ID** and **Client secret**, *Save credentials*.
3. **Add account** → your browser opens → pick the Google account, approve.
   You'll see an "unverified app" warning (it's your own app) — *Advanced →
   Go to … (unsafe)*.
4. Repeat *Add account* for as many Google accounts as you want.

Events and tasks then show up in the bar clock's calendar dropdown. Manage
which calendars are visible, the sync interval and the quick-add task list from
the same Settings page.

## Where things live

- `~/.config/quickshell/google/client.json` — your client ID + secret
- `~/.config/quickshell/google/<email>.json` — per-account tokens (mode 600)
- `~/.config/quickshell/google/data.json` — the synced events/tasks the shell reads

All git-ignored. *Remove* an account in Settings to revoke its token and delete
the file.

## CLI

```
qs ipc call gcal sync      # force a sync now
qs ipc call gcal login     # add an account
qs ipc call gcal status
scripts/gcal.py --help     # the bridge script directly
```
