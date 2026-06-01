#!/usr/bin/env python3
"""bilibili-digest: batch transcribe Bilibili audio segments with faster-whisper."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    from faster_whisper import WhisperModel
except ImportError:
    print(
        "Error: faster-whisper not installed. Run: bash scripts/setup.sh",
        file=sys.stderr,
    )
    sys.exit(1)


def transcribe_file(
    audio_path: Path,
    out_file: Path,
    model_size: str = "medium",
) -> None:
    """Transcribe a single audio file (m4a/mp3/wav)."""
    print(f"Loading model '{model_size}'...", file=sys.stderr)
    model = WhisperModel(model_size, device="auto", compute_type="int8")
    print(f"Transcribing {audio_path.name}...", file=sys.stderr)
    segments, info = model.transcribe(
        str(audio_path),
        language="zh",
        beam_size=5,
        vad_filter=True,
        initial_prompt="以下是普通话的句子。",
    )
    text = "".join(seg.text for seg in segments).strip()
    out_file.parent.mkdir(parents=True, exist_ok=True)
    out_file.write_text(text, encoding="utf-8")
    print(
        f"Wrote {out_file} ({info.duration:.1f}s, lang={info.language})",
        file=sys.stderr,
    )


def transcribe_dir(
    audio_dir: Path,
    out_file: Path,
    model_size: str = "medium",
) -> None:
    wav_files = sorted(audio_dir.glob("seg_*.wav"))
    if not wav_files:
        wav_files = sorted(audio_dir.glob("*.wav"))
    if not wav_files:
        print(f"Error: no WAV files in {audio_dir}", file=sys.stderr)
        sys.exit(1)

    print(f"Loading model '{model_size}'...", file=sys.stderr)
    model = WhisperModel(model_size, device="auto", compute_type="int8")

    parts: list[str] = []
    for i, wav in enumerate(wav_files, 1):
        print(f"Transcribing [{i}/{len(wav_files)}] {wav.name}...", file=sys.stderr)
        segments, info = model.transcribe(
            str(wav),
            language="zh",
            beam_size=5,
            vad_filter=True,
            initial_prompt="以下是普通话的句子。",
        )
        text = "".join(seg.text for seg in segments).strip()
        if text:
            parts.append(text)
        print(
            f"  lang={info.language} prob={info.language_probability:.0%} "
            f"duration={info.duration:.1f}s",
            file=sys.stderr,
        )

    out_file.parent.mkdir(parents=True, exist_ok=True)
    out_file.write_text("\n\n".join(parts), encoding="utf-8")
    print(f"Wrote {out_file} ({len(parts)} segments)", file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser(description="Transcribe Bilibili audio with faster-whisper")
    parser.add_argument(
        "audio_input",
        type=Path,
        help="Audio file (m4a/mp3/wav) or directory of seg_*.wav",
    )
    parser.add_argument("output_file", type=Path, help="Output transcript path")
    parser.add_argument(
        "--model",
        default="medium",
        choices=["tiny", "base", "small", "medium", "large-v3"],
        help="Whisper model size (default: medium)",
    )
    args = parser.parse_args()

    if args.audio_input.is_file():
        transcribe_file(args.audio_input, args.output_file, model_size=args.model)
    elif args.audio_input.is_dir():
        transcribe_dir(args.audio_input, args.output_file, model_size=args.model)
    else:
        print(f"Error: not found: {args.audio_input}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
