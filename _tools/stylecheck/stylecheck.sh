#!/bin/bash
# Builds the StyleCheck window, shoots it in the light and dark appearance and analyzes the shots. The window prints
# its window number and the geometry of the controls. The window is shot four times 0.25 s apart: the frames show how
# the indeterminate bar moves. $1 is the directory for the shots and crops, shots next to the script by default
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
QMAKE="${QMAKE:-/usr/local/Qt-6.8.5/bin/qmake}"
APP="$HERE/StyleCheck.app/Contents/MacOS/StyleCheck"
OUT="${1:-$HERE/shots}"
mkdir -p "$OUT"

if [[ ! -f "$HERE/Makefile" ]]; then
    (cd "$HERE" && "$QMAKE" StyleCheck.pro) > "$OUT/build.log" 2>&1 || { echo "qmake failed, see $OUT/build.log"; exit 1; }
fi

make -C "$HERE" -j8 >> "$OUT/build.log" 2>&1 || { echo "build failed, see $OUT/build.log"; exit 1; }

if [[ ! -x "$HERE/scanalyze" || "$HERE/scanalyze.swift" -nt "$HERE/scanalyze" ]]; then
    swiftc -O -o "$HERE/scanalyze" "$HERE/scanalyze.swift" || exit 1
fi

for scheme in light dark; do
    LOG="$OUT/$scheme.txt"

    # a window that never became active draws the bars gray and without the focus ring, such a run is repeated
    for attempt in 1 2 3; do
        "$APP" "$scheme" > "$LOG" 2>&1 &
        PID=$!

        for _ in $(seq 1 150); do
            grep -q '^stylecheck end' "$LOG" && break
            sleep 0.1
        done

        grep -q '^stylecheck ready .* active=1' "$LOG" && break

        echo "$scheme: the window didn't become active (attempt $attempt)"
        kill "$PID"
        wait "$PID" 2>/dev/null
    done

    WIN=$(sed -n 's/^stylecheck ready window=\([0-9]*\).*/\1/p' "$LOG")

    if [[ -z "$WIN" ]] || ! kill -0 "$PID" 2>/dev/null; then
        echo "$scheme: the window didn't respond"
        kill "$PID" 2>/dev/null
        continue
    fi

    SHOTS=()
    for n in 1 2 3 4; do
        screencapture -x -o -l "$WIN" "$OUT/$scheme-$n.png"
        SHOTS+=("$OUT/$scheme-$n.png")
        sleep 0.25
    done

    kill "$PID"
    wait "$PID" 2>/dev/null

    echo "===== $scheme"
    grep '^stylecheck ready' "$LOG"
    "$HERE/scanalyze" "$LOG" "$OUT/$scheme" "${SHOTS[@]}"
done
