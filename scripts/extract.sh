#!/usr/bin/env bash
# bilibili-digest: extract metadata, subtitle/transcript, comments
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: extract.sh <bilibili-url-or-bvid>" >&2
  exit 1
fi

URL="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
ensure_path
PY="$(find_python)"
HASH="$(echo -n "$URL" | md5 2>/dev/null | cut -c1-8 || echo -n "$URL" | md5sum 2>/dev/null | cut -c1-8)"
OUT="/tmp/bilibili-digest/${HASH}"
mkdir -p "$OUT"

if ! bili status >/dev/null 2>&1; then
  echo "ERROR: Not logged in. Run: bili login" >&2
  exit 1
fi

echo "Extracting to $OUT ..." >&2

bili video "$URL" --yaml > "$OUT/meta.yaml"

if "$PY" "$SCRIPT_DIR/fetch_subtitle.py" "$URL" -o "$OUT/subtitle.txt" 2>"$OUT/subtitle-meta.txt" \
   && [ -s "$OUT/subtitle.txt" ]; then
  grep -q "track:" "$OUT/subtitle-meta.txt" 2>/dev/null && cat "$OUT/subtitle-meta.txt" >&2
  echo "source=subtitle" > "$OUT/source.txt"
  echo "Using Bilibili subtitle track (UP/CC/ai-zh)." >&2
else
  echo "No subtitles; falling back to faster-whisper ASR." >&2
  rm -f "$OUT/subtitle.txt"
  mkdir -p "$OUT/audio"
  bili audio "$URL" --no-split -o "$OUT/audio/"
  M4A="$(find "$OUT/audio" -maxdepth 1 -name '*.m4a' -o -name '*.mp3' 2>/dev/null | head -1)"
  if [ -n "$M4A" ]; then
    "$PY" "$SCRIPT_DIR/transcribe.py" "$M4A" "$OUT/subtitle.txt"
  else
    bili audio "$URL" --segment 25 -o "$OUT/audio/"
    "$PY" "$SCRIPT_DIR/transcribe.py" "$OUT/audio" "$OUT/subtitle.txt"
  fi
  echo "source=faster-whisper" > "$OUT/source.txt"
fi

bili video "$URL" --comments --yaml > "$OUT/comments.yaml" 2>/dev/null || echo "comments: []" > "$OUT/comments.yaml"
bili video "$URL" --ai > "$OUT/ai-summary.txt" 2>/dev/null || true

echo "$OUT"
