.pragma library

// The launcher's math mode. Small on purpose: the shell doesn't depend on
// qalc, and running a search box's contents through eval() would hand every
// keystroke to the JS engine. This is a plain recursive-descent parser over a
// fixed grammar instead — anything it doesn't recognise is simply not a sum.
//
//   expr  := term (('+' | '-') term)*
//   term  := unary (('*' | '/' | '%') unary)*
//   unary := ('-' | '+')* power
//   power := atom ('^' unary)?          right-associative
//   atom  := number | constant | name '(' args ')' | '(' expr ')'

const FUNCS = {
    "sqrt": Math.sqrt, "cbrt": Math.cbrt, "abs": Math.abs,
    "round": Math.round, "floor": Math.floor, "ceil": Math.ceil,
    "ln": Math.log, "log": Math.log10, "log2": Math.log2, "exp": Math.exp,
    "sin": Math.sin, "cos": Math.cos, "tan": Math.tan,
    "asin": Math.asin, "acos": Math.acos, "atan": Math.atan,
    "min": Math.min, "max": Math.max, "pow": Math.pow, "hypot": Math.hypot
};

const CONSTS = { "pi": Math.PI, "e": Math.E, "tau": Math.PI * 2 };

// Whether an expression is worth *offering* a result for when the user hasn't
// asked for math by prefix. A bare "42" parses fine but saying "42 = 42" in
// the result list only gets in the way of the apps below it.
function looksLikeMath(src) {
    return /[-+*/%^]/.test(src.slice(1)) || /[a-z]+\s*\(/i.test(src);
}

function evaluate(src) {
    const text = String(src || "").trim();
    if (text.length === 0)
        return { ok: false };

    // The whole tokenizer: numbers, names, and single-character operators.
    const tokens = text.match(/\d*\.?\d+(?:[eE][-+]?\d+)?|[A-Za-z_][A-Za-z_0-9]*|\S/g);
    if (!tokens)
        return { ok: false };

    let i = 0;
    const peek = () => tokens[i];
    const next = () => tokens[i++];
    const eat = t => (tokens[i] === t ? (i++, true) : false);

    function atom() {
        const t = next();
        if (t === undefined)
            throw "end of input";

        if (t === "(") {
            const v = expr();
            if (!eat(")")) throw "unclosed (";
            return v;
        }
        if (/^\d|^\./.test(t)) {
            const v = parseFloat(t);
            if (isNaN(v)) throw "bad number " + t;
            return v;
        }
        if (/^[A-Za-z_]/.test(t)) {
            const name = t.toLowerCase();
            if (peek() === "(") {
                const fn = FUNCS[name];
                if (!fn) throw "unknown function " + name;
                next();
                const args = [];
                if (!eat(")")) {
                    do { args.push(expr()); } while (eat(","));
                    if (!eat(")")) throw "unclosed (";
                }
                return fn.apply(null, args);
            }
            if (name in CONSTS)
                return CONSTS[name];
            throw "unknown name " + name;
        }
        throw "unexpected " + t;
    }

    function power() {
        const base = atom();
        return eat("^") ? Math.pow(base, unary()) : base;
    }

    function unary() {
        if (eat("-")) return -unary();
        if (eat("+")) return unary();
        return power();
    }

    function term() {
        let v = unary();
        for (;;) {
            if (eat("*")) v *= unary();
            else if (eat("/")) v /= unary();
            else if (eat("%")) v %= unary();
            else return v;
        }
    }

    function expr() {
        let v = term();
        for (;;) {
            if (eat("+")) v += term();
            else if (eat("-")) v -= term();
            else return v;
        }
    }

    try {
        const value = expr();
        // Trailing junk means we only understood a prefix of what was typed,
        // which is not the same as understanding it.
        if (i !== tokens.length || typeof value !== "number" || isNaN(value))
            return { ok: false };
        return { ok: true, value: value, text: format(value) };
    } catch (e) {
        return { ok: false };
    }
}

// Enough digits to be useful, few enough that binary floating point doesn't
// show through as 0.30000000000000004.
function format(v) {
    if (!isFinite(v))
        return v > 0 ? "∞" : "-∞";
    if (Number.isInteger(v) && Math.abs(v) < 1e15)
        return String(v);
    const a = Math.abs(v);
    if (a < 1e-6 || a >= 1e12)
        return v.toExponential(6).replace(/\.?0+e/, "e");
    return String(parseFloat(v.toPrecision(12)));
}
