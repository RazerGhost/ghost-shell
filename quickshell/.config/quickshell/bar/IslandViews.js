// Which view the island shows below its top row (bar/IslandWindow.qml). Plain JavaScript, so it
// can be tested on its own (tests/tst_islandviews.qml).
.pragma library

// The open menu ("today", "settings", ...), else the hover view ("media", as "peek-media"), else
// "". `panel` is the open menu on this screen ("" for none), `peek` the hover view ("" for none).
function shown(panel, peek) {
    if (panel !== "")
        return panel;
    return peek !== "" ? "peek-" + peek : "";
}
