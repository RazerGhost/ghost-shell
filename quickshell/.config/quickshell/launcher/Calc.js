// The launcher's calculator, around `qalc` (libqalculate): which searches are sums or unit
// conversions, how to ask, and what the answer is. Plain JavaScript, so it can be tested on its
// own (tests/tst_calc.qml).
.pragma library

// A digit plus an operator, a conversion or a function: "2^10", "5 km in miles", "sqrt(16)",
// "20% of 80". App names ("2048", "7-Zip" aside) rarely look like that.
function isExpression(query) {
    const q = query.trim();
    return /\d/.test(q) && (/[+*\/^%×÷()=]|\d\s*-\s*\d/.test(q) || /\s(to|in)\s+\S/i.test(q)
        || /\b(sqrt|sin|cos|tan|log|ln|abs|round)\b/i.test(q));
}

// What qalc gets: "in" and "to" before the target unit become "to -", which qalc reads as a
// conversion without mixed units ("3.1 mi", not "3 mi + 188 yd + 2.4 in"; "in" alone would be
// inches).
function prepare(query) {
    return query.trim().replace(/\s+(?:in|to)\s+-?(?=[^\s\d])/i, " to -");
}

// The answer from qalc's output (its last line; warnings come before it), or "" when there's
// nothing worth showing: empty, an error, or just the question back.
function answer(output, query) {
    const lines = output.split("\n").map(l => l.trim()).filter(l => l !== "");
    const last = lines.length > 0 ? lines[lines.length - 1] : "";
    if (last === "" || /error|unrecognized/i.test(last) || last === query.trim())
        return "";
    return last;
}
