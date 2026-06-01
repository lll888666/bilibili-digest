#!/usr/bin/env bash
# bilibili-digest: check dependencies before extraction
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
ensure_path
PY="$(find_python)"

check() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "OK   $name"
    return 0
  else
    echo "FAIL $name"
    return 1
  fi
}

failed=0

check "bili" bili --version || failed=1

if command -v ffmpeg >/dev/null 2>&1 && ffmpeg -version >/dev/null 2>&1; then
  echo "OK   ffmpeg (optional, Path B audio)"
elif "$PY" -c "import av" 2>/dev/null; then
  echo "OK   PyAV (Path B uses bili audio + faster-whisper, no ffmpeg CLI required)"
else
  echo "FAIL PyAV (pip install av --only-binary :all:)"
  failed=1
fi

check "python3" python3 --version || failed=1

if "$PY" -c "from faster_whisper import WhisperModel" 2>/dev/null; then
  echo "OK   faster-whisper ($PY)"
else
  echo "FAIL faster-whisper (run: bash scripts/setup.sh)"
  failed=1
fi

if bili status >/dev/null 2>&1; then
  echo "OK   bili login"
else
  echo "WARN bili login (run: bili login — required for subtitles/comments/audio)"
fi

if [ "$failed" -eq 0 ]; then
  echo "All required dependencies OK."
  exit 0
else
  echo "Missing dependencies. See references/prerequisites.md"
  exit 1
fi
