#!/usr/bin/env bash
# Cyber Neon lock screen for i3 (needs: i3lock-color, imagemagick, xorg-xrandr)
# Extra args go straight to i3lock, e.g.:  timeout 30 ~/.config/i3/lock.sh --nofork
set -u
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
SRC="$DIR/cyberneon-lock/panel.png"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cyberneon-lock"
mkdir -p "$CACHE"

# 1) Monitors -> one scaled picture per monitor, joined into one image the size of the whole X screen
mons=$(xrandr --query | grep -E ' connected' | grep -oE '[0-9]+x[0-9]+\+[0-9]+\+[0-9]+')
total=$(xrandr --query | sed -n 's/.*current \([0-9]*\) x \([0-9]*\).*/\1x\2/p' | head -1)
key=$(printf '%s %s' "$total" "$mons" | tr -c 'A-Za-z0-9\n' '_' | tr -d '\n')
OUT="$CACHE/$key.png"
if [ ! -f "$OUT" ]; then
  args=(-size "$total" canvas:'#07010f')
  for m in $mons; do
    w=${m%%x*}; rest=${m#*x}; h=${rest%%+*}; off=${rest#*+}; x=${off%%+*}; y=${off#*+}
    args+=( \( "$SRC" -resize "${w}x${h}^" -gravity center -extent "${w}x${h}" +repage \) -gravity NorthWest -geometry "+${x}+${y}" -composite )
  done
  convert "${args[@]}" "$OUT"
fi

# 2) Colours (Cyber Neon palette)
PINK=ff2a6d; CYAN=05d9e8; YEL=f9f002; TXT=d1f7ff; BG=07010f
FONT="JetBrainsMono Nerd Font"

# 3) Lock. Positions are fractions of each monitor, matched to the panel baked into panel.png
exec i3lock \
  --image="$OUT" --color=${BG} \
  --indicator --clock \
  --ind-pos="x+w*0.73:y+h*0.565" \
  --radius=$((110)) --ring-width=7 \
  --inside-color=07010fcc --insidever-color=07010fcc --insidewrong-color=07010fcc \
  --ring-color=${CYAN}ff --ringver-color=${CYAN}ff --ringwrong-color=${YEL}ff \
  --line-uses-ring --keyhl-color=${PINK}ff --bshl-color=${YEL}ff \
  --separator-color=${BG}00 \
  --verif-text="CHECKING" --wrong-text="ACCESS DENIED" --noinput-text="" --lock-text="LOCKED" --lockfailed-text="LOCK FAILED" \
  --verif-color=${CYAN}ff --wrong-color=${YEL}ff --layout-color=${TXT}ff \
  --verif-font="$FONT" --wrong-font="$FONT" --greeter-font="$FONT" \
  --verif-size=18 --wrong-size=18 \
  --time-str="%H:%M" --time-font="$FONT" --time-size=96 --time-color=${TXT}ff --time-align=1 \
  --time-pos="x+w*0.06:y+h*0.16" \
  --date-str="%A %d %B %Y" --date-font="$FONT" --date-size=22 --date-color=${PINK}ff --date-align=1 \
  --date-pos="tx:ty+40" \
  --timeoutline-color=${PINK}ff --timeoutline-width=2 \
  --greeter-text="" \
  --pass-media-keys --pass-volume-keys \
  "$@"
