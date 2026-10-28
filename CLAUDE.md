# dotfiles

Arch Linux + Hyprland dotfiles, deployed with GNU Stow.

- Each top-level directory is a Stow package mirroring `$HOME`, e.g. `hypr/.config/hypr/hyprland.lua`.
- `packages.txt` lists pacman packages; `aur.txt` lists AUR packages (installed with paru).
- `install.sh` sets up the laptop by running the scripts in `setup/` in order, one per concern: `packages`, `system` (udev rule, boot, greetd, services, Docker), `desktop` (`stow` for every package, GTK, colors), then one per app (`discord`, `spotify`, `steam`, `zen`). They share `setup/lib.sh` (`step`, `clone_or_pull`, `json_edit`) and each can run alone. Keep them re-runnable; new setup steps go in the script for their concern (or a new one).
- Setting the wallpaper and colors goes through `matugen/.config/matugen/wallpaper.sh`, used by both install.sh and the shell's wallpaper picker. matugen hooks only deliver colors; setting an app up belongs in its `setup/` script.
- `update-greeter.sh` (run by install.sh) sets up the Quickshell login screen: copies the shell to `/etc/greetd/quickshell/` and creates `/var/lib/qs-greeter/shared/`, which the shell keeps filled with the user's settings, colors and lock screen picture (`greeter/sync.sh`). Re-run it after changing the shell's code, since the login screen runs its own copy.
- `system/` is not a Stow package: it mirrors `/` and `setup/system.sh` copies its files into place with `sudo install` (udev rule, greetd config and drop-in, mkinitcpio drop-in); it also appends `plymouth.enable=0` to `/etc/default/limine` (Plymouth breaks tuigreet).
- matugen (`matugen/`) generates colors from the wallpaper for Quickshell, Hyprland, Ghostty, GTK, Yazi, Spotify, Discord, MangoHud, Zed, Steam and Zen (list in its `config.toml`). Templates are committed; generated output is gitignored.
- Browser is Zen (`zen-browser-bin` from the AUR), not Firefox. Use it wherever a browser is launched or set as default.
- Hyprland and Quickshell run on the laptop (CachyOS). A session on the laptop can run and test changes directly (`qs`, `hyprctl`, `journalctl`); a session on another machine can't, and hands the user a test checklist instead.
- Commit and push after each phase or fix; the user may pull on another machine.
- `tests/` holds QML tests (not a Stow package). Run them with `QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests`, and the tiling layout's Lua test with `lua tests/tiling_test.lua`.
- Files use LF line endings (enforced in `.gitattributes`), even when edited on Windows.
- `ROADMAP.md` has the phase plan, decisions and open issues. Update it when a phase finishes or a decision changes.
- `NOTES.md` has the verified Quickshell/Hyprland API facts and how to test on the laptop. Read it before using an API it might cover, and add facts you verify.

@ENGINEERING_PRINCIPLES.md
@ROADMAP.md
