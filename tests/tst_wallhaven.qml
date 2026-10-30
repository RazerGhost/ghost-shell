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

    function url(search) {
        return Wallhaven.searchUrl(search);
    }

    function test_searchUrl() {
        const top = url({ words: [], style: "", page: 1 });
        verify(top.startsWith("https://wallhaven.cc/api/v1/search?"));
        verify(top.includes("purity=100"));
        verify(top.includes("categories=010"));
        verify(top.includes("sorting=toplist"));
        verify(!top.includes("q="));
        // Words: by relevance, encoded.
        const words = url({ words: ["night", "city"], page: 2 });
        verify(words.includes("q=night%20city"));
        verify(words.includes("sorting=relevance"));
        verify(words.includes("page=2"));
        // A style: its words first, its favourites; painterly brings general art.
        const lofi = url({ words: ["rain"], style: "lofi", page: 1 });
        verify(lofi.includes("q=indoors%20%2Bwindow%20rain"));
        verify(lofi.includes("sorting=favorites"));
        verify(url({ style: "painterly", page: 1 }).includes("categories=110"));
        verify(url({ page: 1, general: true }).includes("categories=110"));
        // Never anything but safe for work, whatever's asked; a bad page is the first.
        verify(url({ words: ["purity=111"], page: 0 }).includes("purity=100&"));
        verify(url({ page: 0 }).includes("page=1"));
        verify(url({ style: "nope", page: 1 }).includes("sorting=toplist"));
    }

    function test_searchUrlTag() {
        // A tag stands alone: no words or style, its favourites.
        const tag = url({ tag: "1748", words: ["x"], style: "lofi", page: 1 });
        verify(tag.endsWith("q=id%3A1748"));
        verify(tag.includes("sorting=favorites"));
        verify(!tag.includes("indoors"));
        // Not a tag id: ignored.
        verify(!url({ tag: "1 OR 2", page: 1 }).includes("id%3A"));
    }

    function test_searchUrlColor() {
        // A color alone: the best of all time in it; with words, by relevance.
        const blue = url({ color: "0066cc", page: 1 });
        verify(blue.includes("colors=0066cc"));
        verify(blue.includes("sorting=favorites"));
        verify(url({ color: "0066cc", words: ["sea"], page: 1 }).includes("sorting=relevance"));
        verify(url({ color: "0066cc", tag: "5", page: 1 }).includes("colors=0066cc"));
        // Only wallhaven's own colors.
        verify(!url({ color: "123456", page: 1 }).includes("colors="));
        compare(Wallhaven.colors.length, 29);
    }

    function test_tags() {
        const page = JSON.stringify({ data: { tags: [
            { id: 1748, name: "clouds", purity: "sfw" },
            { id: 9, name: "something", purity: "sketchy" },
            { id: "x", name: "bad id", purity: "sfw" },
            { id: 37, name: "sea", purity: "sfw" },
            { id: 12, name: "sky", purity: "sfw" }
        ] } });
        compare(Wallhaven.tags(page, 8), [{ id: "1748", name: "clouds" }, { id: "37", name: "sea" }, { id: "12", name: "sky" }]);
        compare(Wallhaven.tags(page, 2).length, 2);
        compare(Wallhaven.tags("nope", 8), []);
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
