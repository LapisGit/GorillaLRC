#!/bin/bash

OUT_DIR="${1:-$HOME/.cache/GorillaLRC}"
PIDFILE="$OUT_DIR/media.pid"
PORT="${2:?missing stream port}"

mkdir -p "$OUT_DIR"

if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
fi
echo $$ > "$PIDFILE"

PLAYERCTL=()
for c in playerctl /run/host/usr/bin/playerctl; do
    if command -v "$c" >/dev/null 2>&1; then BIN="$c"; break; fi
done

if [ -z "$BIN" ]; then
    while ! exec 3<>"/dev/tcp/127.0.0.1/$PORT"; do sleep 1; done
    printf 'playerctl-missing\n\n' >&3
    exit 1
fi

PLAYERCTL=("$BIN")
if ! "${PLAYERCTL[@]}" --version >/dev/null 2>&1; then
    PLAYERCTL=(/run/host/usr/lib/ld-linux-x86-64.so.2 --library-path /run/host/usr/lib64:/run/host/usr/lib /run/host/usr/bin/playerctl)
fi

FORMAT='{{playerInstance}}|{{status}}|{{title}}|{{artist}}|{{mpris:length}}|{{position}}'

while ! exec 3<>"/dev/tcp/127.0.0.1/$PORT"; do sleep 1; done

while :; do
    snapshot=$("${PLAYERCTL[@]}" metadata --all-players --format "$FORMAT" 2>/dev/null || true)
    if ! printf '%s\n\n' "$snapshot" >&3; then
        exec 3>&-
        while ! exec 3<>"/dev/tcp/127.0.0.1/$PORT"; do sleep 1; done
    fi
    sleep 0.5
done
