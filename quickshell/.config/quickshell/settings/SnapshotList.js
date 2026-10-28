// snapper's snapshot lists for the settings app's Snapshots page. Plain JavaScript, so it can be
// tested on its own (tests/tst_snapshotlist.qml).
.pragma library

// `answer`: `snapper -c <config> --jsonout list` ({ "<config>": [snapshots] }). Returns up to
// `max` rows, newest first, as { number, date, label }: an update counts once (its "before"
// snapshot; the "after" one is skipped), snapshot 0 ("current") is left out.
function rows(answer, config, max) {
    const all = (answer && answer[config]) || [];
    const result = [];
    for (let i = all.length - 1; i >= 0 && result.length < max; i--) {
        const s = all[i];
        if (s.number === 0 || s.type === "post")
            continue;
        result.push({ number: s.number, date: s.date, label: label(s) });
    }
    return result;
}

// "Update: linux-cachyos mesa", "Hourly", "By hand", or the description as it is.
function label(s) {
    const d = (s.description || "").trim();
    const pacman = d.match(/^pacman\s+(-\S+)\s*(.*)$/);
    if (pacman) {
        // Package files (pacman -U) by their package name, not their path.
        const what = pacman[2].split(/\s+/).filter(w => w && !w.startsWith("-"))
            .map(w => w.split("/").pop().replace(/-(x86_64|any)\.pkg\.tar\.\w+$/, ""))
            .slice(0, 4).join(" ");
        // -Syu, or written out: --sync -y -u / --sysupgrade.
        const update = /^-[A-Za-z]*u/.test(pacman[1]) || /(^|\s)(-u|--sysupgrade)(\s|$)/.test(pacman[2]);
        const kind = update ? "System update"
                   : what === "" ? "Packages changed"
                   : /^-R/.test(pacman[1]) ? "Removed: " + what
                   : "Installed: " + what;
        return kind;
    }
    if (s.cleanup === "timeline" || d === "timeline")
        return "Hourly";
    return d || "Snapshot";
}
