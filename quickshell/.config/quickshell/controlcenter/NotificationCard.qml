import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets
import "NotificationTime.js" as NotificationTime

// One notification: app icon (or the notification's own image), app and time, title, text,
// and the app's action buttons. Click it to run its default action; × dismisses it. Used for
// the island's pop-up and in the history in the "today" menu.
MouseArea {
    id: root

    required property Notification notification
    // For the "5 min" label; the history ticks it every minute.
    property real now: Date.now()

    // A path or URL to an image, or an icon theme name.
    function imageSource(source: string): string {
        if (source === "")
            return "";
        if (source.startsWith("/"))
            return "file://" + source;
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

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.l
        color: root.notification?.urgency === NotificationUrgency.Critical ? Colors.m3primaryContainer
                                                                            : Colors.m3surfaceContainerHigh
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
                color: Colors.m3onSurfaceVariant
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
                    color: Colors.m3onSurfaceVariant
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
                color: Colors.m3onSurface
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
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            // The app's buttons, except the default action (that's clicking the card).
            Row {
                readonly property var buttons: (root.notification?.actions ?? []).filter(a => a.identifier !== "default")

                visible: buttons.length > 0
                topPadding: Theme.spacing.xs
                spacing: Theme.spacing.xs

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
