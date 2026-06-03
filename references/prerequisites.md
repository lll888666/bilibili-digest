# 前置依赖

## 一次性安装

需要 **Python 3.10+**。在 skill 目录下执行：

```bash
# 1. Python 依赖（一条命令装齐：bili CLI + 字幕 API + 本地 ASR + PyAV）
pip3 install -r scripts/requirements.txt
# 或: bash scripts/setup.sh

# 2. B 站登录
bili login
# 若浏览器已登录 B 站，bilibili-cli 可能自动读取 Cookie，可跳过扫码
```

`requirements.txt` 只列**直接依赖**（2 个包），子依赖由 pip 自动解析。请勿用 `pipreqs` 自动生成——`bili_cli` 等 import 名与 PyPI 包名不一致，容易装错。

可选：若走无字幕视频的音频转录分支，还需要可用的 **ffmpeg CLI**（见下文「ffmpeg 未安装或损坏」）。有 PyAV 时可先跑通大部分流程；`bili audio` 仍建议配置 ffmpeg。

隔离安装（与 pip 二选一）：

```bash
uv tool install "bilibili-cli[audio]"
pip3 install faster-whisper>=1.2.1
```

## 验证

```bash
bash scripts/preflight.sh
```

预期输出各项均为 `OK`。

## 可选：预下载 Whisper 模型

首次转录会自动下载 `medium` 模型（约 1.5GB）。可提前下载：

```bash
python3 -c "from faster_whisper import WhisperModel; WhisperModel('medium', device='cpu', compute_type='int8')"
```

## 不需要

- `DASHSCOPE_API_KEY` / `ANTHROPIC_API_KEY` / `OPENAI_API_KEY`
- `bilibili-subtitle` skill
- openai-whisper CLI
- XMind / ProcessOn 等导图软件

## PyAV 构建失败

若 `pip install -r scripts/requirements.txt` 报 `pkg-config is required for building PyAV`：

```bash
# 优先：预编译 wheel（无需 brew）
pip3 install av --only-binary :all:
pip3 install -r scripts/requirements.txt

# 或先装系统依赖再 pip
brew install ffmpeg pkg-config
pip3 install -r scripts/requirements.txt
```

## ffmpeg 未安装或损坏

`bili audio` 依赖可正常运行的 ffmpeg CLI。

### 方式 A：快速安装（推荐，无需 brew 编译 x265）

```bash
pip3 install imageio-ffmpeg
mkdir -p ~/.local/bin
ln -sf "$(python3 -c 'import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())')" ~/.local/bin/ffmpeg
export PATH="$HOME/.local/bin:$PATH"
ffmpeg -version
```

### 方式 B：Homebrew（macOS 13 上可能卡在 x265 编译 30–60+ 分钟）

```bash
brew install ffmpeg
export PATH="/opt/homebrew/bin:$PATH"
```

若 brew 长时间停在 `cmake ... x265 ... TryCompile`，可 **Ctrl+C** 改用方式 A。

若 `which ffmpeg` 有输出但 `ffmpeg -version` 崩溃（conda 缺 `libmp3lame`），不要用 conda 的 ffmpeg，改用方式 A 或 B。

建议将 PATH 写入 `~/.zshrc`：

```bash
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
```
