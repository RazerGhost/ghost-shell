#!/usr/bin/env bash
# Tests for system/usr/local/lib/ghost-boot-menu (Limine's boot menu from Settings): run from the
# repo root with `bash tests/boot_menu_test.sh`. A copy of it reads a stand-in /etc/default/limine
# pointing at a scratch limine.conf, so nothing real is touched.
set -uo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/esp"
printf 'ESP_PATH="%s"\nKERNEL_CMDLINE[default]+=" quiet"\n' "$scratch/esp" >"$scratch/limine-defaults"
printf 'firmware_logo: yes\ntimeout: 1\nquiet: yes\n\n/+CachyOS\n    //linux-cachyos\n    cmdline: quiet\n' >"$scratch/esp/limine.conf"
sed "s#/etc/default/limine#$scratch/limine-defaults#g" system/usr/local/lib/ghost-boot-menu >"$scratch/helper"
passed=0 failed=0
check() { # name, expected, got
    if [[ $3 == "$2" ]]; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL: $1: expected '$2', got '$3'"; fi
}
option() { sed -n "s/^$1: //p" "$scratch/esp/limine.conf"; }

bash "$scratch/helper" remember
check "remember: shown" "3 no yes" "$(option timeout) $(option quiet) $(option remember_last_entry)"
bash "$scratch/helper" shown
check "shown: no remembering" "3 no no" "$(option timeout) $(option quiet) $(option remember_last_entry)"
bash "$scratch/helper" hidden
check "hidden: quiet, a key shows it" "1 yes no" "$(option timeout) $(option quiet) $(option remember_last_entry)"
check "each option once" "1" "$(grep -c '^timeout:' "$scratch/esp/limine.conf")"
check "the logo kept" "yes" "$(option firmware_logo)"
check "the entries kept" "    cmdline: quiet" "$(grep 'cmdline' "$scratch/esp/limine.conf")"
bash "$scratch/helper" "shown; rm -rf /" 2>/dev/null
check "anything else refused" "2" "$?"
bash "$scratch/helper" 2>/dev/null
check "nothing refused" "2" "$?"

echo "$passed passed, $failed failed"
((failed == 0))
