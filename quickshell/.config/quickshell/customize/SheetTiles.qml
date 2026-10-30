import QtQuick
import qs.theme

// A row of tiles (SheetTile) filling an editor sheet's width, all `tileHeight` high: grouped
// modules like Android's "Wallpaper & style" and macOS's Control Center, rather than loose
// controls. A tile with a `natural` width (its content's) takes that; the others share the
// rest by `weight`.
Row {
    id: root

    property real tileHeight: Theme.editor.tile

    // Every tile, shown or not: on a tab that isn't showing, every child reports `visible` false,
    // and dividing the width among no tiles made each millions of px wide (a texture the size
    // of that froze the shell; NOTES).
    readonly property var tiles: Array.from(children).filter(child => child.weight !== undefined)
    readonly property real fixedWidth: tiles.reduce((sum, t) => sum + (t.natural > 0 ? t.natural + Theme.spacing.m * 2 : 0), 0)
    readonly property real totalWeight: Math.max(tiles.reduce((sum, t) => sum + (t.natural > 0 ? 0 : t.weight), 0), 1)
    // One weight's width, of what the natural-width tiles leave.
    readonly property real unit: (width - spacing * Math.max(tiles.length - 1, 0) - fixedWidth) / totalWeight

    x: Theme.spacing.l
    width: (parent?.width ?? 0) - Theme.spacing.l * 2
    topPadding: Theme.spacing.m
    bottomPadding: Theme.spacing.m
    spacing: Theme.spacing.m
}
