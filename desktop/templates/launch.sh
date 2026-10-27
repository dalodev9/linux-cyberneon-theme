#!/usr/bin/env bash
# Start one polybar per monitor (primary gets the tray + system modules)
killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done
primary=$(xrandr --query | awk '/ primary/{print $1; exit}')
for m in $(polybar --list-monitors | cut -d: -f1); do
  if [ "$m" = "${primary:-$m}" ]; then bar=main; else bar=secondary; fi
  MONITOR=$m polybar --reload "$bar" >/tmp/polybar-"$m".log 2>&1 &
done
