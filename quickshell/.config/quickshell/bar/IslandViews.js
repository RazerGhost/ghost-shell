// Which view the island shows below its top row (bar/IslandWindow.qml). Plain JavaScript, so it
// can be tested on its own (tests/tst_islandviews.qml).
.pragma library

// The open menu ("today", "settings", ...), else why the shell couldn't reload ("reload"), else
// the notification pop-up ("notification"), else a window asking for attention ("attention"),
// else the hover view ("media", as "peek-media"), else "". `panel` is the open menu on this screen
// ("" for none), `peek` the hover view ("" for none); the others are whether each is there.
function shown(panel, reloadFailed, notification, attention, peek) {
    if (panel !== "")
        return panel;
    if (reloadFailed)
        return "reload";
    if (notification)
        return "notification";
    if (attention)
        return "attention";
    return peek !== "" ? "peek-" + peek : "";
}
