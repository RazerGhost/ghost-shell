// The Settings pages (SettingsView.qml, the launcher's Settings page) and the search that finds
// them, also from the launcher's own search. Plain JavaScript, so it can be tested on its own
// (tests/tst_settingspages.qml).
.pragma library

// The pages in their sidebar sections (user's choice: grouped, with a search field). The
// search matches a page's title and these words, so it finds the page for any setting on it.
const pages = [
    { id: "appearance", section: "Personalize", icon: "palette", title: "Appearance",
      words: "customize desktop editor wallpaper wallpapers find download wallhaven anime art slideshow folder rotate change every colors theme light dark mode sunset night accent style contrast vibrant monochrome matugen fonts font typeface icon theme colloid folder color status icons island wifi bluetooth battery glass blur style frost acrylic transparent see-through border corners rounding desktop widgets clock weather media glow turning spinning animation opening closing slide workspaces floating pinned" },
    { id: "display", section: "Personalize", icon: "brightness_6", title: "Display",
      words: "night light warm blue light schedule screen monitor resolution refresh rate hz scale rotation rotate vrr adaptive sync" },
    { id: "lock", section: "Personalize", icon: "lock", title: "Lock screen",
      words: "weather battery calendar event login greeter picture blur darken clock style analog stacked thin font layout date name power buttons media music notifications count privacy widgets to-do looks presets save" },
    { id: "sound", section: "System", icon: "volume_up", title: "Sound",
      words: "equalizer audio bass treble mids voice speakers headphones preset eq sound events chime notification charger usb plug volume screenshot shutter battery" },
    { id: "windows", section: "System", icon: "select_window", title: "Windows",
      words: "customize windows border corners rounding gaps animation speed opening closing slide glow turning wobbly dock island workspace dots status icons clock day seconds music dock taskbar pins hide always gaps tiling hot corner overview reopen floating position wobble wobbly jelly" },
    { id: "notifications", section: "System", icon: "notifications", title: "Notifications",
      words: "do not disturb dnd quiet fullscreen game film missed schedule apps silent mute always priority pop-up popup time seconds osd volume brightness position top bottom" },
    { id: "power", section: "System", icon: "battery_charging_full", title: "Power",
      words: "idle dim lock screen off suspend sleep battery plugged low power saver warning" },
    { id: "input", section: "System", icon: "touchpad_mouse", title: "Keyboard and mouse",
      words: "keyboard layout language touchpad natural scrolling tap click pointer speed mouse off cursor theme size" },
    { id: "snapshots", section: "System", icon: "history", title: "Snapshots",
      words: "backup restore btrfs snapper undo files home" },
    { id: "apps", section: "Apps", icon: "apps", title: "Default apps",
      words: "terminal browser file manager editor image viewer video audio player" },
    { id: "screentime", section: "Apps", icon: "hourglass", title: "Screen time",
      words: "usage time apps today week hours digital wellbeing" },
    { id: "keybinds", section: "Apps", icon: "keyboard", title: "Keybinds",
      words: "shortcuts keys welcome tour help" },
    { id: "capture", section: "Apps", icon: "screenshot_monitor", title: "Screenshots and recordings",
      words: "screenshot capture record recording video folder quality fps frame rate microphone" },
    { id: "clock", section: "Apps", icon: "partly_cloudy_day", title: "Weather and clock",
      words: "fahrenheit celsius temperature unit weather town location 24-hour 12-hour time clock" }
];

function find(id) {
    return pages.find(p => p.id === id) ?? null;
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
