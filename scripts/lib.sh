#!/usr/bin/env bash
# Shared helpers for bilibili-digest scripts

find_python() {
  if [ -n "${BILIBILI_DIGEST_PYTHON:-}" ]; then
    echo "$BILIBILI_DIGEST_PYTHON"
    return
  fi
  local candidates=(python3)
  [ -x /opt/anaconda3/bin/python3 ] && candidates=(/opt/anaconda3/bin/python3 "${candidates[@]}")
  [ -x /opt/homebrew/bin/python3 ] && candidates+=("/opt/homebrew/bin/python3")
  local p
  for p in "${candidates[@]}"; do
    if command -v "$p" >/dev/null 2>&1 && "$p" -c "from faster_whisper import WhisperModel" 2>/dev/null; then
      echo "$p"
      return
    fi
  done
  echo python3
}

ensure_path() {
  export PATH="${HOME}/.local/bin:/opt/homebrew/bin:/opt/anaconda3/bin:${PATH}"
}
