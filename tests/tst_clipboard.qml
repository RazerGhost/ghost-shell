// Tests for parsing cliphist's list. Run from the repo root:
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/ClipboardEntries.js" as Entries

TestCase {
    name: "ClipboardEntries"

    function test_text() {
        const e = Entries.parse("78\tsudo cachyos-rate-mirrors");
        compare(e.id, "78");
        compare(e.text, "sudo cachyos-rate-mirrors");
        compare(e.image, null);
    }

    function test_textWithTabs() {
        compare(Entries.parse("5\ta\tb").text, "a\tb");
    }

    function test_image() {
        const e = Entries.parse("80\t[[ binary data 120 KiB png 1920x1080 ]]");
        compare(e.text, "");
        compare(e.image.format, "png");
        compare(e.image.size, "120 KiB");
        compare(e.image.width, 1920);
        compare(e.image.height, 1080);
    }

    function test_binaryWithoutSize() {
        const e = Entries.parse("3\t[[ binary data 2 KiB bmp ]]");
        compare(e.image.format, "bmp");
        compare(e.image.width, 0);
    }

    function test_badLineThrows() {
        let threw = false;
        try {
            Entries.parse("no tab here");
        } catch (err) {
            threw = true;
        }
        verify(threw);
    }

    function test_parseAllSkipsEmptyLines() {
        compare(Entries.parseAll("2\tb\n1\ta\n").map(e => e.id), ["2", "1"]);
    }

    function test_filter() {
        const all = Entries.parseAll("3\t[[ binary data 1 KiB png 10x10 ]]\n2\tHello World\n1\tbye");
        compare(Entries.filter(all, "").length, 3);
        compare(Entries.filter(all, "WORLD").map(e => e.id), ["2"]);
        compare(Entries.filter(all, "ima").map(e => e.id), ["3"]);
    }

    function test_pins() {
        const entries = Entries.parseAll("12\thello\n");
        const list = Entries.withPins(["my address", "", "IBAN NL00"], entries);
        compare(list.map(e => e.text), ["my address", "IBAN NL00", "hello"]);
        verify(list[0].pinned);
        verify(!list[2].pinned);
        compare(Entries.pin(["a"], "b"), ["a", "b"]);
        compare(Entries.pin(["a"], "a"), ["a"]);
        compare(Entries.unpin(["a", "b"], "a"), ["b"]);
        // The search finds pins too.
        compare(Entries.filter(list, "iban").map(e => e.text), ["IBAN NL00"]);
    }
}
