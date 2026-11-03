// Which view the island shows below its top row (bar/IslandWindow.qml). Plain JavaScript, so it
// can be tested on its own (tests/tst_islandviews.qml).
.pragma library

// The open menu ("today", "settings", ...), else why the shell couldn't reload ("reload"), else
// the hover view ("media", as "peek-media"), else "". `panel` is the open menu on this screen (""
// for none), `reloadFailed` whether the reload error is showing, `peek` the hover view ("" for
// none).
function shown(panel, reloadFailed, peek) {
    if (panel !== "")
        return panel;
    if (reloadFailed)
        return "reload";
    return peek !== "" ? "peek-" + peek : "";
}
