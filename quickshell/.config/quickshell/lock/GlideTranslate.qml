import QtQuick
import qs.theme

// A move of part of the lock screen that glides to a new place (a look, an arrow key's step) and
// follows a drag at once (`content`, the LockContent, says when one goes on or is being saved).
Translate {
    required property Item content

    Behavior on x { enabled: !content.dragging && !content.settling; NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
    Behavior on y { enabled: !content.dragging && !content.settling; NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
}
