// A local file's path as a file:// URL for an Image or a video. `"file://" + path` breaks on
// names with # ? or % in them (Qt reads # as the start of a fragment, ? as a query, % as an
// escape), so a picture named "art #2.png" showed nothing. Each part of the path is
// percent-encoded; the slashes stay. "" for no path. Plain JavaScript, tested
// (tests/tst_fileurl.qml).
.pragma library

// The other way: a file:// URL (a file dropped from a file manager) as its path; "" for
// anything that isn't a local file (or a broken % escape).
function pathOf(url) {
    const match = /^file:\/\/(localhost)?(\/[^?#]*)/.exec(String(url || ""));
    if (!match)
        return "";
    try {
        return decodeURIComponent(match[2]);
    } catch (error) {
        return "";
    }
}

function of(path) {
    if (!path)
        return "";
    return "file://" + String(path).split("/").map(encodeURIComponent).join("/");
}
