// A local file's path as a file:// URL for an Image or a video. `"file://" + path` breaks on
// names with # ? or % in them (Qt reads # as the start of a fragment, ? as a query, % as an
// escape), so a picture named "art #2.png" showed nothing. Each part of the path is
// percent-encoded; the slashes stay. "" for no path. Plain JavaScript, tested
// (tests/tst_fileurl.qml).
.pragma library

function of(path) {
    if (!path)
        return "";
    return "file://" + String(path).split("/").map(encodeURIComponent).join("/");
}
