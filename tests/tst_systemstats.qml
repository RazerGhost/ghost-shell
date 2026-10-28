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
}
