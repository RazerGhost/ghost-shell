# Roadmap: Quickshell desktop shell + Hyprland

Handover document for continuing this work. Phase 1 was built in a Windows session that couldn't
run anything; work now continues on the laptop, where changes can be run and tested directly.

## The task

Build a full desktop shell in Quickshell on top of a modular Hyprland Lua config, themed from the
wallpaper with matugen. Work in phases; commit and push after each phase, then give the user a short
test checklist and wait for their results before starting the next one. Ask before building anything
ambiguous or with real trade-offs.

**Laptop:** HP Omen 16, CachyOS, fish shell. Ryzen 7 7840HS (AMD 780M iGPU) + RTX 4070 Max-Q
(nvidia-open, `nvidia-prime`). Panel 1920x1080 @ 165 Hz. Hyprland 0.56 (Lua config), Quickshell 0.3.2,
Qt 6.12. Quickshell owns the bar, notifications, launcher, OSD and lock screen; there is no other bar,
notification daemon or launcher.

**API accuracy:** Quickshell and Hyprland's Lua API change between versions. Check every type,
property and function against quickshell.org/docs (v0.3.x) and wiki.hypr.land (0.56) before using it,
not memory or old dotfiles. Facts already checked are listed under "Verified API notes" below. Say in
the phase summary what couldn't be verified.

**After each phase, report:** what was built; commands to run (fish-compatible); a test checklist;
anything unverified. Update `packages.txt` / `aur.txt` for every new package, and `install.sh` for every
new setup step.

## Look and architecture

- **Bar = the island** (user's choice, replacing the floating pills): a small shape attached to the
  top edge, with concave curves into the screen edge, showing workspaces, the time (no date) and tiny
  status icons. Clicking the time or the status icons morphs it (Android-style) into a menu: "today"
  (date, calendar, media; notifications in Phase 3) or quick settings (tiles, sliders, battery, tray;
  Wi-Fi and Bluetooth tiles slide in their own page). Categorized pages, not one crowded panel.
  Aesthetic reference: saneAspect's Hyprland/Quickshell builds (clean, rounded, Material-ish, subtle
  animations).
- **Colors:** matugen from the wallpaper is the single source of truth for Quickshell, Hyprland borders,
  Ghostty, GTK and Yazi. Dark mode by default.
- **Icons:** Material Symbols (`Material Symbols Rounded`). **UI font:** Inter. **Mono:** MesloLGS Nerd Font.
- **QML:** `shell.qml` entry, one folder per area (`bar/`, `launcher/`, `notifications/`, `osd/`,
  `controlcenter/`, `services/`, `theme/`, `widgets/` for shared components). Singletons for shared
  state, services and theme. No hardcoded colors or sizes in components: use `Colors` and `Theme`. Comment the non-obvious parts
  briefly; the user is learning Quickshell through this.
- **Panels** are toggled from Hyprland binds through Quickshell IPC (`qs ipc call <target> <fn>`).
- **Layer rules:** every Quickshell surface sets `WlrLayershell.namespace: "qs-<name>"`; add blur and
  animation rules for them in `hypr/.config/hypr/rules.lua`.

## Phases

### Phase 1: Foundation (done, verified on the laptop)
- Hyprland split into `monitors`, `env`, `autostart`, `look`, `input`, `binds`, `rules`, plus the
  matugen-generated `colors.lua` (loaded last, through `pcall`).
- GPU offload: udev rule `system/etc/udev/rules.d/61-gpu-symlinks.rules` creates `/dev/dri/amd-igpu`
  and `/dev/dri/nvidia-dgpu`. `env.lua` sets `AQ_DRM_DEVICES=/dev/dri/amd-igpu:/dev/dri/nvidia-dgpu`;
  heavy apps use `prime-run`.
- matugen config and templates (`matugen/.config/matugen/`) for Quickshell (JSON), Hyprland
  (`colors.lua`), Ghostty, GTK3/4 (`gtk.css`) and Yazi (`theme.toml`).
- Quickshell: `theme/Theme.qml` (tokens), `theme/Colors.qml` (matugen JSON, live reload),
  `bar/Bar.qml` + `Pill.qml` + `Workspaces.qml` + `Clock.qml` (center pill only).

**Added alongside Phase 1 at the user's request:**
- `install.sh`: packages, GPU rule check, early KMS, Plymouth off, greetd, GTK dark mode, stow for
  every package, a matugen run. Safe to re-run.
- Nautilus (Super+N), Yazi in Ghostty (Super+Y), adw-gtk3 theme.
- greetd + tuigreet as the login screen (a stopgap until Phase 5).
- Ghostty window padding. Zen browser (`zen-browser-bin`) instead of Firefox.

### Phase 2: Island + control center + launcher + OSD (done, verified on the laptop 2026-10-28,
  except the media card: untested until Spotify is installed)
- Island (`bar/Island.qml`, `IslandShape.qml`): closed = workspaces, clock, `StatusIcons`; the
  clock sits in the exact middle (both sides get the same width). Workspace dots always show at
  least 5 (`WorkspaceSlots.js`, tested in `tests/tst_workspaces.qml`): click one to go there, even
  if it's empty; scroll over them to step through. Status icons: Wi-Fi as three arcs with the
  unlit ones dimmed (`widgets/WifiIcon.qml`), battery as an Android 16-style pill with the
  percentage inside (`bar/BatteryPill.qml`). Opens
  `controlcenter/TodayPanel.qml` (calendar, `MediaCard`) or `QuickSettings.qml` (tiles for Wi-Fi,
  Bluetooth, power mode, microphone; volume and brightness `LevelSlider`s; battery; `Tray`), with
  `WifiPage` (scan, connect, password prompt) and `BluetoothPage` (scan, pair, connect). Super+A /
  Super+D or `qs ipc call island toggle settings|today`.
- Services: `Audio`, `Brightness`, `NetworkStatus`, `BluetoothStatus`, `Battery`. Widgets:
  `MaterialIcon`, `IconButton`, `Switch`, `LevelSlider`, `TextButton`.
- Launcher (`launcher/`, Super+R): `Fuzzy.js` scoring, tested in `tests/tst_fuzzy.qml`. Terminal apps
  open in Ghostty.
- OSD (`osd/Osd.qml`) for volume, mute, mic mute and brightness, on the focused monitor.
- Windows open floating and centered by default (user's request); Super+V tiles one.

### Phase 3: Notifications + rest of the control center + session menu
- Quickshell as the notification server: popups (from the island?) plus history in the "today" menu.
- Quick settings tiles still missing: DND, night light (hyprsunset).
- Session/power menu: lock, logout, suspend, reboot, shutdown.

### Phase 4: Clipboard + wallpaper
- Clipboard picker on Super+V using cliphist history. Move the float toggle (currently Super+V) to
  another key and tell the user which.
- Wallpaper drawn by Quickshell on the background layer, with a picker over `~/Pictures/Wallpapers`
  that also runs matugen (`matugen image <path> -m dark --source-color-index 0`).
  `misc.force_default_wallpaper` in `look.lua` may need changing once Quickshell draws the wallpaper.

### Phase 5: Lock screen + idle + greeter
- Quickshell session lock with PAM. Keep `hyprlock` as a fallback bind (currently Super+L) and tell the
  user how to recover from a crashed lock screen.
- `hypridle` config: dim, then lock, then screen off, then suspend. Ask the user for timings if unsure.
  Check hypridle's current config format.
- Quickshell greeter (`Quickshell.Services.Greetd`) to replace tuigreet, sharing parts with the lock
  screen. It runs inside a small Hyprland instance started by greetd; switching over is a change to
  `command` in `system/etc/greetd/config.toml`.

### Phase 6: Window switching + snap layouts
Added at the user's request after researching Windows/macOS features (2026-10-28). The phase number
isn't a priority: it can move ahead of Phases 3-5 if the user wants it sooner.
- **Alt+Tab switcher** (Windows/macOS style): an overlay with a live thumbnail of every window
  (`ScreencopyView` capturing `HyprlandToplevel.wayland`), most recently used first. Hold Alt, tap
  Tab / Shift+Tab to move, release Alt to focus the selected window; Escape cancels. The overlay
  takes the keyboard (`Exclusive`) while open so it sees the Alt release. Check before building:
  whether Hyprland exposes focus order (`focusHistoryID` or similar) for MRU sorting, and how much
  live capture of many windows costs on battery (fall back to still frames if it's heavy).
- **Snap layouts** (Windows 11 style): a small picker for the focused window with halves, quarters
  and thirds; picking one moves and resizes the (floating) window into that area of the monitor,
  minus the island's reserved zone and gaps. Check the Lua dispatchers for moving/resizing a window
  (exact names, and pixels vs. percent) on wiki.hypr.land. Ask the user which key opens it (and
  whether hovering a window's maximize area should too; Hyprland has no title bars, so probably not).
- Later candidates from the same research, not planned yet: a macOS-style dock, an Exposé overview
  (3-finger swipe up / hot corner, reusing the switcher's thumbnails), an emoji picker, a snipping
  overlay. Not possible on Wayland: a global app menu. Hard: real minimize, Stage Manager.

## Decisions made

- **External monitors:** keep the RTX in `AQ_DRM_DEVICES` (second, after the iGPU), so outputs wired
  to it work, accepting the battery cost.
- **No global NVIDIA env vars:** the wiki's NVIDIA page sets `LIBVA_DRIVER_NAME=nvidia` and
  `__GLX_VENDOR_LIBRARY_NAME=nvidia`, but those are for setups where NVIDIA renders the desktop. Here
  `prime-run` sets them per app.
- **No Plymouth:** it leaves tty1 in graphics mode, so tuigreet was invisible (black screen at boot).
  `install.sh` appends `plymouth.enable=0` to `/etc/default/limine`. The Phase 5 greeter is the first
  themed screen instead.
- **Early KMS:** CachyOS's chwd removes the `kms` mkinitcpio hook on NVIDIA laptops, so
  `system/etc/mkinitcpio.conf.d/20-early-amdgpu.conf` adds `amdgpu` to MODULES.
- **Color names in QML use an `m3` prefix** (`Colors.m3onSurface`). QML treats `on` + capital letter
  as a change handler: next to a `surface` property, `onSurface` silently reads as `#000000`.
  Reproduced in Qt 6.12. Follow this for every new color.
- **matugen's Quickshell JSON lives outside the shell directory**
  (`~/.local/state/quickshell/colors.json`). Quickshell reloads the whole shell when files in its config
  directory change; `Colors.qml` watches the file instead.
- **Floating by default:** a `float = true, center = true` rule for every window in `rules.lua`; the
  dwindle layout is kept for windows tiled with Super+V.
- **Brightness OSD through IPC:** sysfs backlight files send no inotify events, so the brightness
  binds run `qs ipc call brightness refresh` after `brightnessctl`. Volume and mic need nothing:
  the OSD watches PipeWire.
- **Island window:** fixed at the open menu's maximum size (resizing a layer surface every frame
  would stutter); `mask: Region { item: island }` limits input to the shape and `exclusiveZone`
  reserves only the closed height. The shape is one `ShapePath` (no seams between body and curves).
- **Island keyboard focus is always `OnDemand`.** Switching it between `None` and `Exclusive` while
  the surface was mapped made Hyprland clear the `HyprlandFocusGrab` right after it started, so the
  menu closed immediately. (The launcher maps a new surface with `Exclusive`, which works.)
- **Bluetooth pairing agent:** Quickshell can't register a BlueZ agent, and devices like the
  Keychron M6 ask the host to confirm pairing (journal: "No agent available for request type 2").
  `bt-agent` (`bluez-tools`, user-approved) runs from `autostart.lua` as
  `yes | bt-agent -c NoInputNoOutput`: without `--daemon` it reads answers from stdin, and in
  `--daemon` mode it rejects confirmations unless a PIN file matches. The Bluetooth page also sets
  the adapter `pairable` and the device `trusted` before `pair()`, and connects once paired.
- **Calendar locale:** `Qt.locale(Qt.uiLanguage)` (en_GB): the user has English UI with Dutch
  regional formats, and plain `Qt.locale()` gave Dutch day names next to English dates.
- **No wallpaper yet:** `install.sh` with no argument generates colors from seed `#6750a4`, the same
  scheme as the fallbacks in `Colors.qml`. `./install.sh "#rrggbb"` or `./install.sh <image>` overrides it.

## Open issues

None. Phase 1 verified on the laptop on 2026-10-27: RTX back on the PCI bus (cause unknown; it
returned on its own), tuigreet shows at boot, clock text is light, Nautilus follows the matugen accent,
live recolor works for the bar, borders and Ghostty, the bar's slide animation plays, and
`prime-run glxgears` shows up in `nvidia-smi`.

## Verified API notes

Checked against the docs or source in October 2026. Re-check anything not listed.

**Hyprland 0.56 (Lua)**
- `require("name")` is relative to `hyprland.lua`; a missing file aborts the calling file, so use
  `pcall(require, "name")` for optional files. The docs don't say whether required files are watched
  for changes; use `hyprctl reload`.
- Colors: `"rgba(rrggbbaa)"`, `"#rrggbb"`, `"rgb(...)"`; gradients are
  `{ colors = { ... }, angle = 45 }`.
- `hl.layer_rule({ name, match = { namespace = "<regex>" }, blur, blur_popups, ignore_alpha (0–1),
  dim_around, xray, animation, no_anim, order, above_lock, no_screen_share })`.
- `hl.exec_cmd` runs immediately (use inside `hl.on("hyprland.start", ...)`). `hl.dsp.exec_cmd` returns
  an action for `hl.bind`. Events: `hyprland.start`, `hyprland.shutdown`, `config.reloaded`.
- Window rules: `hl.window_rule({ name, match = { class = ".*" }, float = true, center = true })`;
  `float`/`center` are static effects (applied when the window opens).
- Bind flags (third argument): `locked`, `release`, `repeating`, `mouse`, `long_press`,
  `non_consuming`, `description`, ...
- `hl.env` runs before the compositor starts; `AQ_DRM_DEVICES` is a colon-separated list with the
  primary GPU first. `/dev/dri/by-path` can't be used in it because those paths contain colons.

**Quickshell 0.3.2**
- Imports: `import qs.<folder>` relative to `shell.qml`; no `qmldir` needed. Singletons:
  `pragma Singleton` with a `Singleton {}` root.
- `PanelWindow`: `anchors.*`, `margins.*`, `implicitWidth/Height`, `exclusionMode`
  (`ExclusionMode.Auto/Normal/Ignore`), `exclusiveZone`, `mask: Region`. Set `color: "transparent"`
  from the start. Anchoring only `top` centers the window (wlr-layer-shell spec).
  `WlrLayershell.namespace / .layer (WlrLayer.Background|Bottom|Top|Overlay) / .keyboardFocus
  (WlrKeyboardFocus.None|Exclusive|OnDemand)`.
- `Quickshell.Hyprland`: `Hyprland.workspaces / monitors / toplevels` are ObjectModels (`.values` in
  JS). `focusedWorkspace`, `focusedMonitor`, `monitorFor(screen)`, `refreshWorkspaces()`.
  `HyprlandWorkspace`: `id`, `name`, `active`, `focused`, `urgent`, `monitor`, `toplevels`,
  `activate()`. `Hyprland.dispatch(str)` sends the string as-is; with a Lua config it must be Lua,
  e.g. `hl.dsp.focus({ workspace = "3" })`. Prefer `activate()` where it exists.
- `SystemClock { precision: SystemClock.Minutes }`, then `Qt.formatDateTime(clock.date, ...)`.
- `FileView { path; watchChanges: true; onFileChanged: reload(); adapter: JsonAdapter { ... } }`.
  `Quickshell.env("HOME")`. `Quickshell.statePath()` points at a per-shell folder, not
  `~/.local/state`.
- `IpcHandler { target: "name"; function f(arg: string): void {} }`: arguments and returns must be
  typed (string, int, bool, real, color). Call with `qs ipc call name f`; list with `qs ipc show`.
- `Process { command: [...]; running }` (no shell; use `["sh", "-c", ...]`), `StdioCollector`,
  `Quickshell.execDetached([...])`.
- `Quickshell.Services.Greetd` exists: `createSession`, `respond`, `launch`, `cancelSession`; signals
  `authMessage`, `readyToLaunch`, `launched`, `authFailure`, `error`.
- Services load lazily: `UPower`, `Bluetooth`, `Networking`, `SystemTray`, `DesktopEntries` are empty
  until first accessed, then fill in asynchronously. Bindings are fine; a one-off read is not.
- `Quickshell.Services.Pipewire`: `Pipewire.defaultAudioSink/Source` (`PwNode`), `node.audio.volume`
  (0-1, writable), `.muted` (writable). Needs `PwObjectTracker { objects: [...] }` to fill `audio`.
- `Quickshell.Services.UPower`: `UPower.displayDevice` (`percentage` 0-1, `state`
  `UPowerDeviceState.Charging/...`, `isLaptopBattery`), `PowerProfiles.profile` (writable,
  `PowerProfile.PowerSaver/Balanced/Performance`, `PowerProfile.toString()`),
  `PowerProfiles.hasPerformanceProfile`.
- `Quickshell.Bluetooth`: `Bluetooth.defaultAdapter` (`enabled` writable, `devices`),
  `BluetoothDevice.connected`.
- `Quickshell.Networking`: `Networking.devices` (`NetworkDevice`: `type` `DeviceType.Wifi/Wired`,
  `connected`, `networks`), `WifiNetwork.signalStrength` (0-1), `Networking.wifiEnabled`.
- `Quickshell.Services.SystemTray`: `SystemTray.items` of `SystemTrayItem` (`icon`, `title`, `id`,
  `tooltipTitle`, `onlyMenu`, `hasMenu`, `menu`, `activate()`, `secondaryActivate()`).
  `QsMenuAnchor { menu; anchor.item; anchor.edges: Edges.Bottom; open() }`.
- `DesktopEntries.applications` of `DesktopEntry` (`name`, `genericName`, `comment`, `icon`,
  `keywords`, `noDisplay`, `runInTerminal`, `command` (string list), `execute()`). `execute()`
  ignores `runInTerminal`. `Quickshell.iconPath(name, fallback)`; `IconImage` in
  `Quickshell.Widgets` (`source`, `implicitSize`).
- `HyprlandFocusGrab { windows: [...]; active; onCleared }`. `mask: Region { Region { item } }`;
  an empty `Region {}` makes a surface click-through. A layer surface with no anchors is centered.
- `font.variableAxes: { "FILL": 1 }` fills Material Symbols (Qt 6.12).
- `Quickshell.Services.Mpris`: `Mpris.players` of `MprisPlayer` (`trackTitle`, `trackArtist`,
  `trackArtUrl`, `isPlaying`, `canTogglePlaying`, `canGoNext/Previous`, `togglePlaying()`, `next()`,
  `previous()`).
- Networking: `Networking.wifiEnabled` and `WifiDevice.scannerEnabled` are writable;
  `Network.connect()`, `disconnect()`, signal `connectionFailed(reason)` (`ConnectionFailReason`);
  `WifiNetwork.connectWithPsk(psk)`, `security` (`WifiSecurityType.Open/Owe/...`), `known`, `state`.
- Bluetooth: `BluetoothAdapter.discovering` writable; `BluetoothDevice` `connect()`, `disconnect()`,
  `pair()`, `paired`, `pairing`, `state` (`BluetoothDeviceState`), `battery`, `deviceName`, `icon`.
- Qt: `QtQuick.Shapes` (`Shape.CurveRenderer`, `PathArc.direction`), `MonthGrid` / `DayOfWeekRow`
  from `QtQuick.Controls.Basic` (MonthGrid needs an explicit height).
- `console.log` doesn't reach `qs log`; use `console.warn` when debugging.
- Scrolling: `WheelHandler` received no wheel events on the island's layer surface; a
  `MouseArea { acceptedButtons: Qt.NoButton; onWheel: ... }` under the content works and lets
  clicks through. Wheel events pass through MouseAreas that have no `onWheel`.
- Deprecated: `Quickshell.configDir` / `shellRoot` (use `shellDir`), and setting window
  `width/height` (use `implicit*`).

**matugen 4.2** (in Arch `extra`)
- Templates: `{{colors.<name>.default.hex}}` (also `hex_stripped`, `rgba`, ...), `{{mode}}`, loops
  `<* for name, value in colors *>`, filters like `| set_alpha: 0.5`. Relative `input_path` resolves
  against the config file; `output_path` can be a list.
- Hooks run through `sh -c`. A non-zero exit is only logged; the run continues.
- `matugen image <img> -m dark --source-color-index 0` (the index skips an interactive prompt),
  `matugen color hex "#rrggbb" -m dark`.

**Others**
- Ghostty: `theme = Matugen` loads `~/.config/ghostty/themes/Matugen`; `SIGUSR2` reloads open windows.
- GTK: libadwaita and adw-gtk3 read `@define-color accent_bg_color, window_bg_color, view_*,
  headerbar_*, sidebar_*, card_*, popover_*` from `~/.config/gtk-{3,4}.0/gtk.css`. Open apps need a
  restart.
- Yazi 26.9: sections `[mgr] [tabs] [mode] [indicator] [status] [input] [pick] [cmp] [tasks] ...`. A
  partial `theme.toml` is merged with the defaults; Yazi reads it at startup.
- tuigreet 0.11 (`greetd-tuigreet`): `--time --remember --asterisks --cmd <command>`.

## Testing on the laptop

- Quickshell reloads on file changes, but a reload after adding a property to a singleton
  (e.g. `Theme`) can leave parts blank; restart it then:
  `hyprctl dispatch 'hl.dsp.exec_cmd("pkill -x qs; sleep 0.5; qs")'`. `qs log` prints the running instance's log; panels can be
  opened with `qs ipc call ...` and checked with `grim -g "x,y wxh" out.png`. Run `pkill qs; qs` in a terminal to watch its log (also saved
  under `/run/user/1000/quickshell/`). `qs ipc show` lists IPC targets.
- `hyprctl reload` after editing a required Lua file; `hyprctl layers` shows layer namespaces;
  `hyprctl binds` shows loaded binds.
- Changes to `env.lua`, the initramfs, the kernel cmdline or greetd only apply after logging in again
  or rebooting. Say so in the checklist, and give a recovery path (Ctrl+Alt+F2, then
  `sudo systemctl disable greetd`) before changes that could stop the user getting to a desktop.
