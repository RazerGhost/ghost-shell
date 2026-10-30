import QtQuick
import qs.theme

// A row of tiles (SheetTile) filling an editor sheet's width, all the same height, each as wide
// as its `weight` gives it: grouped modules like Android's "Wallpaper & style" and macOS's
// Control Center, rather than loose controls.
Row {
    id: root

    readonly property real totalWeight: {
        let total = 0;
        for (const child of children)
            if (child.visible && child.weight !== undefined)
                total += child.weight;
        return Math.max(total, 1);
    }
    readonly property int shown: {
        let count = 0;
        for (const child of children)
            if (child.visible && child.weight !== undefined)
                count++;
        return count;
    }
    // One weight's width.
    readonly property real unit: (width - spacing * Math.max(shown - 1, 0)) / totalWeight

    x: Theme.spacing.l
    width: (parent?.width ?? 0) - Theme.spacing.l * 2
    topPadding: Theme.spacing.m
    bottomPadding: Theme.spacing.m
    spacing: Theme.spacing.m
}
