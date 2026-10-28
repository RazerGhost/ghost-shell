// Now playing, from any MPRIS player (Spotify, Zen, mpv...), shared by the island's live
// activity, its hover player and the media menu.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris

Singleton {
    // The player that's playing, otherwise the first one (e.g. paused music). null without any.
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying)
                                          ?? Mpris.players.values[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false

    // The player's window, matched by its .desktop name (Spotify's is "spotify"); null when it
    // has none (a browser tab plays in the browser's window, which this can't tell apart).
    readonly property HyprlandToplevel window: {
        const app = (player?.desktopEntry ?? "").toLowerCase();
        return app ? Windows.recent.find(t => t.wayland.appId.toLowerCase() === app) ?? null : null;
    }

    // Bring the player to the front. Through Hyprland, not MPRIS's raise(): apps may not take
    // the focus themselves here (they get an attention card instead).
    function show(): void {
        if (window)
            Windows.show(window);
        else if (player?.canRaise)
            player.raise();
    }
}
