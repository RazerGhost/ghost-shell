// The today menu's to-do list and timer (services/Planner.qml, services/Countdown.qml). Plain
// JavaScript, so it can be tested on its own (tests/tst_planner.qml). Lists are never changed in
// place: each function returns a new one, so bindings see the change.
.pragma library

// A task is { text, done }. New ones go at the end; blank text adds nothing.
function add(todos, text) {
    const trimmed = (text ?? "").trim();
    return trimmed === "" ? todos : [...todos, { text: trimmed, done: false }];
}

function toggle(todos, index) {
    return todos.map((t, i) => i === index ? { text: t.text, done: !t.done } : t);
}

function remove(todos, index) {
    return todos.filter((_, i) => i !== index);
}

function clearDone(todos) {
    return todos.filter(t => !t.done);
}

// A hand-edited file: keep only well-formed tasks.
function valid(todos) {
    return Array.isArray(todos)
        ? todos.filter(t => typeof t?.text === "string" && t.text !== "").map(t => ({ text: t.text, done: t.done === true }))
        : [];
}

// Time left as "4:05" or "1:02:03" (rounded up, so it shows 0:00 only when it's done).
function remaining(ms) {
    const total = Math.max(0, Math.ceil(ms / 1000));
    const h = Math.floor(total / 3600), m = Math.floor(total / 60) % 60, s = total % 60;
    const ss = String(s).padStart(2, "0");
    return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${ss}` : `${m}:${ss}`;
}
