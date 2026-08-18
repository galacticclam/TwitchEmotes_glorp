#!/bin/bash

set -euo pipefail

stage=${1:-alpha}

version_mainline=$(grep "Version: " TwitchEmotes_glorp-Mainline.toc | cut -d ' ' -f 3)
version_classic=$(grep "Version: " TwitchEmotes_glorp-Classic.toc | cut -d ' ' -f 3)

[ "$version_mainline" == "$version_classic" ] || {
    echo "Error: TwitchEmotes_glorp-Mainline.toc is version $version_mainline, but TwitchEmotes_glorp-Classic.toc is version $version_classic"
    exit 1
}

version="$version_mainline-$stage"

dist_root="dist"
dist_dir="TwitchEmotes_glorp"
zip_name="TwitchEmotes_glorp-$version.zip"

make build

rm -f "$dist_root/$zip_name"
(cd "$dist_root" && "/c/Program Files/7-Zip/7z" a "$zip_name" "$dist_dir")
