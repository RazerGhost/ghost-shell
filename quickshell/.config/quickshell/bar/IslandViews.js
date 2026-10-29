// Which view the island shows below its top row (bar/IslandWindow.qml). Plain JavaScript, so it
// can be tested on its own (tests/tst_islandviews.qml).
.pragma library

// An open menu wins; then the shell-reload notice, the notification pop-up, a window asking for
// attention, and a hover view ("media" -> "peek-media"). "" for none. `panel` is the open menu
// on this screen ("" for none); the others are whether each is there.
function shown(panel, reload, notification, attention, peek) {
    if (panel !== "")
        return panel;
    if (reload)
        return "reload";
    if (notification)
        return "notification";
    if (attention)
        return "attention";
    return peek !== "" ? "peek-" + peek : "";
}
