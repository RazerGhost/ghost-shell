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

// wallhaven's color filter: the colors it sorts pictures into (its own palette; any other is
// refused), with names for screen readers.
const colors = [
    { hex: "660000", name: "Maroon" }, { hex: "990000", name: "Dark red" }, { hex: "cc0000", name: "Red" },
    { hex: "cc3333", name: "Brick red" }, { hex: "ea4c88", name: "Pink" }, { hex: "993399", name: "Purple" },
    { hex: "663399", name: "Violet" }, { hex: "333399", name: "Indigo" }, { hex: "0066cc", name: "Blue" },
    { hex: "0099cc", name: "Sky blue" }, { hex: "66cccc", name: "Turquoise" }, { hex: "77cc33", name: "Lime" },
    { hex: "669900", name: "Green" }, { hex: "336600", name: "Dark green" }, { hex: "666600", name: "Olive" },
    { hex: "999900", name: "Dark yellow" }, { hex: "cccc33", name: "Mustard" }, { hex: "ffff00", name: "Yellow" },
    { hex: "ffcc33", name: "Gold" }, { hex: "ff9900", name: "Orange" }, { hex: "ff6600", name: "Dark orange" },
    { hex: "cc6633", name: "Rust" }, { hex: "996633", name: "Brown" }, { hex: "663300", name: "Dark brown" },
    { hex: "000000", name: "Black" }, { hex: "999999", name: "Grey" }, { hex: "cccccc", name: "Light grey" },
    { hex: "ffffff", name: "White" }, { hex: "424153", name: "Slate" }
];

// The search's URL, from { words, style, page, general, tag, color }: SFW only (purity 100), anime
// (categories 010; with general art too 110), at least 1920x1080 in 16:9.
// - tag: a wallhaven tag's id ("More like this": the pictures with one of a picture's tags);
//   it stands on its own, without the words or a style.
// - style: its words first, then the typed ones.
// - color: one of `colors`, with any of the above.
// Sorted by favourites for a style, a tag or a color alone (the best of all time: a month's
// best in one color is a handful); by relevance for typed words; else the month's top list.
// `page` counts from 1.
function searchUrl(search) {
    const tag = /^\d+$/.test(String(search.tag ?? "")) ? String(search.tag) : "";
    const chosen = tag ? null : style(search.style ?? "");
    const words = tag ? [] : (search.words ?? []).filter(w => w !== "");
    const all = tag ? ["id:" + tag] : (chosen ? chosen.words : []).concat(words);
    const color = colors.some(c => c.hex === search.color) ? search.color : "";
    const params = {
        categories: search.general || chosen?.general ? "110" : "010",
        purity: "100",
        atleast: "1920x1080",
        ratios: "16x9",
        page: String(Math.max(1, Math.floor(search.page) || 1)),
        sorting: tag || (chosen && chosen.value !== "") || (color && words.length === 0) ? "favorites"
               : words.length > 0 ? "relevance" : "toplist",
        topRange: "1M"
    };
    if (all.length > 0)
        params.q = all.join(" ");
    if (color)
        params.colors = color;
    return "https://wallhaven.cc/api/v1/search?" + Object.keys(params)
        .map(k => k + "=" + encodeURIComponent(params[k])).join("&");
}

// One picture's page in the API: for downloading it by its id, and its tags.
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

// A picture's tags from its page (the API's JSON text), for "More like this": [{ id, name }],
// safe-for-work tags only, at most `most`.
function tags(text, most) {
    let answer;
    try {
        answer = JSON.parse(text);
    } catch (e) {
        return [];
    }
    const list = Array.isArray(answer?.data?.tags) ? answer.data.tags : [];
    return list.filter(t => t?.purity === "sfw" && /^\d+$/.test(String(t.id)) && typeof t.name === "string" && t.name !== "")
        .slice(0, most)
        .map(t => ({ id: String(t.id), name: t.name }));
}
