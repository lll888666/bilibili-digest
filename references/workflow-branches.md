# 工作流分支

## 路径 A：有字幕（优先）

```bash
bili video "$URL" --subtitle > "$OUT/subtitle.txt"
```

成功且文件非空 → `source=subtitle`，跳过 ASR。

## 路径 B：无字幕（faster-whisper）

```bash
bili audio "$URL" --segment 25 -o "$OUT/audio/"
python3 scripts/transcribe.py "$OUT/audio/" "$OUT/subtitle.txt"
```

- 音频切成 25 秒 WAV 片段，便于转录与恢复
- `transcribe.py` 使用 `language=zh`、`vad_filter=True`
- 模型默认 `medium`；可通过 `--model small` 加速

## 公共步骤（两条路径之后）

```bash
bili video "$URL" --yaml > "$OUT/meta.yaml"
bili video "$URL" --comments --yaml > "$OUT/comments.yaml"
bili video "$URL" --ai > "$OUT/ai-summary.txt" 2>/dev/null || true
```

`--ai` 为 B 站官方摘要，作补充参考，非必须。

## Agent 总结

读取 `$OUT/` 下文件，按 output-template 生成报告。Mermaid mindmap 嵌入报告，Cursor 内直接渲染。

## 输出目录结构

```
/tmp/bilibili-digest/<hash>/
├── meta.yaml
├── subtitle.txt
├── source.txt          # subtitle | faster-whisper
├── comments.yaml
├── ai-summary.txt      # 可选
└── audio/              # 仅路径 B
    └── seg_*.wav
```
