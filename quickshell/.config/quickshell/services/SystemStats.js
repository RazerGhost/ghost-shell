// Reading services/system-stats.sh's output for services/SystemStats.qml. Plain JavaScript, so it
// can be tested on its own (tests/tst_systemstats.qml).
.pragma library

// One reading as numbers: { cpu: { total, idle } (counters, see cpuLoad), memory: { used, total }
// (bytes), cpuTemp (°C), disk: { used, total } (bytes), gpus: [{ name, load (0-1), memory: {
// used, total }, temp, asleep }] }. Missing sensors are left out (cpuTemp null, no gpu entry).
function parse(text) {
    const result = { cpu: null, memory: null, cpuTemp: null, disk: null, gpus: [], procs: [] };
    let memTotal = 0, memAvailable = 0;
    for (const line of text.split("\n")) {
        const [key, ...rest] = line.trim().split(/\s+/);
        const n = rest.map(Number);
        if (key === "cpu") {
            // user nice system idle iowait irq softirq steal: idle time is idle + iowait.
            result.cpu = { total: n.slice(0, 8).reduce((a, b) => a + b, 0), idle: n[3] + n[4] };
        } else if (key === "MemTotal:") {
            memTotal = n[0] * 1024;
        } else if (key === "MemAvailable:") {
            memAvailable = n[0] * 1024;
        } else if (key === "cputemp") {
            result.cpuTemp = n[0] / 1000;
        } else if (key === "disk") {
            result.disk = { total: n[0], used: n[1] };
        } else if (key === "proc" && rest.length >= 5) {
            // The name is everything after the numbers (it can hold spaces).
            result.procs.push({ pid: n[0], ppid: n[1], ticks: n[2], memory: n[3], name: rest.slice(4).join(" ") });
        } else if (key === "amdgpu" || key === "nvidia") {
            const name = key === "amdgpu" ? "Radeon (built-in)" : "NVIDIA";
            result.gpus.push(rest[0] === "asleep"
                ? { name: name, asleep: true }
                : { name: name, asleep: false, load: n[0] / 100, memory: { used: n[1], total: n[2] }, temp: n[3] / 1000 });
        }
    }
    if (memTotal > 0)
        result.memory = { total: memTotal, used: memTotal - memAvailable };
    return result;
}

// CPU load (0-1) between two readings' counters; null without an earlier one.
function cpuLoad(previous, current) {
    if (!previous || !current || current.total <= previous.total)
        return null;
    const busy = (current.total - previous.total) - (current.idle - previous.idle);
    return busy / (current.total - previous.total);
}

// Processes the desktop needs: their rows get no "End task" (ending them would end the session,
// the shell or the sound). Names as the kernel shortens them (15 characters).
const essential = ["systemd", "(sd-pam)", "start-hyprland", "Hyprland", "Xwayland", "qs", "shell.sh",
                   "pipewire", "pipewire-pulse", "wireplumber", "dbus-broker", "dbus-broker-lau",
                   "xdg-desktop-por", "xdg-permission-", "xdg-document-po", "gnome-keyring-d"];

// Whether a process is the shell (qs) or one it started (its nmcli, rfkill and udevadm
// watchers): those are one essential group, so End task can't take the shell down with them.
function fromShell(p, byPid) {
    for (let at = p, depth = 0; at && depth < 64; at = byPid[at.ppid], depth++) {
        if (at.name === "qs")
            return true;
    }
    return false;
}

// The busiest apps, like a task manager: a window's app with every process under it (Electron
// and browser helpers, games under Steam), the rest by process name. `windows` maps a window's
// process id to its app { name, icon }; `previous` maps process ids to their CPU ticks at the
// last reading and `cpuTicks` is the whole processor's ticks since then (all cores), so `cpu` is
// a share of the whole machine. Sorted by CPU (whole percents, so idle apps don't swap places),
// then memory.
function apps(procs, previous, cpuTicks, windows, limit) {
    const byPid = {};
    for (const p of procs)
        byPid[p.pid] = p;
    const groups = {};
    for (const p of procs) {
        const shell = fromShell(p, byPid);
        let owner = p;
        for (let depth = 0; owner && !windows[owner.pid] && depth < 64; depth++)
            owner = byPid[owner.ppid];
        const app = shell || !owner ? null : windows[owner.pid];
        const key = shell ? "shell" : app ? "app:" + app.name : "proc:" + p.name;
        const group = groups[key] ?? (groups[key] = {
            name: shell ? "Ghost Shell" : app ? app.name : p.name, icon: app ? app.icon : "",
            essential: shell || (!app && essential.includes(p.name)), cpu: 0, memory: 0, pids: []
        });
        if (previous[p.pid] !== undefined && cpuTicks > 0)
            group.cpu += Math.max(0, p.ticks - previous[p.pid]) / cpuTicks;
        group.memory += p.memory;
        group.pids.push(p.pid);
    }
    return Object.values(groups)
        .sort((a, b) => Math.round(b.cpu * 100) - Math.round(a.cpu * 100) || b.memory - a.memory)
        .slice(0, limit);
}

// "340 MB", "1.2 GB" (decimal units, like amount()).
function size(bytes) {
    return bytes >= 1e9 ? (bytes / 1e9).toFixed(1) + " GB" : Math.round(bytes / 1e6) + " MB";
}

// "7.8 of 15.6 GB" (decimal units, like the file manager).
function amount(used, total) {
    const gb = bytes => (bytes / 1e9).toFixed(bytes >= 100e9 ? 0 : 1);
    return gb(used) + " of " + gb(total) + " GB";
}
