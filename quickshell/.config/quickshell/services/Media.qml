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
    // A moment later, not inside `player`'s own change: setting lastPlaying there re-evaluated
    // `player` while it was still being evaluated ("Binding loop detected" each time a player
    // started).
    function rememberPlaying(): void {
        if (playing && lastPlaying !== player)
            Qt.callLater(() => {
                if (root.playing)
                    root.lastPlaying = root.player;
            });
    }
    onPlayerChanged: {
        rememberPlaying();
        Qt.callLater(checkDetails); // not inside `player`'s change (the binding loop above)
    }

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

    // The playing track's details, for the views to show (title(), artist(), album(), artUrl).
    // Spotify doesn't announce the first track after it starts: it's on the bus before the track
    // has loaded, and Quickshell only learns of changes, so that track showed with no title,
    // artist or cover until the next one (user's find, 2026-11-05; a fresh Quickshell read it
    // fine). While the followed player plays without a title, the shell reads the details itself
    // with playerctl, a few times a second apart in case the track is still loading; the
    // player's own take over as soon as it has them.
    readonly property bool missingDetails: (player?.isPlaying ?? false) && !player.trackTitle
    property var readDetails: null // MediaPlayers.parseMetadata's result, for `player`
    property int readTries: 0
    onMissingDetailsChanged: Qt.callLater(checkDetails) // it changes while `player` is still being set
    function checkDetails(): void {
        readDetails = null;
        readTries = 0;
        detailsRetry.stop();
        if (missingDetails)
            readMetadata();
    }
    readonly property string playerName: (player?.dbusName ?? "").replace("org.mpris.MediaPlayer2.", "")
    function readMetadata(): void {
        if (playerName !== "")
            metadataRead.start(["playerctl", "-p", playerName, "metadata", "--format",
                                "{{xesam:title}}\t{{xesam:artist}}\t{{xesam:album}}\t{{mpris:artUrl}}"]);
    }
    LatestProcess {
        id: metadataRead
        stdout: StdioCollector {
            onStreamFinished: {
                // Only for the player still followed, while it still has no details of its own.
                if (!root.missingDetails || metadataRead.command[2] !== root.playerName)
                    return;
                const details = MediaPlayers.parseMetadata(text);
                if (details)
                    root.readDetails = details;
                else if (++root.readTries < 5)
                    detailsRetry.restart();
            }
        }
    }
    Timer {
        id: detailsRetry
        interval: 1000
        onTriggered: root.readMetadata()
    }

    // A track detail of `p`: for the followed player, its own or the ones read above.
    function title(p: var): string {
        return p === player ? MediaPlayers.detail(p?.trackTitle, readDetails, "title") : (p?.trackTitle ?? "");
    }
    function artist(p: var): string {
        return p === player ? MediaPlayers.detail(p?.trackArtist, readDetails, "artist") : (p?.trackArtist ?? "");
    }
    function album(p: var): string {
        return p === player ? MediaPlayers.detail(p?.trackAlbum, readDetails, "album") : (p?.trackAlbum ?? "");
    }

    // The cover as a local file, for ColorQuantizer (the media menu's accent), which can't read
    // the web addresses players give (Spotify's are https). Downloaded once per track into
    // $XDG_RUNTIME_DIR; a local cover is used as it is.
    readonly property string artUrl: MediaPlayers.detail(player?.trackArtUrl, readDetails, "artUrl")
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
        // (root.artUrl includes a cover read by readMetadata)
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

    // On `player`, for the island (middle-click, the wheel over the cover) and the media keys.
    function playPause(): void {
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }
    function next(): void {
        if (player?.canGoNext)
            player.next();
    }
    function previous(): void {
        if (player?.canGoPrevious)
            player.previous();
    }

    // The keyboard's media keys (hypr/binds.lua): `qs ipc call media playPause|next|previous`.
    IpcHandler {
        target: "media"

        function playPause(): void {
            root.playPause();
        }
        function next(): void {
            root.next();
        }
        function previous(): void {
            root.previous();
        }
    }
}
