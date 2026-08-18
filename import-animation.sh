#!/bin/bash

. .env

set -euo pipefail

rm -rf import && mkdir import
image_orig="import/$2.webp"
# Prefer WebP output for normal animations. PNG is only a fallback when the stacked
# sheet exceeds ImageMagick's WebP limits for very wide or tall animations.
image_appended="import/$2-appended.png"
image_final="emotes/$2.webp"
image_fallback="emotes/$2.png"

curl "$1" -o "$image_orig"

anim_dump -folder import "$image_orig"

num_frames=$(ls -l import/dump_* | wc -l)
if [ $# -ge 4 ] ; then
    frame_sampling=$3
    frame_offset=$4
    i=$frame_offset
    n=$num_frames
    num_frames=0

    frames=()
    while [ $i -lt $n ]; do
        frames+=( $(printf "import/dump_%04d.png" $i) )
        i=$(($i + $frame_sampling))
        num_frames=$(($num_frames + 1))
    done

    # TODO: Resize frames
    # magick ${frames[@]} -resize "64x124" -append "$image_appended"
    magick ${frames[@]} -resize x64 -append "$image_appended"
else
    # TODO: Resize frames
    # magick import/dump_* -resize "64x124" -background none -gravity center -extent "64x124" -append "$image_appended"
    # magick import/dump_* -resize x64 -background none -append "$image_appended"
    # magick import/dump_* -resize "128x64" -background none -gravity center -extent "128x64" -append "$image_appended"
    magick import/dump_* -resize x64 -background none -append "$image_appended"
fi

orig_h=$(magick identify -ping -format '%h' "$image_appended")
orig_w=$(magick identify -ping -format '%w' "$image_appended")

first_frame="$(ls import/dump_*.png | head -n 1)"
frame_w=$(magick "$first_frame" -resize x64 -format '%w' info:)
frame_h=$(magick "$first_frame" -resize x64 -format '%h' info:)
frames=$(($orig_h/$frame_h))

# Round h up to the next power of 2
final_h=$(($orig_h-1))
final_h=$(($final_h|($final_h>>1)))
final_h=$(($final_h|($final_h>>2)))
final_h=$(($final_h|($final_h>>4)))
final_h=$(($final_h|($final_h>>8)))
final_h=$(($final_h|($final_h>>16)))
final_h=$(($final_h|($final_h>>32)))
final_h=$(($final_h+1))

final_w=$(($orig_w-1))
final_w=$(($final_w|($final_w>>1)))
final_w=$(($final_w|($final_w>>2)))
final_w=$(($final_w|($final_w>>4)))
final_w=$(($final_w|($final_w>>8)))
final_w=$(($final_w|($final_w>>16)))
final_w=$(($final_w|($final_w>>32)))
final_w=$(($final_w+1))

final_w=$orig_w
final_h=$orig_h

if [ "$orig_w" -gt 16383 ] || [ "$orig_h" -gt 16383 ]; then
    cp "$image_appended" "$image_fallback"
else
    magick "$image_appended" "$image_final"
fi

emotes_newline='["'$2'"] = basePath .. "'$2'.tga:28:28",'
if ! grep -Fq "\[\"$2\"\]" emotes.lua; then
    sed -i -e '$i\'"    $emotes_newline" emotes.lua
fi

animation_newline="TwitchEmotes_animation_metadata[basePath .. \"$2.tga\"] = {[\"nFrames\"] = $frames, [\"frameWidth\"] = $frame_w, [\"frameHeight\"] = $frame_h, [\"imageWidth\"] = $orig_w, [\"imageHeight\"] = $orig_h, [\"framerate\"] = 18, [\"imageFrameHeight\"] = $frame_h}";
if ! grep -Fq "basePath .. \"$2.tga\"" animation.lua; then
    echo "$animation_newline" >> animation.lua
fi
