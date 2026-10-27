#!/usr/bin/env bash
set -e
SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.config/cyberneon"
mkdir -p "$DEST" "$HOME/.config/i3"
cp "$HOME/.config/i3/config" "$HOME/.config/i3/config.bak-$(date +%s)"
cp -r "$SRC"/{palette.sh,wallpaper.sh,wallpaper.png,apply.sh,templates} "$DEST/"
chmod +x "$DEST"/*.sh
"$DEST/apply.sh"
# polybar + rofi: back up the old files, then link the generated ones
TS=$(date +%s)
mkdir -p "$HOME/.config/polybar" "$HOME/.config/rofi"
for f in "$HOME/.config/polybar/config.ini" "$HOME/.config/polybar/launch.sh" "$HOME/.config/rofi/config.rasi"; do
  [ -e "$f" ] && [ ! -L "$f" ] && cp "$f" "$f.bak-$TS"
done
ln -sf "$DEST/polybar.ini" "$HOME/.config/polybar/config.ini"
ln -sf "$DEST/polybar-launch.sh" "$HOME/.config/polybar/launch.sh"
ln -sf "$DEST/rofi-cyberneon.rasi" "$HOME/.config/rofi/cyberneon.rasi"
printf '@theme "%s"\n' "$HOME/.config/rofi/cyberneon.rasi" > "$HOME/.config/rofi/config.rasi"

# dunst: back up and link
mkdir -p "$HOME/.config/dunst"
[ -e "$HOME/.config/dunst/dunstrc" ] && [ ! -L "$HOME/.config/dunst/dunstrc" ] && cp "$HOME/.config/dunst/dunstrc" "$HOME/.config/dunst/dunstrc.bak-$TS"
ln -sf "$DEST/dunstrc" "$HOME/.config/dunst/dunstrc"

# terminals: kitty gets an include line automatically, alacritty needs one manual line
KC="$HOME/.config/kitty/kitty.conf"
if [ -f "$KC" ] && ! grep -qF "kitty-cyberneon.conf" "$KC"; then
  cp "$KC" "$KC.bak-$TS"; printf '\ninclude %s/kitty-cyberneon.conf\n' "$DEST" >> "$KC"; echo "kitty: include added"
fi

INC="include $DEST/i3-cyberneon.conf"
grep -qF "$INC" "$HOME/.config/i3/config" || printf '\n# Cyber Neon theme (keep this last so it overrides earlier colours)\n%s\n' "$INC" >> "$HOME/.config/i3/config"
echo "Alacritty users: add this at the top of ~/.config/alacritty/alacritty.toml:"
echo "  [general]"
echo "  import = [\"$DEST/alacritty-cyberneon.toml\"]"
echo "Done. Now comment out your old feh wallpaper line in ~/.config/i3/config, then press \$mod+Shift+r (restart i3)."
