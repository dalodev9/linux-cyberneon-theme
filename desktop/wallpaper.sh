#!/usr/bin/env bash
# Sets the Cyber Neon wallpaper, scaled to each monitor (needs feh, imagemagick, xrandr)
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cyberneon-wall"; mkdir -p "$CACHE"
mons=$(xrandr --query | grep -E ' connected' | grep -oE '[0-9]+x[0-9]+\+[0-9]+\+[0-9]+')
total=$(xrandr --query | sed -n 's/.*current \([0-9]*\) x \([0-9]*\).*/\1x\2/p' | head -1)
key=$(printf '%s %s' "$total" "$mons" | tr -c 'A-Za-z0-9\n' '_' | tr -d '\n')
OUT="$CACHE/$key.png"
if [ ! -f "$OUT" ]; then
  args=(-size "$total" canvas:'#07010f')
  for m in $mons; do
    w=${m%%x*}; rest=${m#*x}; h=${rest%%+*}; off=${rest#*+}; x=${off%%+*}; y=${off#*+}
    args+=( \( "$DIR/wallpaper.png" -resize "${w}x${h}^" -gravity center -extent "${w}x${h}" +repage \) -gravity NorthWest -geometry "+${x}+${y}" -composite )
  done
  convert "${args[@]}" "$OUT"
fi
exec feh --no-fehbg --bg-tile "$OUT"
