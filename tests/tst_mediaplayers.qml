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
    }
}
