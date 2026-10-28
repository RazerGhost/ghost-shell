import QtQuick
import qs.theme

// "−  value  +": steps through a list of `values` (minutes, times of day, temperatures), showing
// the current one through `format`. Like Switch it doesn't change `value` itself: handle
// picked(value) and update what it's bound to.
Row {
    id: root

    required property var values
    property var value
    property var format: v => String(v)
    // Past the last value comes the first again (times of day go round).
    property bool wrap
    property string label // what screen readers announce
    property int valueWidth: Theme.settings.stepper

    signal picked(var value)

    // A value that isn't in the list (a hand-edited settings file) steps from the next one up.
    readonly property int index: {
        const exact = values.indexOf(value);
        if (exact >= 0)
            return exact;
        const above = values.findIndex(v => v >= value);
        return above >= 0 ? above : values.length - 1;
    }

    function step(delta: int): void {
        let i = index + delta;
        if (wrap)
            i = (i + values.length) % values.length;
        if (i >= 0 && i < values.length)
            picked(values[i]);
    }

    spacing: Theme.spacing.xs

    Accessible.role: Accessible.SpinBox
    Accessible.name: label
    Accessible.description: format(value)
    Accessible.onIncreaseAction: step(1)
    Accessible.onDecreaseAction: step(-1)

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "remove"
        label: "Less"
        opacity: root.enabled && (root.wrap || root.index > 0) ? 1 : 0.38
        onClicked: root.step(-1)
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: root.valueWidth
        horizontalAlignment: Text.AlignHCenter
        text: root.format(root.value)
        color: root.enabled ? Colors.m3onSurface : Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
        font.features: { "tnum": 1 }
    }

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "add"
        label: "More"
        opacity: root.enabled && (root.wrap || root.index < root.values.length - 1) ? 1 : 0.38
        onClicked: root.step(1)
    }
}
