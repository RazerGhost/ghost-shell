import QtQuick
import QtTest
import "../quickshell/.config/quickshell/settings/XkbLayouts.js" as XkbLayouts

TestCase {
    name: "XkbLayouts"

    function test_layouts() {
        const lst = [
            "! model",
            "  pc105           Generic 105-key PC",
            "",
            "! layout",
            "  us              English (US)",
            "  nl              Dutch",
            "  de              German",
            "",
            "! variant",
            "  intl            us: English (US, intl., with dead keys)"
        ].join("\n");
        compare(XkbLayouts.layouts(lst), [
            { code: "nl", name: "Dutch" },
            { code: "us", name: "English (US)" },
            { code: "de", name: "German" }
        ]);
    }
}
