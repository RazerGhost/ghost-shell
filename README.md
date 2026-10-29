# Ghost Shell

A complete desktop on Arch (CachyOS) built from Hyprland and a Quickshell shell, colored from the
wallpaper. Made for an HP Omen 16 (AMD iGPU + NVIDIA RTX), but split into modules so another
machine can take what it needs.

![The desktop](docs/screenshots/desktop.png)

| | |
|:---:|:---:|
| ![Quick settings](docs/screenshots/quick-settings.png) **Quick settings** | ![Launcher](docs/screenshots/launcher.png) **Launcher** |
| ![Settings](docs/screenshots/settings.png) **Settings** | |

## What's in it

- **The island**: the bar, a shape growing out of the top edge with workspaces, the time (or the
  playing song's cover) and status icons. It opens into menus: quick settings (Wi-Fi, Bluetooth,
  sound, power mode, game mode, system stats), today (date, weather, calendar and its events, to-do, note, timer,
  notifications), background apps, media, clipboard, emoji.
- **Windows**: a tiling layout of its own (halves, thirds, quarters from the window menu, or by
  the number of windows), Snap Assist, window tabs, Alt+Tab with live previews, an overview
  (Super+Tab, a three-finger swipe or the top-left corner), minimize, a dock with window previews.
- **The rest of a desktop**: notifications (with sounds), launcher (apps, windows, files with `/`, commands with `>`, a calculator), on-screen
  volume and brightness, lock and login screen, idle and night light, screenshots and screen
  recording, a password prompt for apps (polkit), an equalizer, screen time, web apps
  (`ghost webapp`), an update count, wallpapers, and a welcome tour on the first start.
- **A settings app** for what would otherwise be config files: displays, sound, keyboard and
  touchpad, power, default apps, keybinds, Btrfs snapshots and more.
- **Glass**: see-through panels with Hyprland's blur behind exactly their shape.
- **One color scheme** from the wallpaper (matugen) for the shell, Hyprland, Ghostty, GTK apps,
  Zed, Yazi, Zen, Discord, Spotify, Steam and MangoHud.

The full plan and every decision behind it: [ROADMAP.md](ROADMAP.md). Keybinds:
[docs/keybinds.md](docs/keybinds.md).

## Install

On Arch or CachyOS, with `git` installed:

```sh
git clone https://github.com/RazerGhost/ghost-shell ~/ghost-shell
cd ~/ghost-shell
./install.sh ~/Pictures/some-wallpaper.jpg   # or "#22d3ee" for colors from one color
```

It installs the packages, links the configs into your home folder (GNU Stow) and sets up the
system (login screen, services). It asks for your password for pacman and the system parts. Log
out and back in afterwards. Some app themes need the app started once first; the install says
so and `ghost install <module>` finishes them later.

## The `ghost` command

After the first install, `ghost` (in `~/.local/bin`) does everything:

| Command | |
|---|---|
| `ghost update` | pull the repo, then install again (new packages, new setup steps) |
| `ghost install [module...]` | packages and setup for some or all modules |
| `ghost theme <wallpaper \| "#rrggbb">` | a new wallpaper and the colors from it |
| `ghost greeter` | update the login screen's copy of the shell (after changing its code) |
| `ghost calendar add [name]` | subscribe to a calendar (it asks for the link: a Proton Calendar share link or any .ics address; `remove <name>`, `list`, `sync`) |
| `ghost webapp add <name> <url> [icon]` | a site in its own window, in the launcher and the dock (`remove <name>`, `list`) |
| `ghost doctor` | check that everything is set up; each problem says what fixes it |
| `ghost modules` | list the modules and which ones this machine uses |
| `ghost keybinds` | the keybinds as a Markdown table |

## Modules

Each folder in `modules/` is one part of the setup: its packages (`packages.txt`, `aur.txt`) and
its setup (`setup.sh`).

| Module | |
|---|---|
| `core` | Hyprland, the shell, fonts and themes, the login screen, the colors |
| `system` | this laptop's GPU rule, boot options, greetd and services |
| `snapshots` | Btrfs snapshots: the system's before and after every update (bootable), your home folder hourly |
| `apps` | terminal, editor, files, pictures, video, music, browser, web apps |
| `dev` | languages, package managers and Docker |
| `gaming` | Steam, Proton, Lutris, Heroic, MangoHud; Steam's theme |
| `discord`, `spotify`, `zen` | those apps in the wallpaper's colors |
| `haunt` | the Haunt Git client, from its release package, and what building it needs |
| `capture` | screen recording, color picker, text and QR codes from the screen |
| `phone` | KDE Connect |
| `proton` | Proton Mail, Pass and VPN |
| `calendar` | calendar events in the today menu, from a Proton Calendar share link (`ghost calendar add`) |
| `wave3` | the Elgato Wave:3 microphone with openxlr and a voice chain ([its README](modules/wave3/README.md)) |

Every module except `wave3` is installed unless `~/.config/ghost/modules` lists the ones this
machine wants, one per line (`wave3` only ever comes from that list: it's for the machine the
microphone is plugged into). That file isn't in the repo, so each machine keeps its own:

```sh
mkdir -p ~/.config/ghost
printf '%s\n' core apps dev > ~/.config/ghost/modules
```

The `system` module is written for this laptop (an AMD + NVIDIA GPU rule, Limine boot entries);
leave it out elsewhere.

## Your own changes

Settings made in the shell's settings window live outside the repo
(`~/.local/state/quickshell/`). For things the settings window doesn't cover, these files are
loaded last and aren't in git, so `ghost update` never conflicts with them:

| File | For |
|---|---|
| `~/.config/hypr/local.lua` | Hyprland: your own binds, monitors, any option |
| `~/.config/ghostty/local` | Ghostty settings |
| `~/.config/fish/conf.d/local.fish` | fish: aliases, variables |

## Layout

| Folder | |
|---|---|
| `hypr/`, `quickshell/`, `ghostty/`, `fish/`, `matugen/`, `zed/`, `spotify/`, `pipewire/`, `paru/`, `bin/` | configs, linked into `$HOME` by Stow (each mirrors the home folder) |
| `modules/` | packages and setup per module, `lib.sh` shared by them |
| `system/` | files for `/` (udev rule, greetd, mkinitcpio), installed by the `system` module |
| `tests/` | tests: `QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests` and `lua tests/tiling_test.lua` |
| `docs/` | keybinds and screenshots |

[NOTES.md](NOTES.md) has the Hyprland and Quickshell API facts this was built on.
