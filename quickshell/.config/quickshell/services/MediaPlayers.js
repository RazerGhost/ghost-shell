// Which MPRIS player the shell follows (services/Media.qml): the island, its menus, the desktop
// widget and the media keys. Plain JavaScript, so it can be tested (tests/tst_mediaplayers.qml).
.pragma library

// The one playing, otherwise the one that played last (still running), otherwise the music app
// heard last (by its desktop entry, which survives a shell restart), otherwise the first one;
// null without any. Not simply the first: KDE Connect's phone players come first, so a paused
// Spotify lost the island and the media keys to the phone. `players` is the running players
// (objects with isPlaying and desktopEntry), `last` the one that played last (or null),
// `lastApp` the music app's desktop entry id ("" for none).
function chosen(players, last, lastApp) {
    const list = Array.from(players);
    return list.find(p => p.isPlaying)
        ?? (last && list.includes(last) ? last : null)
        ?? (lastApp ? list.find(p => p.desktopEntry === lastApp) : null)
        ?? list[0] ?? null;
}
