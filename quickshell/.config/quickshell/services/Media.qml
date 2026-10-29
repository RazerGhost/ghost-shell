// Now playing, from any MPRIS player (Spotify, Zen, mpv...), shared by the island's live
// activity, its hover player and the media menu.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    // The player that's playing, otherwise the first one (e.g. paused music). null without any.
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying)
                                          ?? Mpris.players.values[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false

    // The player's window, matched by its .desktop name (Spotify's is "spotify"); null when it
    // has none (a browser tab plays in the browser's window, which this can't tell apart).
    readonly property HyprlandToplevel window: Windows.forApp(player?.desktopEntry ?? "")

    // The cover as a local file, for ColorQuantizer (the media menu's accent), which can't read
    // the web addresses players give (Spotify's are https). Downloaded once per track into
    // $XDG_RUNTIME_DIR; a local cover is used as it is.
    readonly property string artUrl: player?.trackArtUrl ?? ""
    property string artFile: ""
    onArtUrlChanged: {
        if (artUrl.startsWith("file://")) {
            artFile = artUrl.slice("file://".length);
        } else if (artUrl.startsWith("http")) {
            artFile = "";
            // A new name per track, so the quantizer sees a new file; the previous one goes.
            const target = Quickshell.env("XDG_RUNTIME_DIR") + "/qs-cover-" + Date.now();
            download.start(["sh", "-c", `rm -f "\${XDG_RUNTIME_DIR}"/qs-cover-*; exec curl -sfL --max-time 10 -o "$1" "$2"`,
                            "sh", target, artUrl]);
        } else {
            artFile = "";
        }
    }

    // Skipping tracks while one downloads: the newest track's cover downloads after it.
    LatestProcess {
        id: download
        onExited: code => {
            // command[4] is the file this run wrote ("sh", "-c", script, "sh", target, url).
            if (code === 0)
                root.artFile = command[4];
        }
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
