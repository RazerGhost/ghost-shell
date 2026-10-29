import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/NetworkExtras.js" as NetworkExtras

TestCase {
    name: "NetworkExtras"

    readonly property string listing: [
        "HomeNetwork:f975:802-11-wireless:yes",
        "ProtonVPN NL\\:12:aa11:wireguard:yes",
        "Work:bb22:vpn:no",
        "Hotspot:cc33:802-11-wireless:no",
        ""
    ].join("\n")

    function test_fields() {
        compare(NetworkExtras.fields("a\\:b:c\\\\d:e"), ["a:b", "c\\d", "e"]);
    }

    function test_connections() {
        const list = NetworkExtras.connections(listing);
        compare(list.length, 4);
        compare(list[1].name, "ProtonVPN NL:12");
        compare(list[1].uuid, "aa11");
        verify(list[1].active);
        verify(!list[2].active);
        compare(NetworkExtras.vpns(list).map(c => c.name), ["ProtonVPN NL:12", "Work"]);
        verify(!NetworkExtras.hotspotActive(list));
        verify(NetworkExtras.hotspotActive(NetworkExtras.connections("Hotspot:cc33:802-11-wireless:yes")));
    }

    function test_airplane() {
        verify(NetworkExtras.airplane("blocked\nblocked\n"));
        verify(!NetworkExtras.airplane("blocked\nunblocked\n"));
        verify(!NetworkExtras.airplane(""));
    }
}
