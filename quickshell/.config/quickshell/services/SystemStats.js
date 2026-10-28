// Reading services/system-stats.sh's output for services/SystemStats.qml. Plain JavaScript, so it
// can be tested on its own (tests/tst_systemstats.qml).
.pragma library

// One reading as numbers: { cpu: { total, idle } (counters, see cpuLoad), memory: { used, total }
// (bytes), cpuTemp (°C), disk: { used, total } (bytes), gpus: [{ name, load (0-1), memory: {
// used, total }, temp, asleep }] }. Missing sensors are left out (cpuTemp null, no gpu entry).
function parse(text) {
    const result = { cpu: null, memory: null, cpuTemp: null, disk: null, gpus: [] };
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

// "7.8 of 15.6 GB" (decimal units, like the file manager).
function amount(used, total) {
    const gb = bytes => (bytes / 1e9).toFixed(bytes >= 100e9 ? 0 : 1);
    return gb(used) + " of " + gb(total) + " GB";
}
