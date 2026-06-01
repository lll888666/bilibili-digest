#!/usr/bin/env python3
"""Fetch Bilibili subtitles including CC / AI-generated (ai-zh) tracks from player API."""

from __future__ import annotations

import argparse
import asyncio
import sys

import aiohttp

from bili_cli.auth import get_credential
from bili_cli.client import get_video_subtitle
from bilibili_api import video

# Priority: B站自动生成 > 官方中文 > 其他含 zh 的轨道
LAN_PRIORITY = (
    "ai-zh",
    "ai-zh-hans",
    "zh-cn",
    "zh-hans",
    "zh-hant",
    "zh-hk",
)


def pick_subtitle_url(subtitles: list[dict]) -> str | None:
    if not subtitles:
        return None

    def norm(lan: str) -> str:
        return (lan or "").lower().replace("_", "-")

    by_lan = {norm(s.get("lan", "")): s.get("subtitle_url", "") for s in subtitles}

    for key in LAN_PRIORITY:
        if key in by_lan and by_lan[key]:
            return by_lan[key]

    for sub in subtitles:
        lan = norm(sub.get("lan", ""))
        if "zh" in lan or "ai" in lan:
            url = sub.get("subtitle_url", "")
            if url:
                return url

    return subtitles[0].get("subtitle_url", "") or None


async def fetch_subtitle_json(url: str) -> tuple[str, list, str]:
    """Returns (plain_text, items, track_lan)."""
    if url.startswith("//"):
        url = "https:" + url
    timeout = aiohttp.ClientTimeout(total=30)
    async with aiohttp.ClientSession(timeout=timeout) as session:
        async with session.get(url) as resp:
            resp.raise_for_status()
            data = await resp.json(content_type=None)
    body = data.get("body") or []
    texts = [item.get("content", "") for item in body]
    return "\n".join(texts), body, ""


async def fetch_best_subtitle(bvid: str) -> tuple[str, list, str]:
    """Fetch subtitle with track priority (ai-zh CC first)."""
    cred = get_credential()
    v = video.Video(bvid=bvid, credential=cred)
    pages = await v.get_pages()
    if not pages:
        return "", [], ""
    cid = pages[0].get("cid")
    if not cid:
        return "", [], ""
    player_info = await v.get_player_info(cid=cid)
    subtitles = player_info.get("subtitle", {}).get("subtitles") or []
    if not subtitles:
        return "", [], ""

    url = pick_subtitle_url(subtitles)
    if not url:
        return "", [], ""

    track_lan = next(
        (s.get("lan", "") for s in subtitles if s.get("subtitle_url") == url),
        subtitles[0].get("lan", ""),
    )
    text, items, _ = await fetch_subtitle_json(url)
    return text, items, track_lan


async def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch Bilibili subtitles (incl. CC/ai-zh)")
    parser.add_argument("bvid_or_url", help="BV id or bilibili URL")
    parser.add_argument("-o", "--output", type=str, help="Write plain text to file")
    args = parser.parse_args()

    raw = args.bvid_or_url.strip()
    bvid = raw.split("/")[-1].split("?")[0]
    if not bvid.upper().startswith("BV"):
        print(f"Error: invalid BV/URL: {raw}", file=sys.stderr)
        sys.exit(1)

    text, _items, track = await fetch_best_subtitle(bvid)
    if not text.strip():
        # Fallback to bilibili-cli default picker
        cred = get_credential()
        text, _items = await get_video_subtitle(bvid, credential=cred)
        track = track or "cli-default"

    if not text.strip():
        print("No subtitle tracks available (no UP/CC/AI subtitle in API).", file=sys.stderr)
        sys.exit(2)

    print(f"# track: {track}", file=sys.stderr)
    if args.output:
        from pathlib import Path

        Path(args.output).write_text(text, encoding="utf-8")
        print(args.output, file=sys.stderr)
    else:
        print(text)


if __name__ == "__main__":
    asyncio.run(main())
