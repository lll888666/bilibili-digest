# 前置依赖

## 一次性安装

```bash
# 1. 系统依赖（macOS）
brew install ffmpeg pkg-config

# 2. B 站 CLI（含音频下载）
pip3 install "bilibili-cli[audio]"
# 或: uv tool install "bilibili-cli[audio]"

# 3. 本地 ASR（完全免费，无 API Key）
pip3 install -r ~/.cursor/skills/bilibili-digest/scripts/requirements.txt
# 或: bash ~/.cursor/skills/bilibili-digest/scripts/setup.sh

# 4. B 站登录
bili login
# 若浏览器已登录 B 站，bilibili-cli 可能自动读取 Cookie，可跳过扫码
```

## 验证

```bash
bash ~/.cursor/skills/bilibili-digest/scripts/preflight.sh
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

若 `pip install bilibili-cli[audio]` 报 `pkg-config is required for building PyAV`：

```bash
# 优先：预编译 wheel（无需 brew）
pip3 install av --only-binary :all:
pip3 install "bilibili-cli[audio]"

# 或先装系统依赖再 pip
brew install ffmpeg pkg-config
pip3 install "bilibili-cli[audio]"
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
