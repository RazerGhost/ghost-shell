# Notes: verified APIs and testing

Reference for working on the shell; the plan and decisions are in `ROADMAP.md`.

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
- `Quickshell.Services.Notifications`: `NotificationServer { keepOnReload; actionsSupported;
  imageSupported; persistenceSupported; onNotification: n => n.tracked = true }`;
  `trackedNotifications`. `Notification`: `id`, `appName`, `appIcon`, `image`, `summary`, `body`,
  `urgency` (`NotificationUrgency.Low/Normal/Critical`), `actions` (`identifier`, `text`,
  `invoke()`), `transient`, `lastGeneration` (true for ones carried over a reload, which are
  announced again), `dismiss()`, `expire()`. No timestamp. App icons can be names, paths or URLs;
  show them with `IconImage` (a plain `Image` scales up a tiny icon).
- Lock: `WlSessionLock { locked; WlSessionLockSurface { ... } }` (one surface per screen;
  `Quickshell.Wayland`). `PamContext { config: "login"; start(); respond(text) }` with
  `responseRequired`, `completed(PamResult.Success/Failed/Error/MaxTries)`, `error(PamError)`.
  `MultiEffect` (`QtQuick.Effects`) blurs (`blurEnabled`, `blur`, `blurMax`). Use
  `Qt.locale(name).toString(date, format)`; `Qt.formatDate(date, locale, x)` treats `x` as a
  format type, not a string.
- hypridle 0.1.8: `general { lock_cmd; before_sleep_cmd; after_sleep_cmd; inhibit_sleep }`,
  `listener { timeout; on-timeout; on-resume; condition_cmd; condition_retry }`. Screen off is
  `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'`.
- cliphist: `cliphist list` prints `<id>\t<preview>` newest first; images look like
  `[[ binary data 120 KiB png 1920x1080 ]]`. `cliphist decode <id>`, `cliphist delete` (the
  whole line on stdin), `cliphist wipe`. `wtype -M ctrl v -m ctrl` presses Ctrl+V.
- `Qt.labs.folderlistmodel` `FolderListModel { folder; nameFilters; showDirs }` (roles
  `filePath`, `fileName`) doesn't notice its folder being created later; reset `folder` to
  re-read. `FileView.writeAdapter()` saves a `JsonAdapter`; `printErrors: false` silences a
  missing file.
- hyprsunset 0.4: `hyprctl hyprsunset temperature <K>` / `identity` / `reset` / `profile` (prints
  the active profile's Time/Temperature/Gamma/Identity, not manual overrides). Profiles in
  `~/.config/hypr/hyprsunset.conf` with `time`, `temperature`, `identity`, `on-switch`.
- `HyprlandToplevel.address` has no `0x` (Hyprland's selector needs `address:0x<address>`).
  `Hyprland.activeToplevel` is null after the shell starts until focus changes; match
  `ToplevelManager.activeToplevel` (`Quickshell.Wayland`) against `HyprlandToplevel.wayland`.
  `DesktopEntries.heuristicLookup(appId)` finds a window's .desktop entry (icon).
- Lua dispatchers take a target window: `hl.dsp.window.move({ window = "address:0x...",
  workspace = "special:x", follow = false })`, also `close`, `float`, `fullscreen({ mode =
  "maximized" | "fullscreen", action = "toggle" })`, `move({ x, y, relative })`;
  `hl.dsp.focus({ window = ... })`. A special workspace that's never toggled stays hidden.
- Lua events: `hl.on("window.active", function(window, reason) ... end)`, also `window.urgent`,
  `window.close`, `window.open`, `window.update_state` (see the wiki's events.md). `input.follow_mouse`:
  0 cursor never focuses, 1 hover focuses, 2 click focuses (pointer separate), 3 click doesn't
  focus. `hl.dsp.window.alter_zorder({ window?, mode = "top" | "bottom" })`.
- Lua `HL.Window` (stubs in `/usr/share/hypr/stubs/hl.meta.lua`): `address` (with 0x, so
  `"address:" .. w.address` selects it), `class`, `at.x/.y`, `size.x/.y`, `floating`, `fullscreen`
  (0 = no), `workspace.name`, `focus_history_id`, `pinned`. `hl.get_windows()`, `hl.get_monitors()`
  (`x`, `y`, `width`, `height`, `scale`). Lua's `io` and `os` work in the config. A window is still
  readable in `window.close`.
- `Hyprland.rawEvent(event)` gives every socket2 event (`event.name`, `event.data`, e.g.
  `urgent` with the address without 0x). Don't annotate the parameter's type in QML
  (`HyprlandIpcEvent` isn't a registered name; Qt logs an error per event).
- wtype: Hyprland doesn't run its binds for wtype's virtual keyboard, so binds can't be tested
  with it. `wtype -M alt` only sets the modifier, without Alt key events; `-P Alt_L` / `-p Alt_L`
  send real ones.
- Freezing and cropping the screen: `ScreencopyView { captureSource: <ShellScreen>; live: false }`
  + `captureFrame()` gives one still frame (`hasContent` once it's in). A `ShaderEffectSource {
  sourceItem; sourceRect }` cut from it, then `grabToImage(cb, Qt.size(w * scale, h * scale))` and
  `result.saveToFile(path)`, saves just that part. The ShaderEffectSource must be visible (put it
  behind, `z: -1`). Draw nothing over the screen until `hasContent`, or the frame includes it.
- `ScreencopyView { captureSource: toplevel.wayland; live; constraintSize }` (`Quickshell.Wayland`)
  captures windows on other workspaces too.
- `float({ action })` takes `"toggle"` (default), `"enable"`/`"on"`, `"disable"`/`"off"`; an
  unknown value like `"set"` toggles. `fullscreen` uses `"set"`/`"unset"`. `resize({ window, x, y
  })` and `move({ window, x, y })` take logical pixels (a 940x1004 resize gives exactly that).
  Monitor `lastIpcObject.reserved` is `[left, top, right, bottom]` (after `refreshMonitors()`);
  `hyprctl getoption general:gaps_out -j` gives `{ "css": "20 20 20 20" }` (top right bottom left).
  `hyprctl clients -j` has `focusHistoryID` (0 = focused, then most recently used).
- Gestures: `hl.gesture({ fingers = 3, direction = "up", action = function() hl.exec_cmd("...") end })`;
  directions include horizontal, vertical, up, down, left, right, pinch (wiki: binds/gestures).
- `general.gaps_in/out` only affect tiled windows. Here everything floats, so they matter only
  where the shell places windows (Snap); a maximized window fills the work area minus a 2 px
  border, no gaps.
- `hl.dsp.cursor.move({ x, y })` moves the pointer: useful for testing hover behaviour.
- While a layer surface with `WlrKeyboardFocus.Exclusive` is mapped, Hyprland refuses to focus any
  window (`FocusState.cpp`: "Refusing a keyboard focus to a window because of an exclusive ls").
  A surface that closes and then focuses a window must be `OnDemand` (it still gets the keyboard
  when it appears, unless the pointer is constrained), or the focus call races the unmap.
- Quickshell reads its icon theme from `QS_ICON_THEME` (set in `env.lua`), not GTK's setting.
- `IdleMonitor { enabled; timeout (seconds); respectInhibitors (default true); isIdle }`
  (`Quickshell.Wayland`, ext-idle-notify). `timeout: 0` reports idle at once, so use `enabled:
  false` for "never". `enabled` reads false until the monitor is set up; changing `timeout` later
  works. Only Wayland idle inhibitors count, not D-Bus ones.
- `FloatingWindow { title; implicitWidth/Height; minimumSize; color }` is a normal toplevel
  (class `org.quickshell`); Hyprland draws no decorations for it. Closing it (Super+W) sets
  `visible` to false; setting it true again reopens it.
- Hyprland sends every xdg toplevel the tiled-left/right/top/bottom states from the start
  (`XDGShell.cpp`, so apps drop their shadows). Qt reports a window tiled on all edges as
  maximized, so `FloatingWindow.maximized` is always true; use Hyprland's state instead
  (`lastIpcObject.fullscreen === 1` is maximized). `startSystemMove()` hands the pointer to Hyprland: calling it on press swallows double-clicks, so call it once the pointer has dragged past `Qt.styleHints.startDragDistance`.
- An inline `component` can't be declared in a `pragma Singleton` file ("X is not a type"); put
  it in its own file.
- A `JsonAdapter` in a `FileView` loads after the shell starts, even with `blockLoading` (that
  only affects `text()`/`data()`): bindings see the defaults first, then the saved values.
  `onAdapterUpdated: writeAdapter()` saves every change.
- `DesktopEntry.categories` (list), `DesktopEntries.byId(id)`.
- `hl.bind(keys, action, { description = "..." })`; `hyprctl binds -j` gives `modmask` (Super 64,
  Ctrl 4, Alt 8, Shift 1), `key`, `description`, `has_description`.
- `Repeater` only creates visual items; `Variants { model: [...] }` creates any object (e.g. a
  `FileView` per file), each with `modelData`.
- An `IpcHandler` exposes every function and property declared inside it (it scans its own
  QML type), so keep helpers outside it.
- `ScriptModel { values }` needs a JS array: spread a typed QML list (`[...list]`). Without
  `objectProp` it compares values structurally, so a recomputed but equal list changes nothing.
- `PwNodePeakMonitor { node: Pipewire.defaultAudioSink }` measures what plays through the speakers
  (`peaks` per channel, `peak`; 0-1); `enabled` turns it off.
- `PolkitAgent` registers as the session's polkit agent (`isRegistered`); only one agent can.
  `flow` (`AuthFlow`): `message`, `iconName`, `selectedIdentity.displayName`, `inputPrompt`,
  `responseVisible`, `isResponseRequired`, `supplementaryMessage`/`supplementaryIsError`,
  `submit()`, `cancelAuthenticationRequest()`. `pkexec true` is a harmless test.
- `IdleInhibitor { window; enabled }` (`Quickshell.Wayland`). `hyprctl clients -j` shows
  `inhibitingIdle` per window (Vesktop holds one during voice).
- Notifications: `NotificationServer.inlineReplySupported`, `Notification.hasInlineReply`,
  `sendInlineReply(text)` (an `inline-reply` action over D-Bus).
- Testing notifications by hand: `gdbus call ... Notify` prints `(uint32 7,)`; take the id with
  `sed -E 's/\(uint32 ([0-9]+),\)/\1/'` (grepping digits catches the 32 in "uint32").
  `CloseNotification <id>` removes it from the shell's list; that works.
- `qs ipc call` exits 0 even for an unknown target, but non-zero when no shell is running.
- `hyprctl hyprsunset temperature` prints the last temperature set, also after `identity`, so it
  doesn't tell whether night light is on.
- A singleton is only created when something uses it, so an `IpcHandler` inside one doesn't exist
  until then ("Target not found"); put handlers in always-loaded components.
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
- Creates missing parent folders of an `output_path` (`create_dir_all` in its template code).

**Others**
- Ghostty: `theme = Matugen` loads `~/.config/ghostty/themes/Matugen`; `SIGUSR2` reloads the config.
  Ghostty runs as one process for all windows (`--gtk-single-instance=true`), so new windows only
  get config changes after that reload; `window-decoration = client` showed in new windows after it.
- GTK: libadwaita and adw-gtk3 read `@define-color accent_bg_color, window_bg_color, view_*,
  headerbar_*, sidebar_*, card_*, popover_*` from `~/.config/gtk-{3,4}.0/gtk.css`. Open apps need a
  restart.
- Spotify (AUR `spotify`): `/usr/bin/spotify` is a script that reads extra flags from
  `$XDG_CONFIG_HOME/spotify-flags.conf`, one per line, `#` comments skipped.
- Vesktop (`vesktop-bin` 1.6.8): `/usr/bin/vesktop` reads flags from `~/.config/electron-flags.conf`,
  `~/.config/vesktop-flags.conf` and `~/.config/vesktop/vesktop-flags.conf`. Its `settings.json` key
  `nativeTitleBar` (default false) drops Discord's own window buttons; Vencord's settings are in
  `~/.config/vesktop/settings/settings.json` (`enabledThemes`, `plugins.<Name>`).
- Spicetify 2.46: `spicetify refresh` rewrites the theme's CSS, JS, colors and assets without a full
  apply; `spicetify config color_scheme <name>` picks a `color.ini` section.
- Yazi 26.9: sections `[mgr] [tabs] [mode] [indicator] [status] [input] [pick] [cmp] [tasks] ...`. A
  partial `theme.toml` is merged with the defaults; Yazi reads it at startup.
- tuigreet 0.11 (`greetd-tuigreet`): `--time --remember --asterisks --cmd <command>`.

## Testing on the laptop

- Quickshell reloads on file changes, but a reload after adding a property to a singleton
  (e.g. `Theme`) can leave parts blank; restart it then:
  `hyprctl dispatch 'hl.dsp.exec_cmd("pkill -x qs; sleep 0.5; ~/.config/hypr/shell.sh")'` (the
  wrapper restarts qs only after a crash; `pkill` ends it too, so start it again). `qs log` prints the running instance's log; panels can be
  opened with `qs ipc call ...` and checked with `grim -g "x,y wxh" out.png`. Run `pkill qs; qs` in a terminal to watch its log (also saved
  under `/run/user/1000/quickshell/`). `qs ipc show` lists IPC targets.
- `xdg-mime default` calls running side by side overwrite each other's `mimeapps.list`: run them one
  after another.
- Qt's JavaScript `Array.prototype.sort` isn't stable: break ties explicitly (an index) when the
  original order matters (EmojiData.filter).
- Changing a `.js` file didn't reload the shell (QML files do): restart qs to test JS changes.
- Reloads happen when a file's contents change (`touch` alone doesn't). After a failed reload,
  fixing the file didn't trigger another one: restart qs. The island reports both
  (`Quickshell.reloadCompleted` / `reloadFailed`, then `inhibitReloadPopup()`).
- A window inside a singleton (the settings window) can survive a reload with its old code:
  after editing `settings/SettingsWindow.qml`, restart qs before testing.
- `hyprctl reload` after editing a required Lua file; `hyprctl layers` shows layer namespaces;
  `hyprctl binds` shows loaded binds.
- Changes to `env.lua`, the initramfs, the kernel cmdline or greetd only apply after logging in again
  or rebooting. Say so in the checklist, and give a recovery path (Ctrl+Alt+F2, then
  `sudo systemctl disable greetd`) before changes that could stop the user getting to a desktop.
