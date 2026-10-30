import QtQuick
import qs.theme

// A row of tiles (SheetTile) filling an editor sheet's width, all `tileHeight` high: grouped
// modules like Android's "Wallpaper & style" and macOS's Control Center, rather than loose
// controls. A tile with a `natural` width (its content's) takes that; the others share the
// rest by `weight`.
Row {
    id: root

    property real tileHeight: Theme.editor.tile

    readonly property var tiles: {
        const list = [];
        for (const child of children)
            if (child.visible && child.weight !== undefined)
                list.push(child);
        return list;
    }
    readonly property real fixedWidth: tiles.reduce((sum, t) => sum + (t.natural > 0 ? t.natural + Theme.spacing.m * 2 : 0), 0)
    readonly property real totalWeight: Math.max(tiles.reduce((sum, t) => sum + (t.natural > 0 ? 0 : t.weight), 0), 0.001)
    // One weight's width, of what the natural-width tiles leave.
    readonly property real unit: (width - spacing * Math.max(tiles.length - 1, 0) - fixedWidth) / totalWeight

    x: Theme.spacing.l
    width: (parent?.width ?? 0) - Theme.spacing.l * 2
    topPadding: Theme.spacing.m
    bottomPadding: Theme.spacing.m
    spacing: Theme.spacing.m
}
