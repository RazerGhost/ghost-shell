# The HP logo through the boot, tried and dropped on 2026-11-04 (ROADMAP "The HP logo through the
# boot"): its plymouth-quit drop-in (it kept the logo on screen and crashed Hyprland's first
# start), greetd's ordering after Plymouth (greetd's own unit has it), and the `splash` line it
# added to Limine's kernel line.
changed=false
if [[ -e /etc/systemd/system/plymouth-quit.service.d/retain-splash.conf ]]; then
    sudo rm /etc/systemd/system/plymouth-quit.service.d/retain-splash.conf
    sudo rmdir --ignore-fail-on-non-empty /etc/systemd/system/plymouth-quit.service.d
    changed=true
fi
if [[ -e /etc/systemd/system/greetd.service.d/after-plymouth.conf ]]; then
    sudo rm /etc/systemd/system/greetd.service.d/after-plymouth.conf
    sudo rmdir --ignore-fail-on-non-empty /etc/systemd/system/greetd.service.d
    changed=true
fi
if $changed; then
    sudo systemctl daemon-reload
fi
if [[ -f /etc/default/limine ]] && grep -qxF 'KERNEL_CMDLINE[default]+=" splash"' /etc/default/limine; then
    sudo sed -i '/^KERNEL_CMDLINE\[default\]+=" splash"$/d' /etc/default/limine
    sudo limine-mkinitcpio
fi
