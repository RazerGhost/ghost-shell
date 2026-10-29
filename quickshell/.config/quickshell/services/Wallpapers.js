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

// The paths (one per line, yours first) as [{ filePath, fileName, darkPath, own }], in their
// order: a Plasma folder is one picture at the size for a screenW x screenH screen; a dark
// version is paired with its light one (`darkPath`, "" when there's none). `own`: in `ownFolder`.
function entries(text, screenW, screenH, ownFolder) {
    const paths = text.split("\n").map(l => l.trim()).filter(l => l !== "");
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
        const v = variant.exec(base);
        const key = folder + "/" + (v ? v[1] : base);
        const g = group(key, v ? v[1] : base, folder);
        const isDark = v && /^d/i.test(v[2]);
        (isDark ? g.dark : g.light).push({ path: path, w: 0, h: 0 });
    }
    const result = [];
    for (const key of order) {
        const g = groups[key];
        const pick = list => list.length === 0 ? "" : list.some(s => s.w > 0) ? bestSize(list, screenW, screenH) : list[0].path;
        let light = pick(g.light);
        let dark = pick(g.dark);
        // Only a dark one ("night-dark.png" alone): it's just a picture.
        if (light === "") {
            light = dark;
            dark = "";
        }
        // Two names with -d / -l but no partner: a picture each, not a pair.
        const fileName = key.startsWith("plasma:") ? g.name : light.slice(light.lastIndexOf("/") + 1);
        result.push({
            filePath: light,
            fileName: fileName,
            darkPath: dark,
            own: ownFolder !== "" && light.startsWith(ownFolder + "/")
        });
    }
    return result;
}
