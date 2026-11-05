# Early KMS where an AMD GPU drives the display: amdgpu loads before any services start, so the
# session's first frame isn't waiting for it. CachyOS's chwd removes the kms hook on NVIDIA
# laptops (10-chwd-kms.conf), so without this amdgpu loads late on the hybrid laptop. Elsewhere
# (the desktop, where the RTX drives the screens) the drop-in is taken out again.
kms=system/etc/mkinitcpio.conf.d/20-early-amdgpu.conf
installed=/etc/mkinitcpio.conf.d/$(basename "$kms")
if [[ $(hw display-gpu) == amd ]]; then
    echo "AMD drives the display: amdgpu loads early"
    if ! cmp -s "$kms" "$installed"; then
        sudo install -Dm644 "$kms" "$installed"
        rebuild_boot=true
    fi
elif [[ -e $installed ]]; then
    echo "AMD doesn't drive the display: amdgpu no longer loads early"
    sudo rm "$installed"
    rebuild_boot=true
fi
