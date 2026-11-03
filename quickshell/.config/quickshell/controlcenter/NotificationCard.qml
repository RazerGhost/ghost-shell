import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets
import "NotificationProgress.js" as NotificationProgress
import "NotificationTime.js" as NotificationTime
import "../services/FileUrl.js" as FileUrl

// One notification: app icon (or the notification's own image), app and time, title, text,
// and the app's action buttons. Click it to run its default action; × dismisses it. Used for
// the island's pop-up and in the history in the "today" menu. Chat apps can ask for a reply
// field: in the history you type in it; a pop-up can't take the keyboard (the closed island
// doesn't), so it shows a Reply button that opens the history instead.
MouseArea {
    id: root

    required property Notification notification
    // For the "5 min" label; the history ticks it every minute.
    property real now: Date.now()
    // Whether a reply can be typed here (the history), or Reply asks for that (a pop-up).
    property bool canType: false

    signal replyRequested()

    // A path or URL to an image, or an icon theme name.
    function imageSource(source: string): string {
        if (source === "")
            return "";
        if (source.startsWith("/"))
            return FileUrl.of(source);
        if (source.includes("://"))
            return source;
        return Quickshell.iconPath(source, true);
    }

    readonly property string icon: imageSource(notification?.image || notification?.appIcon || "")

    implicitHeight: content.implicitHeight + Theme.spacing.m * 2
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: Notifications.activate(notification)

    Accessible.role: Accessible.Button
    Accessible.name: (notification?.appName ?? "") + ": " + (notification?.summary ?? "") + ". " + (notification?.body ?? "")
    Accessible.onPressAction: Notifications.activate(notification)

    // The keyboard (arrow keys or Tab, then Enter or Space), like a click.
    activeFocusOnTab: true
    Keys.onReturnPressed: Notifications.activate(notification)
    Keys.onEnterPressed: Notifications.activate(notification)
    Keys.onSpacePressed: Notifications.activate(notification)

    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    // Text on the card: on a critical one, the error container's own text color.
    readonly property color textColor: critical ? Colors.m3onErrorContainer : Colors.m3onSurface
    readonly property color subtleColor: critical ? Colors.m3onErrorContainer : Colors.m3onSurfaceVariant

    // Critical ones (a low battery, the timer) in Material's error colors, so they stand out
    // from the attention card's accent.
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.l
        color: root.critical ? Colors.m3errorContainer : Colors.m3surfaceContainerHigh
    }

    StateLayer {
        radius: Theme.radius.l
        color: root.textColor
        hovered: root.containsMouse
    }

    FocusRing {
        radius: Theme.radius.l
    }

    Row {
        id: content

        x: Theme.spacing.m
        y: Theme.spacing.m
        width: parent.width - Theme.spacing.m * 2
        spacing: Theme.spacing.m

        ClippingRectangle {
            width: Theme.icon.launcher
            height: width
            radius: Theme.radius.s
            color: "transparent"

            MaterialIcon {
                anchors.centerIn: parent
                visible: image.status !== Image.Ready
                icon: "notifications"
                color: root.subtleColor
            }

            // IconImage, not Image: it asks icon themes for the right size instead of scaling
            // up a small one.
            IconImage {
                id: image
                anchors.fill: parent
                source: root.icon
                asynchronous: true
            }
        }

        Column {
            width: parent.width - Theme.icon.launcher - parent.spacing
            spacing: 2

            // App · time, with the dismiss button on the right.
            Item {
                width: parent.width
                height: close.height

                Text {
                    anchors.left: parent.left
                    anchors.right: close.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: [root.notification?.appName,
                           NotificationTime.format(Notifications.received[root.notification?.id] ?? root.now, root.now)]
                          .filter(s => s).join(" · ")
                    color: root.subtleColor
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.small
                    elide: Text.ElideRight
                }

                IconButton {
                    id: close
                    anchors.right: parent.right
                    icon: "close"
                    iconSize: Theme.icon.small
                    label: "Dismiss"
                    onClicked: root.notification.dismiss()
                }
            }

            Text {
                width: parent.width
                text: root.notification?.summary ?? ""
                textFormat: Text.PlainText
                color: root.textColor
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.notification?.body ?? ""
                // Apps may send markup; show it as text rather than render it.
                textFormat: Text.PlainText
                color: root.subtleColor
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            // Progress of a long task (a download, a copy), when the app sends it; apps update the
            // same notification as it goes.
            Rectangle {
                readonly property real progress: NotificationProgress.progress(root.notification?.hints)

                width: parent.width
                height: Theme.spacing.xs
                radius: height / 2
                visible: progress >= 0
                color: Colors.m3surfaceContainerHighest

                Accessible.role: Accessible.ProgressBar
                Accessible.name: Math.round(progress * 100) + " %"

                Rectangle {
                    width: parent.width * Math.max(0, parent.progress)
                    height: parent.height
                    radius: height / 2
                    color: Colors.m3primary

                    Behavior on width {
                        NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
                    }
                }
            }

            // Quick reply, when the app offers it.
            TextField {
                visible: root.canType && (root.notification?.hasInlineReply ?? false)
                width: parent.width
                implicitHeight: Theme.slider.height - Theme.spacing.s
                placeholder: root.notification?.inlineReplyPlaceholder || "Reply"
                onAccepted: {
                    if (text === "")
                        return;
                    root.notification.sendInlineReply(text);
                    root.notification.dismiss();
                }
            }

            // The app's buttons, except the default action (that's clicking the card).
            Row {
                readonly property var buttons: (root.notification?.actions ?? []).filter(a => a.identifier !== "default")
                readonly property bool replyButton: !root.canType && (root.notification?.hasInlineReply ?? false)

                visible: buttons.length > 0 || replyButton
                topPadding: Theme.spacing.xs
                spacing: Theme.spacing.xs

                TextButton {
                    visible: parent.replyButton
                    text: "Reply"
                    filled: true
                    onClicked: root.replyRequested()
                }

                Repeater {
                    model: parent.buttons

                    TextButton {
                        required property NotificationAction modelData
                        required property int index

                        text: modelData.text
                        filled: index === 0
                        onClicked: {
                            modelData.invoke();
                            root.notification.dismiss();
                        }
                    }
                }
            }
        }
    }
}
