import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/MediaPlayers.js" as MediaPlayers

TestCase {
    name: "MediaPlayers"

    readonly property var phone: ({ desktopEntry: "org.kde.kdeconnect", isPlaying: false })
    readonly property var spotify: ({ desktopEntry: "spotify", isPlaying: false })
    readonly property var zen: ({ desktopEntry: "zen", isPlaying: true })

    function test_chosen() {
        compare(MediaPlayers.chosen([], null, ""), null);
        // Nothing played yet: the first.
        compare(MediaPlayers.chosen([phone, spotify], null, ""), phone);
        // Paused Spotify keeps its place over the phone.
        compare(MediaPlayers.chosen([phone, spotify], spotify, ""), spotify);
        // One that plays wins.
        compare(MediaPlayers.chosen([phone, spotify, zen], spotify, "spotify"), zen);
        // The last one quit: the first again.
        compare(MediaPlayers.chosen([phone], spotify, "spotify"), phone);
        // After a restart nothing has played yet: the music app heard last.
        compare(MediaPlayers.chosen([phone, spotify], null, "spotify"), spotify);
        // The one that played last comes before the music app.
        compare(MediaPlayers.chosen([phone, spotify], phone, "spotify"), phone);
        // playerctld mirrors the playing one: never followed, even listed first.
        const mirror = { dbusName: "org.mpris.MediaPlayer2.playerctld", desktopEntry: "spotify", isPlaying: true };
        const playing = { dbusName: "org.mpris.MediaPlayer2.spotify", desktopEntry: "spotify", isPlaying: true };
        compare(MediaPlayers.chosen([mirror, playing], null, ""), playing);
        compare(MediaPlayers.chosen([mirror], null, ""), null);
    }

    function test_parseMetadata() {
        compare(MediaPlayers.parseMetadata("Body\tDon Toliver\tOCTANE\thttps://i.scdn.co/image/ab\n"),
                { title: "Body", artist: "Don Toliver", album: "OCTANE", artUrl: "https://i.scdn.co/image/ab" });
        // No album or cover: kept empty.
        compare(MediaPlayers.parseMetadata("Song\tSomeone\t\t"), { title: "Song", artist: "Someone", album: "", artUrl: "" });
        // No title yet, an error, or nothing at all: nothing.
        compare(MediaPlayers.parseMetadata("\t\t\t"), null);
        compare(MediaPlayers.parseMetadata("No players found"), null);
        compare(MediaPlayers.parseMetadata(""), null);
        compare(MediaPlayers.parseMetadata(undefined), null);
    }

    function test_detail() {
        const read = { title: "Body", artist: "Don Toliver", album: "OCTANE", artUrl: "https://x" };
        compare(MediaPlayers.detail("E85", read, "title"), "E85");   // the player's own wins
        compare(MediaPlayers.detail("", read, "title"), "Body");     // none: the one read
        compare(MediaPlayers.detail(undefined, null, "artist"), ""); // neither
    }
}
