import QtQuick
import qs.services
import qs.widgets
import "../services/CaptureFolders.js" as CaptureFolders

// A folder setting (Settings -> Screenshots and recordings): the current folder as the
// placeholder; type another and press Enter (empty: the default, "~/..." in your home folder).
TextField {
    property string key      // the setting
    property string fallback // its default folder
    property string home

    placeholder: CaptureFolders.short(CaptureFolders.folder(Settings.values[key], home, fallback), home)
                 + "  (type another and press Enter; empty for the default)"
    onAccepted: {
        Settings.values[key] = text.trim();
        text = "";
    }
}
