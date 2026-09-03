#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_icon="$project_dir/assets/branding/finflow-icon-master-v2.png"
rounded_icon="$project_dir/assets/branding/finflow-icon-rounded.png"

if ! command -v convert >/dev/null 2>&1; then
  echo "ImageMagick (convert) is required to generate the app icons." >&2
  exit 1
fi

if [[ ! -f "$source_icon" ]]; then
  echo "Source icon not found: $source_icon" >&2
  exit 1
fi

icon_tmp_dir="$(mktemp -d)"
trap 'rm -rf "$icon_tmp_dir"' EXIT

convert "$source_icon" \
  -shave 24x24 \
  -resize 1024x1024! \
  -strip \
  "$icon_tmp_dir/master.png"

convert -size 1024x1024 xc:black \
  -fill white \
  -draw "roundrectangle 0,0 1023,1023 210,210" \
  "$icon_tmp_dir/rounded-mask.png"

convert "$icon_tmp_dir/master.png" "$icon_tmp_dir/rounded-mask.png" \
  -alpha off \
  -compose CopyOpacity \
  -composite \
  "$rounded_icon"

convert "$rounded_icon" -filter Lanczos -resize 256x256! -strip \
  "$project_dir/assets/branding/finflow-icon-256.png"
convert "$rounded_icon" -filter Lanczos -resize 64x64! -strip \
  "$project_dir/assets/branding/finflow-icon-64.png"

densities=(
  "mdpi:48"
  "hdpi:72"
  "xhdpi:96"
  "xxhdpi:144"
  "xxxhdpi:192"
)

for density_and_size in "${densities[@]}"; do
  density="${density_and_size%%:*}"
  size="${density_and_size##*:}"
  destination="$project_dir/android/app/src/main/res/mipmap-$density"
  mkdir -p "$destination"
  convert "$rounded_icon" -filter Lanczos -resize "${size}x${size}!" -strip \
    "$destination/ic_launcher.png"
  cp "$destination/ic_launcher.png" "$destination/ic_launcher_round.png"
done

convert "$rounded_icon" \
  -define icon:auto-resize=256,128,64,48,32,24,16 \
  "$project_dir/windows/runner/resources/app_icon.ico"

echo "FinFlow Android and Windows icons generated successfully."
