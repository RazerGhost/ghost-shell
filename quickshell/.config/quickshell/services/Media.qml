// Now playing, from any MPRIS player (Spotify, Zen, mpv...), shared by the island's live
// activity, its hover player and the media menu.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import "MediaPlayers.js" as MediaPlayers

Singleton {
    id: root

    // The player that's playing, otherwise the one that played last, otherwise the first one
    // (MediaPlayers.js). null without any.
    readonly property MprisPlayer player: MediaPlayers.chosen(Mpris.players.values, lastPlaying,
                                                              Settings.values.lastMediaApp ?? "")
    readonly property bool playing: player?.isPlaying ?? false
    // Cleared by itself when that player goes away. Kept when a paused player plays again
    // (onPlayingChanged) and when another one takes over while music plays (here).
    property MprisPlayer lastPlaying: null
    function rememberPlaying(): void {
        if (playing)
            lastPlaying = player;
    }
    onPlayerChanged: rememberPlaying()

    // The music app last heard (Settings' lastMediaApp), for the desktop's media widget to open
    // while no player is running; before one has been heard, the first installed music app
    // (Spotify here). Only music players: a video in the browser isn't one to come back to. The
    // app list is read so it's found once it has filled in (NOTES).
    readonly property DesktopEntry lastApp: {
        const apps = DesktopEntries.applications.values;
        const id = Settings.values.lastMediaApp;
        return (id ? DesktopEntries.byId(id) : null) ?? apps.find(isMusic) ?? null;
    }
    function isMusic(entry: DesktopEntry): bool {
        return entry.categories.includes("Music"); // not every audio tool (a mixer, a video player)
    }
    onPlayingChanged: {
        rememberPlaying();
        const entry = playing ? DesktopEntries.heuristicLookup(player.desktopEntry || player.identity || "") : null;
        if (entry && isMusic(entry) && Settings.values.lastMediaApp !== entry.id)
            Settings.values.lastMediaApp = entry.id;
    }

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

    // The cover to show for `player`: for the current player the downloaded copy, so a cover is
    // fetched once rather than again by every image showing it (nothing while it downloads: the
    // placeholder shows); for another player its own address.
    function cover(player: var): string {
        if (!player)
            return "";
        if (player !== root.player)
            return player.trackArtUrl ?? "";
        if (artFile !== "")
            return "file://" + artFile;
        return artUrl.startsWith("http") ? "" : artUrl;
    }

    // Skipping tracks while one downloads: the newest track's cover downloads after it.
    LatestProcess {
        id: download
        onExited: code => {
            // command[4] is the file this run wrote, command[5] its address ("sh", "-c", script,
            // "sh", target, url). Only for the track still playing: an older track's download
            // finishing late would put its cover back.
            if (code === 0 && command[5] === root.artUrl)
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

    // The keyboard's media keys (hypr/binds.lua): `qs ipc call media playPause|next|previous`,
    // acting on `player` like the island's controls.
    IpcHandler {
        target: "media"

        function playPause(): void {
            if (root.player?.canTogglePlaying)
                root.player.togglePlaying();
        }
        function next(): void {
            if (root.player?.canGoNext)
                root.player.next();
        }
        function previous(): void {
            if (root.player?.canGoPrevious)
                root.player.previous();
        }
    }
}
