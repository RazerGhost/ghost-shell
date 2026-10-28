#!/usr/bin/env bash
# Haunt, the user's Git client (github.com/RazerGhost/haunt): installs the pacman package from its
# newest release. The package isn't signed, so pacman only installs it from a downloaded file
# (`pacman -U`), as Haunt's README describes. The user's own repo, so it follows new releases.
# Run by `ghost install`; alone: `ghost install haunt`. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Haunt (from its newest release)"
# All releases are pre-releases so far, so not GitHub's "latest": the newest with the package.
asset=$(curl -fsSL https://api.github.com/repos/RazerGhost/haunt/releases | node -e '
    const releases = JSON.parse(require("fs").readFileSync(0, "utf8"));
    for (const release of releases) {
        const asset = release.assets.find(a => /^haunt-bin-.+-x86_64\.pkg\.tar\.zst$/.test(a.name));
        if (asset) { console.log(asset.name + " " + asset.browser_download_url); break; }
    }
')
[[ -n $asset ]] || fail "no Haunt release has a pacman package yet"
name=${asset%% *}
url=${asset#* }
# haunt-bin-0.2.0-1-x86_64.pkg.tar.zst -> 0.2.0-1, what `pacman -Q haunt-bin` reports.
version=${name#haunt-bin-}
version=${version%-x86_64.pkg.tar.zst}
if [[ $(pacman -Q haunt-bin 2>/dev/null | cut -d' ' -f2) == "$version" ]]; then
    echo "Haunt $version is installed."
    exit 0
fi
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fL --output "$tmp/$name" "$url"
sudo pacman -U --needed "$tmp/$name"
