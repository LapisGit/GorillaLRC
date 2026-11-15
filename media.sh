#!/bin/sh

OUT_DIR="${1:-$HOME/.cache/GorillaLRC}"
OUT="$OUT_DIR/media.txt"
TMP="$OUT.tmp"
PIDFILE="${OUT%.txt}.pid"

mkdir -p "$OUT_DIR"

if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
fi
echo $$ > "$PIDFILE"

BIN=""
for c in playerctl /run/host/usr/bin/playerctl; do
    if command -v "$c" >/dev/null 2>&1; then BIN="$c"; break; fi
done

if [ -z "$BIN" ]; then
    echo "playerctl-missing" > "$OUT"
    exit 1
fi

if ! "$BIN" --version >/dev/null 2>&1; then
    BIN="/run/host/usr/lib/ld-linux-x86-64.so.2 --library-path /run/host/usr/lib64:/run/host/usr/lib /run/host/usr/bin/playerctl"
fi

FORMAT='{{playerInstance}}|{{status}}|{{title}}|{{artist}}|{{mpris:length}}|{{position}}'

while :; do
    $BIN metadata --all-players --format "$FORMAT" > "$TMP" 2>/dev/null || : > "$TMP"
    mv -f "$TMP" "$OUT"
    sleep 0.5
done
