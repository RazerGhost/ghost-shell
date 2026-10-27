import QtQuick
import qs.services

// Speaker volume. Click to mute, scroll to change it.
BarIcon {
    icon: Audio.icon
    label: Audio.muted ? "Volume, muted" : "Volume " + Math.round(Audio.volume * 100) + "%"
    interactive: true
    onClicked: Audio.toggleMute()
    onScrolled: steps => Audio.setVolume(Audio.volume + steps * 0.05)
}
