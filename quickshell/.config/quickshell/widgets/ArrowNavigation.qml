import QtQuick
import "ArrowNavigation.js" as ArrowNavigationJs

// Arrow keys move the keyboard focus between the controls inside `area` (those that take Tab:
// activeFocusOnTab), to the nearest one that way (ArrowNavigation.js). The island's menus use
// it; a control that uses an arrow key itself (a slider's Left and Right, text fields) keeps it.
QtObject {
    id: root

    required property Item area

    // `key` is Qt.Key_Left/Right/Up/Down, or Qt.Key_Tab for "the first one" when nothing has
    // the keyboard yet. True when the focus moved.
    function move(key: int): bool {
        const items = controls();
        const current = items.find(item => item.activeFocus) ?? null;
        const rect = item => item.mapToItem(root.area, 0, 0, item.width, item.height);
        const direction = key === Qt.Key_Left ? "left" : key === Qt.Key_Right ? "right" : key === Qt.Key_Up ? "up" : "down";
        const index = ArrowNavigationJs.nearest(current && key !== Qt.Key_Tab ? rect(current) : null,
                                                items.map(rect), direction);
        if (index < 0)
            return false;
        items[index].forceActiveFocus(Qt.TabFocusReason);
        reveal(items[index]);
        return true;
    }

    // Qt's Tab order (visible, enabled controls, in the order they're declared) within `area`.
    function controls(): list<Item> {
        const items = [];
        let item = area.nextItemInFocusChain(true);
        while (item && !items.includes(item) && items.length < 500) {
            if (inside(item))
                items.push(item);
            item = item.nextItemInFocusChain(true);
        }
        return items;
    }

    function inside(item: Item): bool {
        for (let p = item.parent; p; p = p.parent) {
            if (p === area)
                return true;
        }
        return false;
    }

    // Scroll a list or a scrolling page so the control shows: down a page, or along a row of
    // cards that scrolls sideways (the editors' galleries).
    function reveal(item: Item): void {
        for (let p = item.parent; p && p !== area; p = p.parent) {
            if (p.contentItem === undefined || p.contentY === undefined)
                continue;
            const at = item.mapToItem(p.contentItem, 0, 0);
            if (p.contentWidth > p.width) {
                if (at.x < p.contentX)
                    p.contentX = at.x;
                else if (at.x + item.width > p.contentX + p.width)
                    p.contentX = at.x + item.width - p.width;
            }
            if (p.contentHeight > p.height) {
                if (at.y < p.contentY)
                    p.contentY = at.y;
                else if (at.y + item.height > p.contentY + p.height)
                    p.contentY = at.y + item.height - p.height;
            }
            return;
        }
    }
}
