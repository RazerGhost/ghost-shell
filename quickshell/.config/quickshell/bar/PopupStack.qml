import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.controlcenter
import qs.services
import qs.theme
import qs.widgets

// Pop-ups in the top-right corner of the focused screen, under the island (user's choice,
// 2026-11-03: they used to drop from the island one at a time, and waited while any menu was
// open): up to three notifications at once, oldest at the top, and a window asking for
// attention. Shell reloads show in the island itself (IslandWindow.qml). Each notification stays Settings' notificationSeconds,
// the attention card the same; the pointer over the stack pauses them, critical notifications
// stay until dismissed.
PanelWindow {
    id: root

    required property var island // Island.qml: toggle()

    readonly property string monitorName: Hyprland.focusedMonitor?.name ?? ""
    readonly property list<Notification> notifications: Notifications.popups
    readonly property HyprlandToplevel attention: Windows.needsAttention
    readonly property bool hasAny: notifications.length > 0 || attention !== null
    // How long a pop-up stays, from Settings (it offers 3-30 s; kept within 1-60 should the file
    // say otherwise).
    readonly property int popupTime: Math.min(60, Math.max(1, Number(Settings.values.notificationSeconds) || 5)) * 1000

    screen: Quickshell.screens.find(s => s.name === monitorName) ?? null
    visible: hasAny || stack.opacity > 0

    anchors.top: true
    anchors.right: true
    margins.top: Theme.island.reserved + Theme.spacing.s
    margins.right: Theme.island.popupMargin
    // A fixed size, so the window doesn't resize as cards come and go; only the stack takes
    // input (mask), the rest lets clicks through. As tall as the island's window: three cards with
    // actions or pictures and the attention card ran past half of it, cut off.
    implicitWidth: Theme.island.panelWidth
    implicitHeight: Theme.island.maxHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: stack }
    BackgroundEffect.blurRegion: Region {
        item: stack
        radius: stack.radius
    }

    WlrLayershell.namespace: "qs-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Surface {
        id: stack

        readonly property bool hovered: hover.hovered

        width: parent.width
        height: cards.implicitHeight + Theme.spacing.s * 2
        radius: Theme.island.openRadius
        opacity: root.hasAny ? 1 : 0
        // Slides in from the right edge.
        x: root.hasAny ? 0 : Theme.island.popupSlide

        Behavior on height {
            MorphAnimation {}
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.anim.normal }
        }
        Behavior on x {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }

        HoverHandler {
            id: hover
        }

        Column {
            id: cards

            x: Theme.spacing.s
            y: Theme.spacing.s
            width: parent.width - Theme.spacing.s * 2
            spacing: Theme.spacing.s

            Repeater {
                // ScriptModel keeps the cards that stay when one goes, with their timers.
                model: ScriptModel { values: Array.from(root.notifications) }

                NotificationCard {
                    id: card

                    required property var modelData

                    width: parent.width
                    notification: modelData
                    onReplyRequested: root.island.toggle("today", root.monitorName)

                    Timer {
                        interval: root.popupTime
                        running: !stack.hovered && card.notification !== null
                                 && card.notification.urgency !== NotificationUrgency.Critical
                        onTriggered: Notifications.done(card.notification)
                    }
                }
            }

            AttentionCard {
                id: attentionCard

                width: parent.width
                window: root.attention
                visible: root.attention !== null
                // Another window asking straight after: its own full time.
                onWindowChanged: attentionTimer.restart()
                onActivated: {
                    Windows.show(root.attention);
                    Windows.attentionSeen();
                }

                Timer {
                    id: attentionTimer
                    interval: root.popupTime
                    running: attentionCard.visible && !stack.hovered
                    onTriggered: Windows.attentionSeen()
                }
            }
        }
    }
}
