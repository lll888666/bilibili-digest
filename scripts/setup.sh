#!/usr/bin/env bash
# bilibili-digest: install Python deps for local ASR
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
ensure_path
PY="$(find_python)"

"$PY" -m pip install -r "$SCRIPT_DIR/requirements.txt" || {
  echo "Retrying with PyAV binary wheel..."
  "$PY" -m pip install "av" --only-binary :all:
  "$PY" -m pip install -r "$SCRIPT_DIR/requirements.txt"
}

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg not found. Install with: brew install ffmpeg"
  echo "  or: conda install -c conda-forge ffmpeg"
fi

echo "Pre-downloading medium model (optional, ~1.5GB)..."
"$PY" -c "from faster_whisper import WhisperModel; WhisperModel('medium', device='cpu', compute_type='int8')"
echo "Setup complete."
