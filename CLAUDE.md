# dotfiles

Arch Linux + Hyprland dotfiles, deployed with GNU Stow.

- Each top-level directory is a Stow package mirroring `$HOME`, e.g. `hypr/.config/hypr/hyprland.lua`.
- `packages.txt` lists pacman packages; `aur.txt` lists AUR packages (installed with paru).
- `install.sh` sets up the laptop: packages, the udev rule, greetd, `stow` for every package, a matugen run. Keep it re-runnable and extend it when a phase needs new setup steps.
- `update-greeter.sh` (run by install.sh) sets up the Quickshell login screen: copies the shell to `/etc/greetd/quickshell/` and a snapshot of colors/wallpaper to `/var/lib/qs-greeter/`; re-run it after changing the wallpaper.
- `system/` is not a Stow package: it mirrors `/` and `install.sh` copies its files into place with `sudo install` (udev rule, greetd config and drop-in, mkinitcpio drop-in); it also appends `plymouth.enable=0` to `/etc/default/limine` (Plymouth breaks tuigreet).
- matugen (`matugen/`) generates colors from the wallpaper for Quickshell, Hyprland, Ghostty, GTK and Yazi. Templates are committed; generated output is gitignored.
- Browser is Zen (`zen-browser-bin` from the AUR), not Firefox. Use it wherever a browser is launched or set as default.
- Hyprland and Quickshell run on the laptop (CachyOS). A session on the laptop can run and test changes directly (`qs`, `hyprctl`, `journalctl`); a session on another machine can't, and hands the user a test checklist instead.
- Commit and push after each phase or fix; the user may pull on another machine.
- `tests/` holds QML tests (not a Stow package). Run them with `QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests`.
- Files use LF line endings (enforced in `.gitattributes`), even when edited on Windows.
- `ROADMAP.md` has the phase plan, decisions and open issues. Update it when a phase finishes or a decision changes.
- `NOTES.md` has the verified Quickshell/Hyprland API facts and how to test on the laptop. Read it before using an API it might cover, and add facts you verify.

@ENGINEERING_PRINCIPLES.md
@ROADMAP.md
