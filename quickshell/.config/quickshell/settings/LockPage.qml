import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets
import "../lock/LockClock.js" as LockClock

// The lock screen and the login screen share one look: picture, blur, dimming, clock and date.
// The login screen also shows your name and power buttons. The login screen gets these through
// greeter/sync.sh, once `ghost greeter` has set it up.
Column {
    id: root

    // Whether the login screen can follow these (`ghost greeter` made its folder yours).
    property bool loginScreenReady: false
    // Thumbnails only load once the page has been shown (the built-in pictures are large).
    property bool opened: false

    readonly property list<int> percents: Array.from({ length: 11 }, (_, i) => i * 10)

    spacing: Theme.spacing.l
    function shown(): void {
        opened = true;
        Wallpaper.rescan();
        check.running = true;
    }
    onVisibleChanged: {
        if (visible)
            shown();
    }
    // Settings builds the page when it's chosen, already visible.
    Component.onCompleted: shown()

    Process {
        id: check
        command: ["test", "-w", "/var/lib/qs-greeter/shared"]
        onExited: code => root.loginScreenReady = code === 0
    }

    Item {
        width: parent.width
        height: preview.height

        Text {
            anchors.left: parent.left
            anchors.right: preview.left
            anchors.leftMargin: Theme.spacing.l
            anchors.rightMargin: Theme.spacing.l
            anchors.verticalCenter: parent.verticalCenter
            text: root.loginScreenReady
                  ? "The login screen follows these too."
                  : "These only change the lock screen until you run ghost greeter once (it needs sudo)."
            color: root.loginScreenReady ? Colors.m3onSurfaceVariant : Colors.m3error
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            wrapMode: Text.Wrap
        }

        TextButton {
            id: preview
            anchors.right: parent.right
            text: "Preview"
            onClicked: Quickshell.execDetached(["qs", "ipc", "call", "lock", "preview"])
        }
    }

    SettingGroup {
        title: "Picture"

        SettingRow {
            title: "Same as the desktop"
            subtitle: "Or pick a picture just for these screens"

            Switch {
                label: "Same picture as the desktop"
                checked: Settings.values.lockWallpaper === ""
                // Turning it off starts from the current wallpaper; pick another below.
                onToggled: Settings.values.lockWallpaper = checked ? Wallpaper.path : ""
            }
        }

        ListView {
            id: pictures

            readonly property real thumbHeight: Theme.wallpaper.thumbHeight * 0.75

            visible: Settings.values.lockWallpaper !== ""
            x: Theme.spacing.l
            width: parent.width - Theme.spacing.l * 2
            height: thumbHeight + Theme.spacing.m
            orientation: ListView.Horizontal
            spacing: Theme.spacing.s
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            // Pictures only: the lock and login screens can't play a video.
            model: Wallpaper.pictures.filter(p => !p.video)

            Accessible.role: Accessible.List
            Accessible.name: "Pictures"

            delegate: MouseArea {
                id: cell

                required property var modelData
                readonly property bool current: modelData.filePath === Settings.values.lockWallpaper

                width: pictures.thumbHeight * 16 / 9
                height: pictures.thumbHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Settings.values.lockWallpaper = modelData.filePath

                Accessible.role: Accessible.ListItem
                Accessible.name: modelData.fileName + (current ? ", chosen" : "")
                Accessible.onPressAction: Settings.values.lockWallpaper = modelData.filePath

                ClippingRectangle {
                    anchors.fill: parent
                    radius: Theme.radius.m
                    color: Colors.m3surfaceContainerHigh

                    Image {
                        anchors.fill: parent
                        source: root.opened ? "file://" + cell.modelData.filePath : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: width * 2
                        Accessible.ignored: true
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius.m
                    color: "transparent"
                    border.width: cell.current ? Theme.outline.strong : cell.containsMouse ? Theme.outline.normal : 0
                    border.color: cell.current ? Colors.m3primary : Colors.m3onSurface
                }
            }
        }

        SettingRow {
            title: "Blur"

            Stepper {
                label: "Blur"
                values: root.percents
                value: Settings.values.lockBlur
                format: v => v === 0 ? "Off" : v + " %"
                onPicked: v => Settings.values.lockBlur = v
            }
        }

        SettingRow {
            title: "Darken"
            subtitle: "So the clock and password field stand out"

            Stepper {
                label: "Darken"
                values: Array.from({ length: 13 }, (_, i) => i * 5) // up to 60 %
                value: Settings.values.lockDim
                format: v => v === 0 ? "Off" : v + " %"
                onPicked: v => Settings.values.lockDim = v
            }
        }
    }

    SettingGroup {
        title: "Clock"

        SettingRow {
            title: "Show the time"

            Switch {
                label: "Show the time"
                checked: Settings.values.lockClock
                onToggled: Settings.values.lockClock = !checked
            }
        }

        SettingRow {
            title: "Style"
            subtitle: "Stacked puts the hours over the minutes"

            Stepper {
                label: "Clock style"
                values: LockClock.styles
                valueWidth: Theme.settings.stepperWide
                value: LockClock.pick(Settings.values.lockClockStyle, LockClock.styles)
                format: v => ({ big: "Big", stacked: "Stacked", thin: "Thin", analog: "Analog" })[v]
                onPicked: v => Settings.values.lockClockStyle = v
            }
        }

        SettingRow {
            title: "Size"

            Stepper {
                label: "Clock size"
                values: LockClock.sizes
                value: LockClock.pick(Settings.values.lockClockSize, LockClock.sizes)
                format: v => v + " %"
                onPicked: v => Settings.values.lockClockSize = v
            }
        }

        SettingRow {
            title: "Font"
            subtitle: "The clock's own; the date keeps the shell's"

            Stepper {
                readonly property var installed: Qt.fontFamilies()
                label: "Clock font"
                // "" is the shell's text font (Settings -> Appearance -> Fonts).
                values: ["", "Inter Display", "Noto Serif", "C059", "Nimbus Sans Narrow", "MesloLGS Nerd Font"]
                        .filter(f => f === "" || installed.includes(f))
                valueWidth: Theme.settings.stepperWide
                value: Settings.values.lockClockFont
                format: v => v === "" ? "Same as text" : v === "MesloLGS Nerd Font" ? "Monospaced" : v
                onPicked: v => Settings.values.lockClockFont = v
            }
        }

        SettingRow {
            title: "Place"
            subtitle: "Where the clock and date sit"

            Stepper {
                label: "Clock place"
                values: LockClock.layouts
                valueWidth: Theme.settings.stepperWide
                value: LockClock.pick(Settings.values.lockLayout, LockClock.layouts)
                format: v => ({ top: "Top", center: "Middle", left: "Bottom left" })[v]
                onPicked: v => Settings.values.lockLayout = v
            }
        }

        SettingRow {
            title: "Show the date"

            Switch {
                label: "Show the date"
                checked: Settings.values.lockDate
                onToggled: Settings.values.lockDate = !checked
            }
        }
    }

    SettingGroup {
        title: "Lock screen"

        SettingRow {
            title: "Media controls"
            subtitle: "Play, pause and skip without unlocking"

            Switch {
                label: "Media controls"
                checked: Settings.values.lockMedia
                onToggled: Settings.values.lockMedia = !checked
            }
        }

        SettingRow {
            title: "Notification count"
            subtitle: "How many came in, never what they say"

            Switch {
                label: "Notification count"
                checked: Settings.values.lockNotificationCount
                onToggled: Settings.values.lockNotificationCount = !checked
            }
        }

        SettingRow {
            title: "Weather"

            Switch {
                label: "Weather on the lock screen"
                checked: Settings.values.lockWeather
                onToggled: Settings.values.lockWeather = !checked
            }
        }

        SettingRow {
            title: "Battery"

            Switch {
                label: "Battery on the lock screen"
                checked: Settings.values.lockBattery
                onToggled: Settings.values.lockBattery = !checked
            }
        }

        SettingRow {
            title: "Next calendar event"
            subtitle: "Its title shows to anyone at the locked screen"

            Switch {
                label: "Next calendar event on the lock screen"
                checked: Settings.values.lockEvent
                onToggled: Settings.values.lockEvent = !checked
            }
        }
    }

    SettingGroup {
        title: "Login screen"

        SettingRow {
            title: "Show your name"
            subtitle: "Above the password field"

            Switch {
                label: "Show your name on the login screen"
                checked: Settings.values.greeterShowName
                onToggled: Settings.values.greeterShowName = !checked
            }
        }

        SettingRow {
            title: "Power buttons"
            subtitle: "Suspend, restart and shut down without logging in"

            Switch {
                label: "Power buttons on the login screen"
                checked: Settings.values.greeterPowerButtons
                onToggled: Settings.values.greeterPowerButtons = !checked
            }
        }
    }
}
