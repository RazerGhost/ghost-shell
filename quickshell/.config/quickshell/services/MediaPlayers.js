// Which MPRIS player the shell follows (services/Media.qml): the island, its menus, the desktop
// widget and the media keys. Plain JavaScript, so it can be tested (tests/tst_mediaplayers.qml).
.pragma library

// The one playing, otherwise the one that played last (still running), otherwise the music app
// heard last (by its desktop entry, which survives a shell restart), otherwise the first one;
// null without any. Not simply the first: KDE Connect's phone players come first, so a paused
// Spotify lost the island and the media keys to the phone. `players` is the running players
// (objects with isPlaying and desktopEntry), `last` the one that played last (or null),
// `lastApp` the music app's desktop entry id ("" for none).
// playerctld is left out: it's a mirror of whichever player is active (started on demand by
// anything that asks playerctl for it), so it would be the same music twice.
function chosen(players, last, lastApp) {
    const list = Array.from(players).filter(p => !String(p.dbusName ?? "").endsWith(".playerctld"));
    return list.find(p => p.isPlaying)
        ?? (last && list.includes(last) ? last : null)
        ?? (lastApp ? list.find(p => p.desktopEntry === lastApp) : null)
        ?? list[0] ?? null;
}

// A track's details as `playerctl metadata --format` prints them with a tab between the title,
// artist, album and cover address (Media.qml reads them itself when a player reports none);
// null for anything else, or without a title.
function parseMetadata(text) {
    const parts = String(text ?? "").split("\n")[0].split("\t");
    if (parts.length !== 4 || parts[0] === "")
        return null;
    return { title: parts[0], artist: parts[1], album: parts[2], artUrl: parts[3] };
}

// One of a track's details: the player's own, else the one read for it (`read`, from
// parseMetadata) while the player reports none.
function detail(own, read, key) {
    return own ? own : (read?.[key] ?? "");
}
