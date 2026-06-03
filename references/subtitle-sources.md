# B 站字幕来源说明

## 播放器里能开字幕，skill 能读到吗？

**能。** 你在网页/App 里手动开启的字幕，来自播放器接口 `player_info.subtitle.subtitles` 里的轨道列表。`bilibili-digest` 通过同一接口拉取，**不是**爬页面 DOM。

常见轨道类型：

| `lan` 字段 | 含义 |
|------------|------|
| `ai-zh` | B 站 **AI 自动生成**（中文）— 无 UP 字幕时最常见 |
| `zh-CN` / `zh-Hans` | 上传字幕或翻译字幕 |
| 其他 `*zh*` | 中文相关轨道 |

脚本会 **优先选 `ai-zh`**，再试 `zh-CN`、`zh-Hans` 等。

## 什么时候仍然没有字幕？

- 视频太新，AI 字幕尚未生成
- UP 关闭字幕 / 仅会员可见
- 纯音乐、无语音内容
- 接口暂时无轨道 → 自动走 **Path B**（下载音频 + faster-whisper 本地转录）

## 与 UP 上传字幕的区别

- **UP 上传**：同样在 `subtitles` 列表里，通常 `zh-CN`
- **手选 CC/自动识别**：多为 `ai-zh`，skill 已优先抓取

## ffmpeg 是否必须？

**有字幕轨时不需要 ffmpeg。** 仅 Path B（本地 ASR）需要音频下载；`bili audio` 使用 **PyAV**，不依赖 brew 编译 ffmpeg。可选安装 `imageio-ffmpeg` 作为备用。
