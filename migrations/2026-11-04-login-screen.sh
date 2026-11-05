# The login screen that ran after a logout until 2026-11-04 (Quickshell as the greeter user, see
# docs/history.md "The lock screen is your desktop, locked"): its copy of the shell, its Hyprland config
# and its home folder.
for path in /etc/greetd/quickshell /etc/greetd/hypr /var/lib/qs-greeter; do
    if [[ -e $path ]]; then
        sudo rm -rf "$path"
    fi
done
