#!/usr/bin/env bash
# bilibili-digest: smoke tests (no login required for most checks)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS=0
FAIL=0

ok() { echo "PASS $1"; PASS=$((PASS + 1)); }
bad() { echo "FAIL $1"; FAIL=$((FAIL + 1)); }

echo "=== bilibili-digest smoke tests ==="

# 1. faster-whisper import
if python3 -c "from faster_whisper import WhisperModel" 2>/dev/null; then
  ok "faster-whisper import"
else
  bad "faster-whisper import"
fi

# 2. bili CLI
if bili --version >/dev/null 2>&1; then
  ok "bili CLI"
else
  bad "bili CLI"
fi

# 3. Public metadata (no login)
if bili video BV1GJ411x7h7 --yaml 2>/dev/null | grep -q "ok: true"; then
  ok "bili video metadata (no login)"
else
  bad "bili video metadata"
fi

# 4. extract login gate
OUT="$(bash "$SCRIPT_DIR/extract.sh" "BV1GJ411x7h7" 2>&1 || true)"
if echo "$OUT" | grep -q "bili login"; then
  ok "extract.sh login gate"
else
  bad "extract.sh login gate"
fi

# 5. transcribe.py (tiny model, silent wav)
TEST_DIR="/tmp/bilibili-digest-test"
mkdir -p "$TEST_DIR"
python3 -c "
import wave, struct
from pathlib import Path
p = Path('$TEST_DIR/seg_000.wav')
with wave.open(str(p), 'w') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(16000)
    w.writeframes(struct.pack('<h', 0) * 16000)
"
if python3 "$SCRIPT_DIR/transcribe.py" "$TEST_DIR" "$TEST_DIR/transcript.txt" --model tiny 2>/dev/null; then
  ok "transcribe.py (tiny model)"
else
  bad "transcribe.py"
fi

# 6. ffmpeg (required for Path B audio)
if command -v ffmpeg >/dev/null 2>&1 && ffmpeg -version >/dev/null 2>&1; then
  ok "ffmpeg"
else
  echo "WARN ffmpeg missing or broken — run: brew install ffmpeg (required for bili audio)"
fi

# 7. bili login (warn only)
if bili status >/dev/null 2>&1; then
  ok "bili login"
else
  echo "WARN not logged in — run: bili login (required for full extract)"
fi

echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
