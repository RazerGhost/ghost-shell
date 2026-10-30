// wallhaven.cc's public search API (no account), for the Wallpapers window
// (wallpaper/WallpaperBrowser.qml) and `ghost wallpapers` (modules/core/wallpapers.sh, through
// js_with). Plain JavaScript, so it can be tested on its own (tests/tst_wallhaven.qml).
// Only ever safe for work: the search asks for it, and every result is checked again.
.pragma library

// The kinds of art you like (user's picks, 2026-10-30), each a search tried on wallhaven first:
// its favourites' tags match the style. "" is the month's best anime.
const styles = [
    { value: "", label: "Top", words: [] },
    { value: "sky", label: "Sky", words: ["clouds"] },                    // scenery, big clouds, cities at dusk, trains
    { value: "lofi", label: "Lofi", words: ["indoors", "+window"] },     // cozy rooms, rain on windows
    { value: "painterly", label: "Painterly", words: ["digital", "painting"], general: true }, // painted, anime or not
    { value: "minimal", label: "Minimal", words: ["+minimalism", "-text"] } // one figure and empty space
];

function style(value) {
    return styles.find(s => s.value === value) ?? null;
}

// The search's URL: SFW only (purity 100), anime (categories 010; with general art too 110),
// at least 1920x1080 in 16:9. A style's words go first and sort by favourites; words alone by
// relevance; nothing, the month's top list. `page` counts from 1.
function searchUrl(words, styleValue, page, general) {
    const chosen = style(styleValue);
    const all = (chosen ? chosen.words : []).concat(words.filter(w => w !== ""));
    const params = {
        categories: general || chosen?.general ? "110" : "010",
        purity: "100",
        atleast: "1920x1080",
        ratios: "16x9",
        page: String(Math.max(1, Math.floor(page) || 1)),
        sorting: chosen && chosen.value !== "" ? "favorites" : all.length > 0 ? "relevance" : "toplist",
        topRange: "1M"
    };
    if (all.length > 0)
        params.q = all.join(" ");
    return "https://wallhaven.cc/api/v1/search?" + Object.keys(params)
        .map(k => k + "=" + encodeURIComponent(params[k])).join("&");
}

// One picture's page in the API, for downloading it by its id.
function pictureUrl(id) {
    return /^[a-z0-9]+$/i.test(id) ? "https://wallhaven.cc/api/v1/w/" + id : "";
}

const extensions = { "image/jpeg": "jpg", "image/png": "png" };

// A result made safe, or null: safe for work, a JPEG or PNG, its id letters and digits (the file
// name is made from it), the picture and its thumbnails on wallhaven's own hosts.
function picture(w) {
    if (!w || w.purity !== "sfw" || !extensions[w.file_type] || !/^[a-z0-9]+$/i.test(w.id ?? ""))
        return null;
    if (!/^https:\/\/w\.wallhaven\.cc\/full\/[a-z0-9]+\/wallhaven-[a-z0-9]+\.(jpg|png)$/i.test(w.path ?? ""))
        return null;
    const thumb = /^https:\/\/th\.wallhaven\.cc\/(lg|small|orig)\/[a-z0-9]+\/[a-z0-9]+\.(jpg|png)$/i;
    const large = w.thumbs?.large ?? "";
    const small = w.thumbs?.small ?? "";
    return {
        id: w.id,
        url: w.path,
        file: "wallhaven-" + w.id + "." + extensions[w.file_type],
        thumb: thumb.test(large) ? large : thumb.test(small) ? small : "",
        resolution: /^\d+x\d+$/.test(w.resolution ?? "") ? w.resolution.replace("x", " × ") : ""
    };
}

// A search's answer (the API's JSON text) as { pictures, lastPage }; nothing usable when it
// isn't one.
function results(text) {
    let answer;
    try {
        answer = JSON.parse(text);
    } catch (e) {
        return { pictures: [], lastPage: 0 };
    }
    const data = Array.isArray(answer?.data) ? answer.data : [];
    return {
        pictures: data.map(picture).filter(p => p !== null),
        lastPage: Number(answer?.meta?.last_page) || 0
    };
}
