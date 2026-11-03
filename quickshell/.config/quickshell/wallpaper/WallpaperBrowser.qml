// The Wallpapers page of the launcher (user's choice: it grows out of the search bar, at three
// sizes; it was a window of its own, and before that a tile in the desktop editor): finds art
// on wallhaven.cc, anime by default and only ever safe for work. Search, or
// pick one of your styles, and one of wallhaven's colors if you like; the results come as
// pictures, more as you scroll. Click one for a larger look, then Download (into your folder) or
// Set as wallpaper, or one of its tags for more like it. Nothing is downloaded until you choose it.
// "Yours" shows the pictures in your folder the same way, to set one or delete it (to the trash). The searches and the checks on each result are services/Wallhaven.js (tested);
// downloading is `ghost wallpapers fetch <id>`, which checks the picture again. Opened from the
// desktop editor's Wallpaper tab, the picker strip, the launcher's search or
// `qs ipc call wallpapers browse` (LauncherState). The launcher keeps it for as long as the shell
// runs, so the results and downloads stay while it's closed.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets
import "../services/Wallhaven.js" as Wallhaven
import "../services/FileUrl.js" as FileUrl

Item {
    id: root

    // Shown in the launcher (its Wallpapers page, while it's open).
    property bool active: false

    // The search: your words and the chosen style ("" = the month's best), or a picture's tag
    // ({ id, name }; "More like this", on its own), and a color ("" = any; Wallhaven.colors).
    property string words: ""
    property string style: ""
    property var tag: null
    property string color: ""
    // What's found so far, `page` pages of `lastPage`.
    property var pictures: []
    property int page: 0
    property int lastPage: 0
    property bool loading: false
    property bool failed: false
    // A search's key, so an older search's answer arriving late is dropped.
    property int searchId: 0
    // The picture shown large (null: the grid).
    property var chosen: null

    // "find" (wallhaven) or "yours" (your folder).
    property string mode: "find"
    // Your folder's pictures in the results' shape; `path` marks them as yours.
    readonly property var yours: Wallpaper.pictures.map(p => {
        const picture = FileUrl.of(p.video ? p.thumb : p.filePath);
        return { id: "", file: p.fileName, thumb: picture, url: picture, resolution: "", path: p.filePath,
                 darkPath: p.darkPath };
    })
    // What the grid shows.
    readonly property var shown: mode === "yours" ? yours : pictures

    function showMode(next: string): void {
        if (next === mode)
            return;
        chosen = null;
        mode = next;
        grid.currentIndex = 0;
        grid.contentY = 0;
        if (next === "yours")
            Wallpaper.rescan();
    }

    // Moves a picture of yours to the trash (gio trash: it can be got back), its dark version
    // with it. Not the wallpaper you have now; the lock screen's picture goes back to the desktop's.
    function trash(picture: var): void {
        if (!picture?.path || picture.path === Wallpaper.path || picture.darkPath === Wallpaper.path)
            return;
        const at = shown.indexOf(picture);
        trashing.command = ["gio", "trash", "--"].concat(picture.darkPath ? [picture.path, picture.darkPath] : [picture.path]);
        trashing.next = at;
        trashing.running = true;
        // The lock screen showing it goes back to the desktop's picture (it would show none).
        if ([picture.path, picture.darkPath].includes(Settings.values.lockWallpaper))
            Settings.values.lockWallpaper = "";
    }

    Process {
        id: trashing
        property int next: -1
        onExited: code => {
            if (code !== 0) {
                Notifications.send("Wallpapers", "dialog-warning", "Couldn't delete the picture",
                                   "gio trash exited with " + code + ".", false, []);
                return;
            }
            Wallpaper.rescan();
        }
    }

    // After a delete, the large view moves to the picture now in its place (or back to the grid).
    Connections {
        target: Wallpaper

        function onPicturesChanged(): void {
            if (root.mode !== "yours" || root.chosen === null || trashing.next < 0)
                return;
            const list = root.yours;
            root.chosen = list.length === 0 ? null : list[Math.min(trashing.next, list.length - 1)];
            grid.currentIndex = Math.max(0, Math.min(trashing.next, list.length - 1));
            trashing.next = -1;
        }
    }

    // The files already in your folder (wallhaven-<id>.<ext>), to mark what you have.
    readonly property var owned: Wallpaper.pictures.map(p => p.fileName)

    function search(): void {
        searchId++;
        pictures = [];
        page = 0;
        lastPage = 0;
        failed = false;
        loading = false;
        loadMore();
    }

    function loadMore(): void {
        if (loading || (page > 0 && page >= lastPage))
            return;
        loading = true;
        failed = false;
        const asked = searchId;
        const request = new XMLHttpRequest();
        request.onreadystatechange = () => {
            if (request.readyState !== XMLHttpRequest.DONE || asked !== root.searchId)
                return;
            root.loading = false;
            // 429: wallhaven's limit of 45 searches a minute.
            if (request.status !== 200) {
                root.failed = true;
                return;
            }
            const found = Wallhaven.results(request.responseText);
            // A new list resets the grid to its start: keep the keyboard's place and the scroll.
            const at = grid.currentIndex;
            const y = grid.contentY;
            root.pictures = root.pictures.concat(found.pictures);
            grid.currentIndex = at;
            grid.contentY = y;
            root.page++;
            root.lastPage = found.lastPage;
            Qt.callLater(root.fill);
        };
        request.open("GET", Wallhaven.searchUrl({ words: words.trim().split(/\s+/), style: style, page: page + 1,
                                                  tag: tag?.id ?? "", color: color }));
        request.send();
    }

    // More pages while the ones in don't fill the window (nothing to scroll yet, so scrolling to
    // the end can't ask for them; a maximized window holds more than a page).
    readonly property bool hasMore: page === 0 || page < lastPage
    function fill(): void {
        if (active && mode === "find" && chosen === null && hasMore && !failed && grid.count > 0 && grid.contentHeight <= grid.height)
            loadMore();
    }

    onActiveChanged: {
        if (!active)
            return;
        if (pictures.length === 0)
            search();
        if (chosen === null)
            Qt.callLater(searchField.focusInput);
    }
    // Still shown after a shell reload: the results are gone, so look again.
    Component.onCompleted: if (active && pictures.length === 0) search()

    // "More like this": the pictures with one of the chosen picture's tags (wallhaven's own
    // "similar" search isn't open to the API without an account). The tags come from the
    // picture's page, asked for once it's been shown a moment (stepping through quickly would
    // spend wallhaven's 45 requests a minute).
    property var chosenTags: []

    function moreLike(t: var): void {
        tag = t;
        style = "";
        searchField.text = "";
        chosen = null;
        search();
        grid.forceActiveFocus();
    }

    onChosenChanged: {
        chosenTags = [];
        if (chosen && !chosen.path)
            tagsTimer.restart();
    }

    Timer {
        id: tagsTimer
        interval: 400
        onTriggered: {
            const asked = root.chosen;
            const url = asked ? Wallhaven.pictureUrl(asked.id) : "";
            if (url === "")
                return;
            const request = new XMLHttpRequest();
            request.onreadystatechange = () => {
                if (request.readyState === XMLHttpRequest.DONE && request.status === 200 && root.chosen === asked)
                    root.chosenTags = Wallhaven.tags(request.responseText, 8);
            };
            request.open("GET", url);
            request.send();
        }
    }

    // Downloads, one at a time in the order asked: { id, set } (set: make it the wallpaper after).
    property var queue: []
    property var current: null
    readonly property var pending: (current ? [current.id] : []).concat(queue.map(d => d.id))

    function download(picture: var, set: bool): void {
        if (owned.includes(picture.file)) {
            if (set)
                Wallpaper.set(Wallpaper.folder + "/" + picture.file);
            return;
        }
        if (pending.includes(picture.id)) {
            // Already on its way: set it once it's there.
            if (set)
                queue = queue.map(d => d.id === picture.id ? { id: d.id, set: true } : d);
            if (set && current?.id === picture.id)
                current = { id: current.id, set: true };
            return;
        }
        queue = queue.concat([{ id: picture.id, set: set }]);
        next();
    }

    function next(): void {
        if (current || queue.length === 0)
            return;
        current = queue[0];
        queue = queue.slice(1);
        fetch.command = [Quickshell.env("HOME") + "/.local/bin/ghost", "wallpapers", "fetch", current.id];
        fetch.running = true;
    }

    Process {
        id: fetch
        stdout: StdioCollector { id: fetchOut }
        stderr: StdioCollector { id: fetchErr }
        onExited: code => {
            const done = root.current;
            root.current = null;
            if (code === 0) {
                Wallpaper.rescan();
                if (done.set)
                    Wallpaper.set(fetchOut.text.trim());
            } else {
                Notifications.send("Wallpapers", "dialog-warning", "Couldn't download the picture",
                                   fetchErr.text.trim().replace(/\x1b\[[0-9;]*m/g, "") || "ghost wallpapers fetch exited with " + code,
                                   false, []);
            }
            root.next();
        }
    }

    // The search and the styles.
    Row {
        id: searchRow

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.spacing.s
        visible: root.chosen === null

        Segmented {
            id: modes
            anchors.verticalCenter: parent.verticalCenter
            tabs: true
            options: [{ value: "find", label: "Find" }, { value: "yours", label: "Yours" }]
            current: root.mode
            onPicked: v => root.showMode(v)
        }

        // Yours: how many, and the folder.
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.mode === "yours"
            width: parent.width - modes.width - openFolder.width - parent.spacing * 2
            leftPadding: Theme.spacing.s
            text: root.yours.length + (root.yours.length === 1 ? " picture in " : " pictures in ")
                  + Wallpaper.folder.replace(Quickshell.env("HOME"), "~")
            elide: Text.ElideMiddle
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
        }

        TextButton {
            id: openFolder
            anchors.verticalCenter: parent.verticalCenter
            visible: root.mode === "yours"
            text: "Open folder"
            onClicked: Apps.run(["sh", "-c", 'mkdir -p "$1" && exec xdg-open "$1"', "sh", Wallpaper.folder], "xdg-open", "")
        }

        SearchField {
            id: searchField
            visible: root.mode === "find"
            width: Math.max(Theme.wallpaper.browserThumb, parent.width - modes.width - styles.width - parent.spacing * 2)
            placeholder: root.tag ? "" : root.style ? "Narrow it down (optional)" : "Search wallhaven (or the month's best)"
            onTextChanged: {
                root.words = text;
                // Typing starts a search of your own.
                if (text !== "")
                    root.tag = null;
            }
            onKeyPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.search();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down && grid.count > 0) {
                    grid.forceActiveFocus();
                    event.accepted = true;
                }
            }

            // The tag being looked at ("More like this"), × back to the month's best.
            TextButton {
                visible: root.tag !== null
                text: "Like: " + (root.tag?.name ?? "") + "  ×"
                color: Colors.m3secondaryContainer
                onClicked: {
                    root.tag = null;
                    root.search();
                }
                Accessible.name: "Stop showing pictures like " + (root.tag?.name ?? "")
            }
        }

        Row {
            id: styles
            visible: root.mode === "find"
            spacing: Theme.spacing.xs

            Repeater {
                model: Wallhaven.styles

                OptionChip {
                    required property var modelData
                    width: Theme.wallpaper.browserThumb / 2.4
                    text: modelData.label
                    chosen: root.tag === null && root.style === modelData.value
                    onClicked: {
                        root.style = modelData.value;
                        root.tag = null;
                        root.search();
                    }
                }
            }
        }
    }

    // wallhaven's colors: pictures with a lot of one. Click the chosen one again for any color.
    Row {
        id: colorRow

        anchors.top: searchRow.bottom
        anchors.left: parent.left
        anchors.topMargin: Theme.spacing.m
        spacing: Theme.spacing.xs
        visible: root.chosen === null && root.mode === "find"
        height: visible ? implicitHeight : 0

        Accessible.role: Accessible.Grouping
        Accessible.name: "Colors"

        Repeater {
            model: Wallhaven.colors

            Rectangle {
                id: swatch

                required property var modelData
                readonly property bool picked: root.color === modelData.hex

                function toggle(): void {
                    root.color = picked ? "" : modelData.hex;
                    root.search();
                }

                width: Theme.icon.normal + Theme.spacing.xs
                height: width
                radius: width / 2
                color: "#" + modelData.hex
                border.width: picked ? Theme.outline.strong : Theme.outline.normal
                border.color: picked ? Colors.m3primary : Colors.m3outlineVariant
                scale: picked ? 1.15 : swatchMouse.containsMouse ? 1.08 : 1
                Behavior on scale {
                    NumberAnimation { duration: Theme.anim.fast }
                }

                Accessible.role: Accessible.CheckBox
                Accessible.name: modelData.name
                Accessible.checked: picked
                Accessible.onPressAction: toggle()
                activeFocusOnTab: true
                Keys.onReturnPressed: toggle()
                Keys.onEnterPressed: toggle()
                Keys.onSpacePressed: toggle()

                FocusRing {
                    radius: swatch.radius
                }

                MouseArea {
                    id: swatchMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: swatch.toggle()
                }

                Tooltip {
                    target: swatch
                    text: swatch.modelData.name
                    shown: swatchMouse.containsMouse || swatch.activeFocus
                }
            }
        }
    }

    // The pictures found, more as you scroll to the end.
    GridView {
        id: grid

        readonly property int columns: Math.max(2, Math.floor(width / Theme.wallpaper.browserThumb))

        anchors.top: colorRow.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: -Theme.spacing.xs
        anchors.topMargin: Theme.spacing.m
        visible: root.chosen === null
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        cellWidth: Math.floor(width / columns)
        cellHeight: Math.round((cellWidth - Theme.spacing.s) * 9 / 16) + Theme.spacing.s
        model: root.shown
        keyNavigationEnabled: true
        onAtYEndChanged: if (atYEnd && count > 0 && root.mode === "find") root.loadMore()
        onHeightChanged: Qt.callLater(root.fill)
        onWidthChanged: Qt.callLater(root.fill) // more columns

        Keys.onReturnPressed: if (currentIndex >= 0) root.chosen = root.shown[currentIndex]
        Keys.onEnterPressed: if (currentIndex >= 0) root.chosen = root.shown[currentIndex]
        Keys.onSpacePressed: if (currentIndex >= 0) root.chosen = root.shown[currentIndex]
        Keys.onUpPressed: event => {
            if (currentIndex < columns)
                searchField.focusInput();
            else
                event.accepted = false;
        }

        Accessible.role: Accessible.List
        Accessible.name: "Wallpapers found"

        delegate: MouseArea {
            id: cell

            required property var modelData
            required property int index
            // Its check in Find; in Yours, the wallpaper you have now.
            readonly property bool have: modelData.path ? Wallpaper.path === modelData.path || Wallpaper.path === modelData.darkPath
                                                        : root.owned.includes(modelData.file)
            readonly property bool coming: root.pending.includes(modelData.id)

            width: grid.cellWidth
            height: grid.cellHeight
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.chosen = modelData

            Accessible.role: Accessible.Button
            Accessible.name: modelData.path ? modelData.file + (have ? ", your wallpaper" : "")
                : "Wallpaper " + (index + 1) + ", " + modelData.resolution + (have ? ", downloaded" : coming ? ", downloading" : "")
            Accessible.onPressAction: root.chosen = modelData

            ClippingRectangle {
                id: frame
                anchors.fill: parent
                anchors.margins: Theme.spacing.xs
                radius: Theme.radius.m
                color: Colors.m3surfaceContainerHigh

                Image {
                    anchors.fill: parent
                    source: cell.modelData.thumb
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: width
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: Theme.anim.fast }
                    }
                }

                StateLayer {
                    radius: frame.radius
                    color: Colors.m3onSurface
                    hovered: cell.containsMouse
                }
            }

            // The keyboard's place in the grid.
            Rectangle {
                anchors.fill: frame
                radius: frame.radius
                color: "transparent"
                visible: cell.GridView.isCurrentItem && grid.activeFocus
                border.width: Theme.focus.width
                border.color: Colors.m3primary
            }

            // In your folder already, or on its way.
            Rectangle {
                anchors.right: frame.right
                anchors.bottom: frame.bottom
                anchors.margins: Theme.spacing.s
                width: Theme.icon.normal + Theme.spacing.s
                height: width
                radius: width / 2
                visible: cell.have || cell.coming
                color: Colors.m3primaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    icon: cell.modelData.path ? "wallpaper" : cell.have ? "check" : "downloading"
                    color: Colors.m3onPrimaryContainer
                    font.pixelSize: Theme.icon.small
                }
            }
        }

        footer: Item {
            width: grid.width
            height: Theme.list.rowHeight

            Text {
                anchors.centerIn: parent
                visible: !more.visible
                text: root.mode === "yours" ? (root.yours.length === 0 ? "None yet: find some under Find" : "")
                    : root.failed ? "wallhaven didn't answer. Try again in a moment."
                    : root.loading ? "Looking…"
                    : root.page > 0 && root.pictures.length === 0 ? "Nothing found"
                    : root.page > 0 && !root.hasMore ? "That's all of them" : ""
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
            }

            // Also after a failed page: scrolling to the end again doesn't move atYEnd.
            TextButton {
                id: more
                anchors.centerIn: parent
                visible: root.mode === "find" && !root.loading && root.page > 0 && root.pictures.length > 0 && root.hasMore
                text: root.failed ? "Try again" : "Load more"
                onClicked: root.loadMore()
            }
        }
    }

    // One picture large, with what to do with it. Left and Right step through the results,
    // Escape goes back to them.
    Item {
        id: preview

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.chosen !== null
        focus: visible
        onVisibleChanged: if (visible) forceActiveFocus()

        // By path for yours: a rescan makes new entries for the same pictures.
        readonly property int at: root.chosen === null ? -1
            : root.shown.findIndex(p => p === root.chosen || (p.path && p.path === root.chosen.path))
        readonly property bool own: !!root.chosen?.path
        readonly property bool current: own && (Wallpaper.path === root.chosen.path || Wallpaper.path === root.chosen.darkPath)
        readonly property bool have: root.chosen !== null && root.owned.includes(root.chosen.file)
        readonly property bool coming: root.chosen !== null && root.pending.includes(root.chosen.id)

        function step(by: int): void {
            const next = at + by;
            if (next < 0 || next >= root.shown.length)
                return;
            root.chosen = root.shown[next];
            grid.currentIndex = next;
            if (root.mode === "find" && next >= root.pictures.length - 2)
                root.loadMore();
        }

        function back(): void {
            deleteButton.armed = false;
            root.chosen = null;
            grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
            grid.forceActiveFocus();
        }

        Keys.onEscapePressed: back()
        Keys.onLeftPressed: step(-1)
        Keys.onRightPressed: step(1)
        Keys.onDeletePressed: if (own) deleteButton.press()
        onAtChanged: deleteButton.armed = false

        ClippingRectangle {
            id: large

            anchors.top: parent.top
            anchors.bottom: tagRow.top
            anchors.bottomMargin: Theme.spacing.m
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, height * 16 / 9)
            radius: Theme.radius.l
            color: Colors.m3surfaceContainerHigh

            // The thumbnail at once, the full picture over it when it's in.
            Image {
                anchors.fill: parent
                source: root.chosen?.thumb ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Image {
                id: full
                anchors.fill: parent
                source: root.chosen?.url ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                // Decoded at the size it's shown, not the picture's 4K.
                sourceSize.width: width
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Theme.anim.fast }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: Theme.spacing.m
                visible: full.status === Image.Loading
                text: "Loading the full picture… " + Math.round(full.progress * 100) + " %"
                color: "white"
                style: Text.Outline
                styleColor: "#80000000"
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
            }
        }

        // Its tags: click one for more like it.
        Row {
            id: tagRow

            anchors.bottom: actions.top
            anchors.bottomMargin: Theme.spacing.m
            anchors.horizontalCenter: parent.horizontalCenter
            height: Theme.island.height
            spacing: Theme.spacing.xs

            Text {
                anchors.verticalCenter: parent.verticalCenter
                rightPadding: Theme.spacing.s
                text: root.chosenTags.length > 0 ? "More like this:" : ""
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
            }

            Repeater {
                // As many as fit on one line.
                model: root.chosenTags

                TextButton {
                    required property var modelData
                    required property int index
                    anchors.verticalCenter: parent.verticalCenter
                    visible: x + width <= preview.width
                    text: modelData.name
                    color: Colors.tint
                    onClicked: root.moreLike(modelData)
                    Accessible.name: "More like this: " + modelData.name
                }
            }
        }

        Item {
            id: actions

            anchors.bottom: parent.bottom
            width: parent.width
            height: Theme.island.height

            TextButton {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Back"
                onClicked: preview.back()
            }

            Text {
                anchors.centerIn: parent
                text: (preview.own ? root.chosen.file : root.chosen?.resolution ?? "") + "  ·  " + (preview.at + 1) + " of " + root.shown.length
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.s

                TextButton {
                    visible: !preview.own
                    text: preview.have ? "Downloaded" : preview.coming ? "Downloading…" : "Download"
                    enabled: !preview.have && !preview.coming
                    onClicked: root.download(root.chosen, false)
                }

                // Yours: to the trash, after a second click (or Delete twice) within 4 s.
                // Not the wallpaper you have now: pick another first.
                TextButton {
                    id: deleteButton

                    property bool armed: false

                    function press(): void {
                        if (!enabled)
                            return;
                        if (!armed) {
                            armed = true;
                            disarm.restart();
                            return;
                        }
                        armed = false;
                        root.trash(root.chosen);
                    }

                    visible: preview.own
                    enabled: !preview.current && !trashing.running
                    text: preview.current ? "Your wallpaper now" : armed ? "Delete? Click again" : "Delete"
                    color: armed ? Colors.m3errorContainer : "transparent"
                    onClicked: press()

                    Timer {
                        id: disarm
                        interval: 4000
                        onTriggered: deleteButton.armed = false
                    }
                }

                TextButton {
                    readonly property bool isCurrent: preview.own ? preview.current
                        : Wallpaper.path === Wallpaper.folder + "/" + (root.chosen?.file ?? "")
                    text: isCurrent ? "Your wallpaper" : "Set as wallpaper"
                    filled: true
                    enabled: !isCurrent
                    onClicked: preview.own ? Wallpaper.set(root.chosen.path) : root.download(root.chosen, true)
                }
            }
        }
    }
}
