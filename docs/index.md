# Ghost Shell index

Every feature and rule in one place, each with where it lives. This is a map, not the full story:
the reasons and history are in [ROADMAP.md](../ROADMAP.md), verified API facts in
[NOTES.md](../NOTES.md), keybinds in [keybinds.md](keybinds.md). Shell paths are relative to
`quickshell/.config/quickshell/`, Hyprland paths to `hypr/.config/hypr/`.

## Contents

- [Rules](#rules): repo layout, conventions, engineering principles, decisions
- [Features](#features): island, menus, windows, launcher, lock, editors, widgets, services, apps
- [Commands](#commands): `ghost`, IPC targets, Settings pages
- [Modules](#modules)
- [Tests](#tests)

---

## Rules

### Repo layout and deployment (CLAUDE.md)

| Rule | Where |
|---|---|
| Every top-level folder except `modules/`, `system/`, `tests/`, `docs/` is a GNU Stow package mirroring `$HOME` | `ghost install`, `stow_packages` in `modules/lib.sh` |
| Never move or rename a Stow package while the desktop runs from it (links break; Hyprland once lost hyprland.lua) | |
| One module per part of the setup: `packages.txt` (pacman), `aur.txt` (paru), re-runnable `setup.sh`; new ones go in `all_modules` and `about` | `modules/`, `bin/.local/bin/ghost` |
| Opt-in modules (`llm`, `wave3`) only install where `~/.config/ghost/modules` lists them | `opt_in` in `ghost` |
| A machine picks its modules in `~/.config/ghost/modules` (not in git); without it, all | |
| `install.sh` only bootstraps `ghost install` | `install.sh` |
| `ghost update` refuses with uncommitted changes; never stash with the live config | `cmd_update` |
| Wallpaper and colors always go through `wallpaper.sh`; matugen hooks only deliver colors, app setup belongs in its module | `matugen/.config/matugen/wallpaper.sh` |
| No login screen: greetd logs in at boot and after a logout, and the session locks at once | `system/etc/greetd/config.toml`, `lock/Lock.qml`, `hypr/hyprland.lua` |
| Machine-local overrides, gitignored, loaded last | `hypr/local.lua`, `ghostty/local`, `fish/conf.d/local.fish` |
| `system/` mirrors `/`, copied with `sudo install` by the system module | `modules/system/setup.sh` |
| Browser is Zen (`zen-browser-bin`), never Firefox | |
| Commit and push after each phase or fix | |
| LF line endings everywhere | `.gitattributes` |
| Update ROADMAP.md when a phase finishes or a decision changes; add verified API facts to NOTES.md | |
| Generated output (matugen, `shell-settings.lua`) is gitignored; templates are committed | |

### Shell code conventions (ROADMAP "Look and architecture")

- Check every Quickshell / Hyprland API against the v0.3.x / 0.56-0.57 docs, not memory; record facts in NOTES.md.
- One folder per area; singletons for shared state, services and theme.
- No hardcoded colors or sizes: `theme/Colors.qml` and `theme/Theme.qml` (sizes through `px`, text through `text`, radii through `round`; `ThemeScale.js`).
- Color names use an `m3` prefix (`m3onSurface`): `onX` reads as a signal handler.
- Every surface sets `WlrLayershell.namespace: "qs-<name>"`; blur comes from `BackgroundEffect.blurRegion` per card, not layer rules.
- Panels open through `qs ipc call <target> <fn>` from Hyprland binds.
- Comment the non-obvious parts briefly (the user is learning Quickshell).
- Icons: Material Symbols Rounded, outline, weight 300. UI font Inter, mono MesloLGS Nerd Font.
- The bottom edge belongs to the dock; nothing else goes there.
- Every panel is a `widgets/Surface.qml` (glass: translucent, 1 px edge).
- Every visual option lives in an on-screen editor; Settings keeps only what isn't seen.
- Pure logic goes in a `.js` library with a test in `tests/`.

### Engineering principles (ENGINEERING_PRINCIPLES.md)

Chesterton's Fence · Least Astonishment · YAGNI · KISS · avoid Not Invented Here (repo, stdlib,
platform, installed deps first) · small batches · DRY with the Rule of Three · Single
Responsibility · Separation of Concerns · composition over inheritance · validate at the
boundaries · fail fast · least privilege · defense in depth · type safety · accessibility is
required · no premature optimization · no new dependency without asking (name, why, licence,
maintenance, alternative) · Definition of Done (a focused test for new logic, checks pass, docs
updated) · Boy Scout Rule within touched lines · end each change with a summary.

### Standing decisions (ROADMAP "Decisions made")

| Area | Decision |
|---|---|
| GPU | iGPU first, RTX second in `AQ_DRM_DEVICES`; no global NVIDIA env vars, `prime-run` per app (`env.lua`, udev rule `61-gpu-symlinks.rules`) |
| Boot | Plymouth's `bgrt` splash (the HP logo until Hyprland draws, `plymouth quit --retain-splash`); early KMS adds `amdgpu`; quiet kernel line; Hyprland output to the journal |
| Windows | Own tiling layout (`layout.lua`, `tiling.lua`); dialogs float; floating stays above tiled |
| Focus | Click to focus, raise on focus (`input.follow_mouse = 2`, `windows.lua`); apps can't steal focus, urgent shows an `AttentionCard` |
| Keybinds | Windows-style (Super launcher, Alt+Tab, Super+Left/Right snap, ...); app binds go through the shell with a fallback |
| Minimize | `special:minimized` workspace; restored from the overview's list (`overview/MinimizedList.qml`), the dock or Alt+Tab |
| Positions | Floating windows reopen where they were (`positions.lua`) |
| Island | Fixed-size window with an input mask; keyboard `OnDemand` while a menu is open, `None` closed |
| Switcher / overview | Keyboard `OnDemand`, not `Exclusive` (focus race) |
| Colors | matugen JSON outside the shell folder (`~/.local/state/quickshell/colors.json`) to avoid reloads |
| Icons | Colloid (`QS_ICON_THEME`, gsettings) |
| Night light | Manual by default; the shell drives hyprsunset |
| Idle | Quickshell `IdleMonitor`s (`idle/Idle.qml`); hypridle only locks before suspend |
| Crash recovery | `hypr/shell.sh` restarts qs after a crash; lock falls back to hyprlock |
| Bluetooth pairing | `yes \| bt-agent -c NoInputNoOutput` from `autostart.lua` |
| JavaScript runtime | bun for scripts; node/pnpm only for Vencord |
| Apps | Started in their own systemd scope (`hypr/run-app.sh`, `Apps.run`) so oomd kills the app, not the session |
| Wallpapers | Art (anime, illustrations), your folder only; system collections not offered |
| Third-party code | Pinned (`clone_at`); the user's own Ghost repos follow main |
| Not doing | Hibernation, fingerprint login, dictation, letting games take Super |

Recovery procedures (lock screen crash, a session that can't start) are in ROADMAP Phase 5.

---

## Features

### The island (bar)

| Feature | Files |
|---|---|
| Island: one shape with the time (or music) and alerts, floating or attached to the top edge (`islandAttached`); click for today, right-click for quick settings; morphs into every menu | `bar/Island.qml`, `IslandWindow.qml`, `IslandPill.qml`, `PillShape.qml`, `PillPath.js`, `IslandViews.js`, `IslandButton.qml`, `IslandFade.qml` |
| Island alerts: recording, timer, microphone, camera, screen sharing, low battery | `bar/IslandAlerts.qml`, `widgets/StatusGlyph.qml` |
| Pop-ups out of the island, one at a time: notifications, then attention requests | `bar/IslandWindow.qml`, `IslandViews.js`, `controlcenter/NotificationCard.qml`, `AttentionCard.qml` |
| Workspace dots (3-10 or only used), shown in the island for a moment after a switch; scroll over the island to step | `bar/Workspaces.qml`, `services/WorkspaceSlots.js` |
| Clock (day, seconds, 24-hour options) | `bar/Clock.qml` |
| Status icons in quick settings' top row: Wi-Fi, Bluetooth, VPN, airplane, updates, muted (each hideable), the battery | `controlcenter/StatusIcons.qml`, `BatteryPill.qml`, `widgets/WifiIcon.qml` |
| Media "live activity" (cover replaces the clock), small player on hover; which player (also for the media keys) | `bar/MediaActivity.qml`, `controlcenter/MediaCard.qml`, `services/Media.qml`, `MediaPlayers.js` |
| Shell reloads: "Reloaded" in the island's time place, a failed reload's error opened out of the island | `bar/IslandWindow.qml`, `bar/ReloadNotice.qml` |
| Recording dot, timer countdown in the island | `services/Recorder.qml`, `services/Countdown.qml` |

### Island menus

| Menu | Files |
|---|---|
| Quick settings: tiles (Wi-Fi, Bluetooth, Sound, Power mode, Phone), round toggles (mic, DND, night light, keep awake, game mode, airplane, dark mode, record, screenshot, wallpaper, timer), volume/brightness sliders, battery, status rows; edit mode (wiggle, drag, add, large/small tiles) | `controlcenter/QuickSettings.qml`, `QuickSlot.qml`, `QuickItems.js`, `Tile.qml`, `RoundToggle.qml`, `StatusRow.qml` |
| Wi-Fi page: scan, connect, forget, QR share, VPNs, hotspot, airplane mode, captive-portal sign-in | `controlcenter/WifiPage.qml`, `WifiShare.qml`, `WifiQr.js`, `services/NetworkExtras.qml` |
| Bluetooth page: scan, pair, connect, device batteries | `controlcenter/BluetoothPage.qml` |
| Sound page: output, microphone, per-app volume, equalizer preset | `controlcenter/SoundPage.qml` |
| System page: CPU, memory, GPUs, disk, busiest apps with End task | `controlcenter/SystemPage.qml`, `services/SystemStats.qml`, `system-stats.sh` |
| Phone page: ring, send files, clipboard, browse | `controlcenter/PhonePage.qml`, `services/Phone.qml`, `phone.sh` |
| Background apps (tray), from quick settings' bottom row | `controlcenter/Tray.qml` |
| Today: date, weather, agenda, note, timer, grouped notifications (the month and the to-do list are desktop widgets) | `controlcenter/TodayPanel.qml`, `TodayTools.qml`, `WeatherRow.qml`, `AgendaList.qml` |
| Media menu: cover colors, seek, shuffle/repeat | `controlcenter/MediaPanel.qml`, `MediaAccent.js` |
| Clipboard: history, images, search, pins, paste into the previous window | `controlcenter/ClipboardPanel.qml`, `services/Clipboard.qml`, `ClipboardEntries.js` |
| Emoji picker | `controlcenter/EmojiPanel.qml`, `services/EmojiData.js` |
| Power menu (lock, screen off, suspend, log out, restart, shut down) | `controlcenter/PowerPanel.qml` |
| Logging out, restarting, shutting down: the apps are asked to close first, a dimmed screen says what's happening, apps that don't close are listed (show, go ahead anyway, cancel) | `lock/SessionEnd.qml`, `services/Session.qml` (`ending`, `finish`, `cancel`) |
| The greeting after an unlock ("Good morning" after the login, "Welcome back" later) with what's waiting; the lock opens on screen first | `bar/WelcomeCard.qml`, `Greeting.js`, `Island.qml` (`welcomeShown`), `lock/Lock.qml` (`letIn`) |
| Arrow-key navigation and focus ring in every menu | `widgets/ArrowNavigation.qml/.js`, `FocusRing.qml` |

### Notifications

Server, pop-ups out of the island (`bar/IslandWindow.qml`), history, grouping, progress bars, actions, quick reply, DND
with schedule, per-app rules (Silent / Pop up / Always), quiet while fullscreen with a summary,
sounds. `services/Notifications.qml`, `NotificationRules.js`, `controlcenter/NotificationCard.qml`,
`NotificationGroups.js`, `NotificationProgress.js`, `NotificationTime.js`, `services/Sounds.qml`.

Shell alerts: battery 20/10 % (`BatteryAlerts`), low disk (`DiskAlerts`), out of memory
(`OomAlerts`), attention requests (`controlcenter/AttentionCard.qml`).

### OSD

Volume, mute, mic, brightness, caps lock, keyboard layout, power mode, new output, VPN, muted
while recording; each can be turned off. `osd/Osd.qml`, `services/Keyboard.qml`.

### Windows

| Feature | Files |
|---|---|
| Tiling layout (by count, or a picked arrangement), Super+drag borders and swap | `layout.lua`, `tiling.lua`, `drag.lua`, `services/Snap.qml`, `SnapLayout.js` |
| Window menu (Alt+Space / Super+Z): actions, move to workspace, snap layouts | `snap/WindowMenu.qml`, `WindowActions.qml`, `SnapLayouts.qml` |
| Snap Assist | `snap/SnapAssist.qml`, `services/WindowGrid.js` |
| Alt+Tab switcher with live previews | `switcher/Switcher.qml`, `widgets/WindowPreview.qml` |
| Overview (Super+Tab, swipe, hot corner), drag windows between workspaces, the minimized windows | `overview/Overview.qml`, `HotCorner.qml`, `MinimizedList.qml` |
| Minimize, restore, attention | `services/Windows.qml`, `windows.lua` |
| Window tabs (Hyprland groups) | `binds.lua`, `Windows.toggleTabs` |
| Reopen floating apps where they were | `positions.lua` |
| Scratchpad terminal (Super+\`) | `binds.lua`, `windows.lua` |
| Magnifier (Super+Plus/Minus) | `binds.lua` |

### Dock

Pinned and running apps, window dots, previews on hover, notification badges, right-click menu
(new window, shortcuts, pin, move, close), drag to reorder or unpin, shows at the edge / always /
off. `dock/Dock.qml`, `DockBar.qml`, `DockItem.qml`, `DockApps.js`, `services/DockState.qml`.

### Launcher

Apps (fuzzy, one-typo), app actions, open windows, `/` files (fd), `>` commands, calculator and
unit/currency conversion (qalc), colors, `?` keybinds, web search, Settings pages, favorites and
hidden apps, your own commands, the customize tiles. Grows into Settings and Wallpapers at three
sizes. `launcher/Launcher.qml`, `Fuzzy.js`, `Calc.js`, `CalcRow.qml`, `FileSearch.qml`,
`LauncherRow.qml`, `services/LauncherState.qml`, `services/Apps.qml`.

### Settings (in the launcher)

`settings/SettingsView.qml`, page list and search in `SettingsPages.js`. Pages:

| Section | Pages (id) |
|---|---|
| Personalize | Appearance (`appearance`), Display (`display`), Lock screen (`lock`) |
| System | Sound (`sound`), Windows (`windows`), Notifications (`notifications`), Power (`power`), Keyboard and mouse (`input`), Account (`account`: change your password), Snapshots (`snapshots`) |
| Apps | Default apps (`apps`), Screen time (`screentime`), Keybinds (`keybinds`), Screenshots and recordings (`capture`), Weather and clock (`clock`) |

Settings are saved in `~/.local/state/quickshell/settings.json` (`services/Settings.qml`);
Hyprland options go to the generated `shell-settings.lua` (`settings/HyprlandSettings.qml`,
`HyprlandConfig.js`).

### On-screen editors (Super+U)

Each shows the screen as a card with a tabbed sheet, presets ("Looks"), your own saved looks,
Cancel / Done, full keyboard control. `customize/Customize.qml`, `EditorChrome.qml`,
`LooksTile.qml`, `Presets.js`, `SavedLooks.js`, `SheetTiles.qml`, `services/Editing.qml`.

| Editor | Tabs | File |
|---|---|---|
| Desktop | Themes (save, rename, export/import), Looks + widget layouts, Wallpaper, Colors, Widgets (grid), Style, Size and text | `customize/DesktopEditor.qml`, `Themes.js`, `LooksFile.js` |
| Dock and island | Looks, island (style, dots, clock, status icons in quick settings), dock (when, icon size) | `customize/DockIslandEditor.qml` |
| Windows | Looks, Borders, Space, Motion (with Play samples) on example windows | `customize/WindowsEditor.qml`, `ExampleWindow.qml` |
| Quick settings | Edit mode on the panel itself | `controlcenter/QuickSettings.qml` |

### Desktop widgets

Clock, weather, media (the cover as its card), calendar, battery, to-do, timer, notifications,
the hourly weather (`ForecastWidget`, `Weather.hours`), and two large ones: the month
(`MonthWidget`) and the to-do list. Both to-do widgets are `TasksWidget` (medium and large), where
tasks are added (the layer takes the keyboard while its field is typed in). Small, medium and large (`DesktopWidgets.js` `kinds`, `box`;
`Theme.desktop.box`); glass cards on a `Bottom` layer, dragged by a handle shown only in the
desktop editor, snapping or a grid, keyboard nudges, zoom with the shell's size. The lock screen
draws the same stage, locked. `desktop/DesktopWidgets.qml/.js`, `WidgetStage.qml`, `*Widget.qml`,
`WidgetSurface.qml`, `WidgetRegion.qml`.

### Wallpaper and colors

| Feature | Files |
|---|---|
| Wallpaper layer (stills and live videos, paused when hidden) | `wallpaper/WallpaperLayer.qml` |
| Picker strip under the island | `wallpaper/WallpaperPicker.qml`, `WallpaperPanel.qml` |
| Wallpapers browser (wallhaven SFW search, styles, colors, tags, Yours with delete) | `wallpaper/WallpaperBrowser.qml`, `services/Wallhaven.js` |
| Folder scan, dark/light pairs, slideshow | `services/Wallpaper.qml`, `Wallpapers.js`, `wallpapers.sh` |
| Light / dark / at sunset, style, contrast, accent, smooth recolor | `services/ColorScheme.qml/.js`, `theme/Colors.qml` |
| matugen for the shell, Hyprland, Ghostty, GTK, Yazi, Zed, Zen, Spotify, Discord, Steam, MangoHud | `matugen/.config/matugen/config.toml`, `templates/`, `hooks/` |

### Lock and idle

| Feature | Files |
|---|---|
| Lock screen: the desktop locked (its wallpaper and widgets, glass behind them), PAM, grace period (`LockMotion.js`), message line | `lock/Lock.qml`, `LockContent.qml`, `LockMotion.js`, `desktop/WidgetStage.qml` |
| The island opens into the password field (shake on error, caps lock and layout hints) | `lock/LockIsland.qml` |
| Boot and logout log in and lock at once (greetd, `GHOST_AUTOLOGIN`, a per-instance lock mark); no login screen | `system/etc/greetd/config.toml`, `hypr/hyprland.lua`, `lock/Lock.qml` |
| Idle: dim, lock, screen off, suspend (battery / plugged in) | `idle/Idle.qml`, `hypridle.conf` |
| Polkit agent | `polkit/PolkitPrompt.qml` |

### Capture

Screenshot tool (region / window / screen on a frozen frame), OCR text, QR codes, color picker,
recording (gpu-screen-recorder), draw on it (satty), folders and quality settings.
`screenshot/Screenshot.qml`, `CaptureChoice.qml`, `capture.sh`, `services/Recorder.qml`,
`CaptureFolders.js`.

### Services (no UI of their own, or small)

| Service | What |
|---|---|
| `Audio`, `Equalizer` | PipeWire volume, mic, recording apps; 5-band filter-chain EQ per output |
| `Brightness`, `NightLight`, `KeepAwake`, `GameMode` | Backlight, hyprsunset, idle inhibitor, performance mode |
| `NetworkStatus`, `NetworkExtras`, `BluetoothStatus` | Wi-Fi, VPN, hotspot, airplane, Bluetooth |
| `Battery`, `BatteryAlerts`, `DiskAlerts`, `OomAlerts` | Power and resource alerts |
| `Privacy` | Camera and screen sharing indicators |
| `Updates` | checkupdates + paru count, Update button |
| `Weather`, `Agenda` | open-meteo; vdirsyncer + khal calendar |
| `Planner`, `Countdown` | To-do (the desktop's to-do widgets), note, timer |
| `ScreenTime` | Per-app time, 30 days |
| `Touchpad`, `Keyboard` | Touchpad off with a mouse; layout and caps lock |
| `Media`, `Sounds`, `Phone`, `Session`, `Windows`, `HyprlandRuntime`, `LatestProcess` | Players, sound events, KDE Connect, session actions, window state, runtime Hyprland rules, process helper |

### Other

Welcome tour (`welcome/Welcome.qml`), web apps (`ghost webapp`, Chromium `--app`), snapshots
(snapper, Settings page), Nautilus "Send to phone" script (`nautilus/`), Proton apps, Wave:3
voice chain (`modules/wave3/README.md`), local LLM (`llm` module).

---

## Commands

### `ghost`

`install [module...] [--theme X]` · `update` · `theme <wallpaper|#rrggbb>` ·
`webapp add|remove|list` · `calendar add|remove|list|sync` · `looks export|import` ·
`wallpapers get [words] [--count N] [--general] [--style S]` / `fetch <id>` · `doctor` ·
`modules` · `keybinds`

### IPC (`qs ipc call <target> <fn>`)

| Target | Functions |
|---|---|
| `island` | `toggle <settings\|today\|media\|clipboard\|emoji\|power\|tray>`, `close`, `editQuickSettings` |
| `launcher` | `toggle` |
| `apps` | `open <kind>`, `terminal <command>` |
| `settings` | `open`, `page <id>` |
| `wallpapers` | `browse` |
| `wallpaper` | `set <path>`, `get`, `picker` |
| `customize` | `menu`, `desktop`, `dock`, `windows`, `quick`, `close`, `importLooks <path>` |
| `lock` | `lock`, `isLocked`, `preview` |
| `switcher` | `next`, `previous` |
| `overview` | `toggle`, `open`, `close` |
| `snap` | `active <layout>`, `down`, `picker` |
| `screenshot` | `region`, `screen`, `record` |
| `recorder` | `stop`, `recording` |
| `brightness` | `refresh` |
| `media` | `playPause`, `next`, `previous` (the media keys) |
| `updates` | `check`, `summary` |
| `welcome` | `show` |

---

## Modules

| Module | What |
|---|---|
| core | Hyprland, the shell, fonts and themes, the colors |
| system | GPU rule, boot options, logging in at boot (greetd) and services (sudo) |
| snapshots | Btrfs snapshots: system at every update, home hourly (sudo) |
| apps | Terminal, editor, files, pictures, video, music, browser, web apps |
| dev | Languages, package managers, Docker |
| gaming | Steam, Proton, Lutris, Heroic, MangoHud; Millennium's theme |
| discord | Vesktop with Vencord and the Ghost plugin |
| spotify | Spotify with Spicetify and the Ghost theme |
| zen | Zen in the wallpaper's colors |
| haunt | The Haunt Git client |
| capture | Recording, color picker, OCR and QR |
| phone | KDE Connect (opens its ufw ports) |
| proton | Proton Mail, Pass, VPN |
| calendar | Calendar events from a share link |
| llm (opt-in) | Ollama, OpenCode, Aider on the NVIDIA GPU |
| wave3 (opt-in) | Elgato Wave:3 with openxlr and a voice chain |

---

## Tests

- QML: `QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests` (one
  `tests/tst_<name>.qml` per `.js` library).
- Tiling: `lua tests/tiling_test.lua`.
- Live checks on the laptop: see NOTES.md "Testing on the laptop".
