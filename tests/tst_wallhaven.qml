import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/Wallhaven.js" as Wallhaven

TestCase {
    name: "Wallhaven"

    function sample(over) {
        return Object.assign({ id: "x6128o", purity: "sfw", file_type: "image/jpeg", resolution: "3840x2160",
                               path: "https://w.wallhaven.cc/full/x6/wallhaven-x6128o.jpg",
                               thumbs: { large: "https://th.wallhaven.cc/lg/x6/x6128o.jpg",
                                         small: "https://th.wallhaven.cc/small/x6/x6128o.jpg" } }, over);
    }

    function test_searchUrl() {
        const top = Wallhaven.searchUrl([], "", 1, false);
        verify(top.startsWith("https://wallhaven.cc/api/v1/search?"));
        verify(top.includes("purity=100"));
        verify(top.includes("categories=010"));
        verify(top.includes("sorting=toplist"));
        verify(!top.includes("q="));
        // Words: by relevance, encoded.
        const words = Wallhaven.searchUrl(["night", "city"], "", 2, false);
        verify(words.includes("q=night%20city"));
        verify(words.includes("sorting=relevance"));
        verify(words.includes("page=2"));
        // A style: its words first, its favourites; painterly brings general art.
        const lofi = Wallhaven.searchUrl(["rain"], "lofi", 1, false);
        verify(lofi.includes("q=indoors%20%2Bwindow%20rain"));
        verify(lofi.includes("sorting=favorites"));
        verify(Wallhaven.searchUrl([], "painterly", 1, false).includes("categories=110"));
        verify(Wallhaven.searchUrl([], "", 1, true).includes("categories=110"));
        // Never anything but safe for work, whatever's asked; a bad page is the first.
        verify(Wallhaven.searchUrl(["purity=111"], "", 0, false).includes("purity=100&"));
        verify(Wallhaven.searchUrl([], "", 0, false).includes("page=1"));
        verify(Wallhaven.searchUrl([], "nope", 1, false).includes("sorting=toplist"));
    }

    function test_picture() {
        const p = Wallhaven.picture(sample({}));
        compare(p.file, "wallhaven-x6128o.jpg");
        compare(p.thumb, "https://th.wallhaven.cc/lg/x6/x6128o.jpg");
        compare(p.resolution, "3840 × 2160");
        compare(Wallhaven.picture(sample({ file_type: "image/png", path: "https://w.wallhaven.cc/full/x6/wallhaven-x6128o.png" })).file,
                "wallhaven-x6128o.png");
        // Anything else is left out.
        compare(Wallhaven.picture(sample({ purity: "sketchy" })), null);
        compare(Wallhaven.picture(sample({ file_type: "image/gif" })), null);
        compare(Wallhaven.picture(sample({ id: "../x" })), null);
        compare(Wallhaven.picture(sample({ path: "https://evil.example/full/x6/wallhaven-x6128o.jpg" })), null);
        compare(Wallhaven.picture(null), null);
        // A thumbnail elsewhere isn't shown.
        compare(Wallhaven.picture(sample({ thumbs: { large: "https://evil.example/x.jpg" } })).thumb, "");
    }

    function test_results() {
        const r = Wallhaven.results(JSON.stringify({ data: [sample({}), sample({ purity: "nsfw" })], meta: { last_page: 7 } }));
        compare(r.pictures.length, 1);
        compare(r.lastPage, 7);
        compare(Wallhaven.results("not json").pictures, []);
        compare(Wallhaven.results("{}").lastPage, 0);
    }

    function test_pictureUrl() {
        compare(Wallhaven.pictureUrl("x6128o"), "https://wallhaven.cc/api/v1/w/x6128o");
        compare(Wallhaven.pictureUrl("x/../y"), "");
    }
}
