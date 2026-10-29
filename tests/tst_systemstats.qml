import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/SystemStats.js" as SystemStats

TestCase {
    name: "SystemStats"

    readonly property string reading: [
        "cpu  100 0 50 800 50 0 0 0 0 0",
        "MemTotal: 16000000",
        "MemAvailable: 6000000",
        "cputemp 70250",
        "disk 500000000000 25000000000",
        "nvidia asleep",
        "amdgpu 10 442564608 536870912 48000"
    ].join("\n")

    function test_parse() {
        const r = SystemStats.parse(reading);
        compare(r.cpu, { total: 1000, idle: 850 });
        compare(r.memory, { total: 16384000000, used: 10240000000 });
        compare(r.cpuTemp, 70.25);
        compare(r.disk, { total: 500000000000, used: 25000000000 });
        compare(r.gpus.length, 2);
        compare(r.gpus[0], { name: "NVIDIA", asleep: true });
        compare(r.gpus[1].load, 0.1);
        compare(r.gpus[1].temp, 48);
    }

    function test_missingSensors() {
        const r = SystemStats.parse("cpu  1 0 0 1 0 0 0 0 0 0\n");
        compare(r.cpuTemp, null);
        compare(r.memory, null);
        compare(r.gpus, []);
    }

    function test_cpuLoad() {
        compare(SystemStats.cpuLoad(null, { total: 10, idle: 5 }), null);
        // 200 more ticks, 50 of them idle: 75 % busy.
        compare(SystemStats.cpuLoad({ total: 1000, idle: 850 }, { total: 1200, idle: 900 }), 0.75);
        compare(SystemStats.cpuLoad({ total: 1000, idle: 850 }, { total: 1000, idle: 850 }), null);
    }

    function test_amount() {
        compare(SystemStats.amount(7.8e9, 15.6e9), "7.8 of 15.6 GB");
        compare(SystemStats.amount(23.7e9, 509.5e9), "23.7 of 510 GB");
    }

    function test_procs() {
        const r = SystemStats.parse("proc 10 1 500 2000000 Web Content\nproc 11 10 100 1000000 electron\n");
        compare(r.procs.length, 2);
        compare(r.procs[0], { pid: 10, ppid: 1, ticks: 500, memory: 2000000, name: "Web Content" });
    }

    function test_apps() {
        const procs = [
            { pid: 1, ppid: 0, ticks: 0, memory: 10e6, name: "systemd" },
            { pid: 100, ppid: 1, ticks: 1000, memory: 300e6, name: "electron" },   // Vesktop's window
            { pid: 101, ppid: 100, ticks: 1500, memory: 500e6, name: "electron" }, // its helper
            { pid: 200, ppid: 1, ticks: 50, memory: 900e6, name: "spotify" },
            { pid: 300, ppid: 1, ticks: 10, memory: 20e6, name: "new-thing" }      // no earlier reading
        ];
        const previous = { 1: 0, 100: 900, 101: 1300, 200: 50 };
        const windows = { 100: { name: "Vesktop", icon: "vesktop" } };
        const apps = SystemStats.apps(procs, previous, 1000, windows, 10);
        // 300 of 1000 ticks: 30 % for Vesktop's two processes, first despite less memory.
        compare(apps[0].name, "Vesktop");
        compare(apps[0].icon, "vesktop");
        compare(apps[0].pids, [100, 101]);
        compare(apps[0].memory, 800e6);
        fuzzyCompare(apps[0].cpu, 0.3, 1e-9);
        // The idle ones by memory.
        compare(apps.slice(1).map(a => a.name), ["spotify", "new-thing", "systemd"]);
        verify(apps[3].essential);
        verify(!apps[1].essential);
        compare(SystemStats.apps(procs, previous, 1000, windows, 2).length, 2);
    }

    function test_size() {
        compare(SystemStats.size(340e6), "340 MB");
        compare(SystemStats.size(1.25e9), "1.3 GB");
    }
}
