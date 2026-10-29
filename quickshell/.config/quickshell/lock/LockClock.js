// The lock and login screens' clock (Settings -> Lock screen -> Clock): its styles, sizes and
// where it sits. Plain JavaScript, so it can be tested on its own (tests/tst_lockclock.qml).
.pragma library

const styles = ["big", "stacked", "thin", "analog"];
const layouts = ["top", "center", "left"]; // left: the clock in the bottom-left corner
const sizes = [75, 100, 125, 150];         // percent of Theme.lock.clock

// One of `allowed`, else the first (the default): a hand-edited settings file can't hide the clock.
function pick(value, allowed) {
    return allowed.includes(value) ? value : allowed[0];
}

// The digits as text: { hours, minutes, suffix }; suffix is "AM"/"PM" with the 12-hour clock.
function digits(date, h24) {
    const h = date.getHours();
    const minutes = String(date.getMinutes()).padStart(2, "0");
    if (h24)
        return { hours: String(h).padStart(2, "0"), minutes, suffix: "" };
    return { hours: String(h % 12 || 12), minutes, suffix: h < 12 ? "AM" : "PM" };
}

// The analog clock's hands, in degrees clockwise from 12. The hour hand moves with the minutes.
function hands(date) {
    const m = date.getMinutes();
    return { hour: (date.getHours() % 12) * 30 + m / 2, minute: m * 6 };
}
