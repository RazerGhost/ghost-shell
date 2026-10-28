// Now playing, from any MPRIS player (Spotify, Zen, mpv...), shared by the island's live
// activity, its hover player and the media menu.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    // The player that's playing, otherwise the first one (e.g. paused music). null without any.
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying)
                                          ?? Mpris.players.values[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false
}
