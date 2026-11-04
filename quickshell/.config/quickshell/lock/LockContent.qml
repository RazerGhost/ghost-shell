import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme
import qs.widgets
import "LockClock.js" as LockClockJs
import "LockWidgets.js" as LockWidgets
import "../services/FileUrl.js" as FileUrl

// What the lock screen shows on each monitor: the wallpaper (blurred and darkened as set), a big
// clock (LockClock.qml) and the date, and the island at the top, which opens into the password
// field (LockIsland.qml), so the lock screen reads as the desktop locked rather than a screen of
// its own. Lock.qml checks the password. The login screen (greeter/Greeter.qml) uses it too, with
// power buttons. The look follows the lock screen editor. Children go under the date (the lock
// screen's LockStatus: media and the widgets).
Item {
    id: root

    default property alias status: statusSlot.data

    // Shown under the password field: "Wrong password", or PAM's own messages.
    property string message
    property bool messageIsError
    // A password is being checked; the field waits.
    property bool busy
    // The picture behind everything (blurred); "" shows the plain background color.
    property string wallpaper
    // Suspend, restart and shut down in the bottom right corner (the login screen).
    property bool powerButtons

    signal submitted(string password)
    // A key or a real pointer move: Lock.qml unlocks during the idle lock's grace period.
    signal activity()

    // The lock screens on other monitors clear theirs too after a try; a wrong password also
    // shakes the island.
    function clear(failed: bool): void {
        island.clear(failed);
    }

    // Takes the keyboard for the password; not inside the lock screen editor, whose own keys
    // (Escape, Enter) would go nowhere then.
    property bool takesKeyboard: true

    Component.onCompleted: {
        if (takesKeyboard)
            island.field.forceActiveFocus();
        Qt.callLater(measureQuiet);
    }

    // Fades in from black when it appears (Hyprland shows nothing behind a lock screen).
    opacity: 0
    NumberAnimation on opacity {
        to: 1
        duration: Theme.anim.morph
        easing.type: Theme.anim.easing
    }

    // Where the pointer first showed up: a move away from it counts as activity, so the
    // pointer merely being there when the lock screen appears doesn't.
    property point pointerStart: Qt.point(-1, -1)

    HoverHandler {
        onPointChanged: {
            const p = point.position;
            if (root.pointerStart.x < 0) {
                root.pointerStart = p;
            } else if (Math.abs(p.x - root.pointerStart.x) + Math.abs(p.y - root.pointerStart.y) > Theme.lock.moved) {
                root.activity();
                island.wake();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.m3surface
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        visible: false // drawn through the blur below
        source: FileUrl.of(root.wallpaper)
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
    }

    MultiEffect {
        id: backdrop
        anchors.fill: parent
        visible: wallpaper.status === Image.Ready
        source: wallpaper
        blurEnabled: true
        blur: Settings.values.lockBlur / 100
        blurMax: Theme.lock.blur
        brightness: -Settings.values.lockDim / 100 // darker, so the clock and widgets stand out
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Where the clock sits (Settings -> Lock screen -> Clock): at the top (the default), in the
    // middle, or in the bottom-left corner.
    readonly property string layout: LockClockJs.pick(Settings.values.lockLayout, LockClockJs.layouts)

    // The lock screen editor's frame (customize/EditorChrome.qml) while editing: each part shows
    // an outline to drag (PartOutline.qml), and nothing here takes input; null on the real lock
    // and login screens.
    property var editor: null

    // Every part has its own place, dragged in the editor (Settings' lockPlaces, fractions of the
    // screen; LockClock.placeOf): the clock, the date, the player, each widget. `drags` holds a
    // drag going on ({ part: point px }) until it's let go.
    readonly property var parts: ["clock", "date", "player"].concat(LockWidgets.known)
    property var drags: ({})
    // A drag just let go is being saved: no glide meanwhile.
    property bool settling: false
    readonly property bool dragging: Object.keys(drags).length > 0

    // What the parts keep clear of: the island open with the password field, the login screen's
    // power buttons and the message line at the bottom.
    readonly property var bottomRow: (powerRow.visible ? [{ x: powerRow.x, y: powerRow.y, width: powerRow.width, height: powerRow.height }] : [])
        .concat(messageLine.visible ? [{ x: messageLine.x, y: messageLine.y, width: messageLine.width, height: messageLine.height }] : [])
    readonly property var keepClear: [{ x: island.area.x, y: island.area.y, width: island.area.width, height: island.area.height }]
        .concat(bottomRow)

    // How far `item` (the part `name`) is moved from where the layout puts it: its saved place,
    // plus `by` px (the drag going on unless given), mirrored while `mirrored`, kept on the screen
    // and clear of the rest.
    function shiftOf(name, item, by) {
        // Read so a change around it is followed (mapToItem alone isn't).
        for (let p = item; p && p !== root; p = p.parent)
            void (p.x + p.y + p.width + p.height);
        const at = item.parent.mapToItem(root, item.x, item.y);
        const place = LockClockJs.placeOf(Settings.values.lockPlaces, name, Settings.values);
        const extra = by ?? drags[name] ?? Qt.point(0, 0);
        const dx = place.x * width + extra.x;
        return LockClockJs.clamped({ x: at.x, y: at.y, width: item.width, height: item.height },
                                   mirrored ? LockClockJs.mirroredMove(at.x, item.width, dx, width) : dx,
                                   place.y * height + extra.y, width, height,
                                   keepClear, Theme.spacing.l * 2, Theme.spacing.l);
    }

    // The parts move to the picture's quieter side (Settings' lockQuietSide): when the clock (or
    // the date without it) sits on the busier side, every part is mirrored across the middle. Not
    // in the editor, which shows and drags the places as saved. The side is measured once per
    // picture: ffmpeg makes a small grey copy, cropped to the screen's shape like the picture
    // (LockClock.quietSide).
    readonly property bool followsQuiet: Settings.values.lockQuietSide === true && editor === null && wallpaper !== ""
    property string quietSide: ""
    readonly property Item anchorPart: Settings.values.lockClock ? bigClock : Settings.values.lockDate ? dateLine : null
    // Its saved place without the clamp: the clamp only keeps the part on the screen and clear of
    // the rest, not on another side.
    readonly property string anchorSide: {
        if (!anchorPart)
            return "";
        void (clockColumn.x + anchorPart.x + anchorPart.width);
        const place = LockClockJs.placeOf(Settings.values.lockPlaces, anchorPart === bigClock ? "clock" : "date", Settings.values);
        const at = anchorPart.parent.mapToItem(root, anchorPart.x, anchorPart.y);
        return LockClockJs.sideOf(at.x + place.x * width + anchorPart.width / 2, width);
    }
    readonly property bool mirrored: followsQuiet && quietSide !== "" && anchorSide !== "" && anchorSide !== quietSide

    readonly property int toneWidth: 48
    readonly property int toneHeight: Math.max(2, Math.round(toneWidth * height / Math.max(width, 1)))

    function measureQuiet(): void {
        quietSide = "";
        if (!followsQuiet || width <= 0)
            return;
        tone.start(["sh", "-c", "ffmpeg -nostdin -v error -i \"$1\" -frames:v 1 -vf \"scale=$2:$3:force_original_aspect_ratio=increase:flags=area,crop=$2:$3\" -f rawvideo -pix_fmt gray - | od -An -v -tu1",
                    "sh", wallpaper, String(toneWidth), String(toneHeight)]);
    }
    onFollowsQuietChanged: Qt.callLater(measureQuiet)
    onWallpaperChanged: Qt.callLater(measureQuiet)
    onToneHeightChanged: Qt.callLater(measureQuiet)

    LatestProcess {
        id: tone
        stdout: StdioCollector {
            onStreamFinished: {
                // An older picture's run can finish after a newer one was asked for.
                if (tone.command[4] === root.wallpaper && tone.command[6] === String(root.toneHeight))
                    root.quietSide = LockClockJs.quietSide(text, root.toneWidth, root.toneHeight);
            }
        }
    }

    // The editor's drag of a part, followed until it's let go.
    function dragPart(name: string, by: point): void {
        const next = Object.assign({}, drags);
        next[name] = by;
        drags = next;
    }

    // A part moved `by` px: a drag let go (`dragged`: it already shows there) or an arrow key's
    // step from its place (glided to). Saved where it ends up, as fractions of the screen. A drag
    // of a few px is a click with a wobble, not a move.
    function movePart(name: string, item: Item, by: point, dragged: bool): void {
        const small = dragged && Math.hypot(by.x, by.y) < Theme.spacing.s;
        // A step goes on from where it shows now (its saved place may be clamped further in).
        const place = LockClockJs.placeOf(Settings.values.lockPlaces, name, Settings.values);
        const now = shiftOf(name, item, Qt.point(0, 0));
        const shift = shiftOf(name, item, dragged ? by
                                                  : Qt.point(now.x - place.x * width + by.x, now.y - place.y * height + by.y));
        settling = dragged;
        const next = Object.assign({}, drags);
        delete next[name];
        drags = next;
        if (!small) {
            Settings.values.lockPlaces = LockClockJs.withPlace(Settings.values.lockPlaces, name,
                                                               { x: shift.x / width, y: shift.y / height }, Settings.values, parts);
            // Carried into lockPlaces now: no longer read, and gone so a look or a Place resetting
            // lockPlaces doesn't bring them back.
            Settings.values.lockClockOffset = null;
            Settings.values.lockWidgetsOffset = null;
        }
        Qt.callLater(() => settling = false);
    }

    states: [
        State {
            when: root.layout === "center"
            AnchorChanges {
                target: clockColumn
                anchors.top: undefined
                anchors.verticalCenter: root.verticalCenter
            }
        },
        State {
            when: root.layout === "left"
            AnchorChanges {
                target: clockColumn
                anchors.top: undefined
                anchors.horizontalCenter: undefined
                anchors.left: root.left
                anchors.bottom: root.bottom
            }
            PropertyChanges {
                clockColumn.anchors.leftMargin: root.width * 0.06
                clockColumn.anchors.bottomMargin: root.height * 0.08
            }
        }
    ]

    Column {
        id: clockColumn

        // Left-aligned in the corner, centered otherwise.
        function place(item: Item): real {
            return root.layout === "left" ? 0 : (width - item.width) / 2;
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.18
        spacing: Theme.spacing.xs

        LockClock {
            id: bigClock
            x: clockColumn.place(this)
            visible: Settings.values.lockClock
            date: clock.date
            transform: PartShift { content: root; name: "clock"; target: bigClock }

            PartOutline { content: root; part: "clock"; target: bigClock; tab: "clock"; name: "The clock" }
        }

        Text {
            id: dateLine
            x: clockColumn.place(this)
            visible: Settings.values.lockDate
            topPadding: bigClock.style === "analog" ? Theme.spacing.m : 0
            // English names even with Dutch regional formats, like the calendar.
            text: Qt.locale(Qt.uiLanguage).toString(clock.date, "dddd, d MMMM")
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.title
            transform: PartShift { content: root; name: "date"; target: dateLine }

            PartOutline { content: root; part: "date"; target: dateLine; tab: "clock"; name: "The date" }
        }

        Column {
            id: statusSlot
            x: clockColumn.place(this)
            width: Theme.lock.fieldWidth
            topPadding: Theme.spacing.l * 2
        }
    }

    LockIsland {
        id: island
        anchors.fill: parent
        backdrop: backdrop
        message: root.message
        messageIsError: root.messageIsError
        busy: root.busy
        editing: root.editor !== null
        onSubmitted: password => root.submitted(password)
        onTyped: root.activity()
    }

    // Your own line at the bottom (Settings -> Lock screen -> Message): "If found, call ...".
    Text {
        id: messageLine
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacing.l * 2
        width: Math.min(implicitWidth, parent.width * 0.5)
        visible: text !== ""
        text: Settings.values.lockMessage
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.large
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    Row {
        id: powerRow
        enabled: root.editor === null
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacing.l * 2
        visible: root.powerButtons
        spacing: Theme.spacing.m

        Repeater {
            model: [
                { icon: "bedtime", label: "Suspend", run: "suspend" },
                { icon: "restart_alt", label: "Restart", run: "reboot" },
                { icon: "power_settings_new", label: "Shut down", run: "poweroff" }
            ]

            IconButton {
                required property var modelData
                icon: modelData.icon
                label: modelData.label
                iconSize: Theme.icon.launcher
                color: Colors.m3onSurface
                onClicked: Session[modelData.run]()
            }
        }
    }
}
