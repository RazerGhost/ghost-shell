# dotfiles

Arch Linux + Hyprland dotfiles, deployed with GNU Stow.

- Each top-level directory is a Stow package mirroring `$HOME`, e.g. `hypr/.config/hypr/hyprland.lua`.
- `packages.txt` lists pacman packages; `aur.txt` lists AUR packages (installed with paru).
- Files use LF line endings (enforced in `.gitattributes`), even when edited on Windows.

@ENGINEERING_PRINCIPLES.md
