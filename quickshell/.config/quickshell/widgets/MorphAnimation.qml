import QtQuick
import qs.theme

// The island's open/close motion (and the dock's slide): Material 3's "emphasized decelerate"
// curve, fast at first and settling gently. Use it in a Behavior.
NumberAnimation {
    duration: Theme.anim.morph
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.anim.emphasized
}
