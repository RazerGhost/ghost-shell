import QtQuick
import QtTest
import "../quickshell/.config/quickshell/customize/SavedLooks.js" as SavedLooks
import "../quickshell/.config/quickshell/customize/Presets.js" as Presets

TestCase {
    name: "SavedLooks"

    function test_valid() {
        compare(SavedLooks.valid(undefined, ["a"]), []);
        compare(SavedLooks.valid([{ name: "", values: { a: 1 } }, { name: "B" }, "x"], ["a"]), []);
        // Unknown keys dropped; a look with none of the gallery's left is dropped too.
        compare(SavedLooks.valid([{ name: "A", values: { a: 1, z: 2 } }, { name: "C", values: { z: 3 } }], ["a"]),
                [{ name: "A", values: { a: 1 } }]);
        // As settings.json gives a list back: array-like.
        compare(SavedLooks.valid({ length: 1, 0: { name: "A", values: { a: 1 } } }, ["a"]), [{ name: "A", values: { a: 1 } }]);
    }

    function test_made() {
        const values = { a: 1, list: { length: 2, 0: "x", 1: "y" }, place: { x: 0.1 }, other: 5 };
        const look = SavedLooks.made(["Look 1", "Classic"], values, ["a", "list", "place", "missing"], "Look");
        compare(look.name, "Look 2");
        compare(look.values, { a: 1, list: ["x", "y"], place: { x: 0.1 }, missing: null });
        values.place.x = 0.9;
        compare(look.values.place.x, 0.1);
    }

    function test_renamedRemoved() {
        const looks = [{ name: "Look 1", values: {} }, { name: "Look 2", values: {} }];
        compare(SavedLooks.renamed(looks, "Look 1", " Night ", []).map(l => l.name), ["Night", "Look 2"]);
        compare(SavedLooks.renamed(looks, "Look 1", "Look 2", []).map(l => l.name), ["Look 1", "Look 2"]);
        // A preset's name is taken too.
        compare(SavedLooks.renamed(looks, "Look 1", "Classic", ["Classic"]).map(l => l.name), ["Look 1", "Look 2"]);
        compare(SavedLooks.removed(looks, "Look 1").map(l => l.name), ["Look 2"]);
    }

    // Each gallery's saved looks are in its editor's Cancel list, so Cancel puts them back.
    function test_cancelKeepsThem() {
        verify(Presets.lockKeys.includes("lockLooks"));
        verify(Presets.dockIslandKeys.includes("dockLooks"));
        verify(Presets.windowsKeys.includes("windowLooks"));
        verify(Presets.desktopKeys.includes("widgetLooks"));
    }
}
