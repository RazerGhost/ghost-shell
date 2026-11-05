// The Settings pages (SettingsView.qml, the launcher's Settings page) and the search that finds
// them, also from the launcher's own search. Plain JavaScript, so it can be tested on its own
// (tests/tst_settingspages.qml).
.pragma library

// The pages in their sidebar sections (user's choice: grouped, with a search field; reorganised
// 2026-11-05: what belongs together on one page, each section's pages of one kind). The
// search matches a page's title and these words, so it finds the page for any setting on it.
const pages = [
    { id: "appearance", section: "Personalize", icon: "palette", title: "Appearance",
      words: "customize desktop editor windows editor dock island quick settings tiles buttons edit wallpaper wallpapers find download wallhaven anime art slideshow folder rotate change every colors theme light dark mode sunset night accent style contrast vibrant monochrome matugen fonts font typeface icon theme colloid folder color glass blur style frost acrylic transparent see-through border corners rounding desktop widgets clock weather media glow turning spinning animation opening closing slide workspaces floating pinned" },
    { id: "display", section: "Personalize", icon: "brightness_6", title: "Display",
      words: "night light warm blue light schedule screen monitor resolution refresh rate hz scale size shell text bigger smaller zoom launcher width rows results rotation rotate vrr adaptive sync" },
    { id: "clock", section: "Personalize", icon: "partly_cloudy_day", title: "Date, time and weather",
      words: "fahrenheit celsius temperature unit weather town location 24-hour 12-hour time clock date" },
    { id: "sound", section: "System", icon: "volume_up", title: "Sound",
      words: "equalizer audio bass treble mids voice speakers headphones preset eq sound events chime notification charger usb plug volume screenshot shutter battery" },
    { id: "windows", section: "System", icon: "select_window", title: "Windows",
      words: "customize windows border corners rounding gaps animation speed opening closing slide glow turning wobbly dock island workspace dots status icons clock day seconds music dock taskbar pins hide always gaps tiling hot corner overview reopen floating position wobble wobbly jelly" },
    { id: "notifications", section: "System", icon: "notifications", title: "Notifications",
      words: "do not disturb dnd quiet fullscreen game film missed schedule apps silent mute always priority pop-up popup time seconds osd volume brightness position top bottom" },
    { id: "power", section: "System", icon: "lock_clock", title: "Lock and power",
      words: "idle dim lock screen off suspend sleep battery plugged low power saver warning message if found grace period unlock touch password password change passwd sudo user login unlock lock screen" },
    { id: "input", section: "System", icon: "touchpad_mouse", title: "Keyboard and mouse",
      words: "keyboard layout language touchpad natural scrolling tap click pointer speed mouse off cursor theme size hide typing still" },
    { id: "snapshots", section: "System", icon: "history", title: "Snapshots",
      words: "backup restore btrfs snapper undo files home" },
    { id: "keybinds", section: "System", icon: "keyboard", title: "Keybinds",
      words: "shortcuts keys welcome tour help" },
    { id: "screentime", section: "System", icon: "hourglass", title: "Screen time",
      words: "usage time apps today week hours digital wellbeing" },
    { id: "apps", section: "Apps", icon: "apps", title: "Apps and launcher",
      words: "terminal browser file manager editor image viewer video audio player launcher hidden hide apps favorites commands your own" },
    { id: "terminal", section: "Apps", icon: "terminal", title: "Terminal",
      words: "prompt starship pills style minimal two lines cursor trail shader ghostty notify notification long command finished greeting fastfetch zsh" },
    { id: "capture", section: "Apps", icon: "screenshot_monitor", title: "Screenshots and recordings",
      words: "screenshot capture record recording video folder quality fps frame rate microphone" }
];

// Pages merged into others (2026-11-05) keep their ids, so anything that opens them still lands
// on the right page: `qs ipc call settings page lock`, links in the shell.
const aliases = { lock: "power", account: "power" };

// The page's own id for an id or an alias.
function resolve(id) {
    return aliases[id] ?? id;
}

function find(id) {
    const own = resolve(id);
    return pages.find(p => p.id === own) ?? null;
}

// The pages whose title or words hold the text (all of them without any), in their order; the
// ones whose title holds it first.
function matching(text) {
    const q = String(text ?? "").trim().toLowerCase();
    if (q === "")
        return pages.slice();
    const inTitle = pages.filter(p => p.title.toLowerCase().includes(q));
    return inTitle.concat(pages.filter(p => !inTitle.includes(p) && p.words.toLowerCase().includes(q)));
}
