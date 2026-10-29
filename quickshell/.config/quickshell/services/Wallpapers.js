// The wallpaper picker's pictures from services/wallpapers.sh's paths (services/Wallpaper.qml).
// Plain JavaScript, so it can be tested on its own (tests/tst_wallpapers.qml).
.pragma library

// KDE Plasma's layout: <folder>/contents/images/<w>x<h>.<ext>, and images_dark/ for a dark version.
const plasma = /^(.*\/([^/]+))\/contents\/(images|images_dark)\/(\d+)x(\d+)\.[a-z0-9]+$/i;
// A dark or light version by name: "x-dark.png", "x_dark.jpg", "x-d.jxl" (GNOME), "x-light.png", "x-l.jxl".
const variant = /^(.*?)[-_](dark|d|light|l)$/i;

// Of a Plasma picture's sizes ([{ path, w, h }]), the one for a w x h screen: the exact size, else
// the smallest that still covers it, else the biggest.
function bestSize(sizes, w, h) {
    const exact = sizes.find(s => s.w === w && s.h === h);
    if (exact)
        return exact.path;
    const covering = sizes.filter(s => s.w >= w && s.h >= h).sort((a, b) => a.w * a.h - b.w * b.h);
    if (covering.length > 0)
        return covering[0].path;
    return sizes.slice().sort((a, b) => b.w * b.h - a.w * a.h)[0].path;
}

function baseName(path) {
    const file = path.slice(path.lastIndexOf("/") + 1);
    const dot = file.lastIndexOf(".");
    return dot > 0 ? file.slice(0, dot) : file;
}

// A live wallpaper: a video file.
function isVideo(path) {
    return /\.(mp4|webm|mkv|mov)$/i.test(path);
}

// The paths (one per line, yours first) as [{ filePath, fileName, darkPath, own, video, thumb }],
// in their order: a Plasma folder is one picture at the size for a screenW x screenH screen; a
// dark version is paired with its light one (`darkPath`, "" when there's none). `own`: in
// `ownFolder`. A video's line is "<video><tab><thumbnail>" (`thumb`, "" when none was made); its
// own entry, never paired.
function entries(text, screenW, screenH, ownFolder) {
    const thumbs = {};
    const paths = text.split("\n").map(l => l.trim()).filter(l => l !== "").map(line => {
        const tab = line.indexOf("\t");
        if (tab === -1)
            return line;
        thumbs[line.slice(0, tab)] = line.slice(tab + 1);
        return line.slice(0, tab);
    });
    const order = [];
    const groups = {};
    function group(key, name, folder) {
        if (!groups[key]) {
            groups[key] = { name: name, folder: folder, light: [], dark: [] };
            order.push(key);
        }
        return groups[key];
    }
    for (const path of paths) {
        const p = plasma.exec(path);
        if (p) {
            const g = group("plasma:" + p[1], p[2], p[1]);
            (p[3].toLowerCase() === "images_dark" ? g.dark : g.light).push({ path: path, w: +p[4], h: +p[5] });
            continue;
        }
        if (path.includes("/contents/"))
            continue; // a Plasma folder's preview (screenshot.png)
        const folder = path.slice(0, path.lastIndexOf("/"));
        const base = baseName(path);
        if (isVideo(path)) {
            group("video:" + path, base, folder).light.push({ path: path, w: 0, h: 0 });
            continue;
        }
        const v = variant.exec(base);
        const key = folder + "/" + (v ? v[1] : base);
        const g = group(key, v ? v[1] : base, folder);
        const isDark = v && /^d/i.test(v[2]);
        (isDark ? g.dark : g.light).push({ path: path, w: 0, h: 0 });
    }
    const result = [];
    const add = (light, dark, fileName) => result.push({
        filePath: light,
        fileName: fileName,
        darkPath: dark,
        own: ownFolder !== "" && light.startsWith(ownFolder + "/"),
        video: isVideo(light),
        thumb: thumbs[light] ?? ""
    });
    for (const key of order) {
        const g = groups[key];
        // Not one light and one dark picture (art.png and art.jpg, or sky.png and
        // sky-light.png): each is a picture of its own.
        if (!key.startsWith("plasma:") && (g.light.length > 1 || g.dark.length > 1)) {
            for (const s of g.light.concat(g.dark))
                add(s.path, "", s.path.slice(s.path.lastIndexOf("/") + 1));
            continue;
        }
        const pick = list => list.length === 0 ? "" : list.some(s => s.w > 0) ? bestSize(list, screenW, screenH) : list[0].path;
        let light = pick(g.light);
        let dark = pick(g.dark);
        // Only a dark one ("night-dark.png" alone): it's just a picture.
        if (light === "") {
            light = dark;
            dark = "";
        }
        // Two names with -d / -l but no partner: a picture each, not a pair.
        add(light, dark, key.startsWith("plasma:") ? g.name : light.slice(light.lastIndexOf("/") + 1));
    }
    return result;
}
