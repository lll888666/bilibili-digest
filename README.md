# bilibili-digest

**B 站视频一键消化**：粘贴链接 → 自动提取字幕/转录 + 高赞评论 → 生成结构化干货报告与 Mermaid 思维导图。

专为 [Cursor Agent Skills](https://cursor.com/docs/agent/skills) 设计，**零第三方 API Key**，字幕、语音转写、总结全部在本机或 Cursor 订阅内完成。

---

## 功能亮点

| 能力 | 说明 |
|------|------|
| 字幕提取 | 优先 UP 上传 / B 站 CC / **ai-zh 自动生成** 字幕轨 |
| 本地 ASR | 无字幕时自动下载音频，用 **faster-whisper** 离线转录（约 4–6× 于原版 Whisper） |
| 评论洞察 | 抓取高赞评论，提炼共识 / 补充 / 争议 |
| 干货报告 | 一句话总结、核心要点、资源链接、详细章节 |
| 思维导图 | 输出 **Mermaid mindmap**，Cursor 内直接渲染，无需 XMind |
| 隐私友好 | B 站凭证仅存本机，不发送给任何云端 ASR 或 LLM 服务商 |

---

## 快速开始

### 1. 安装 Skill

将本仓库克隆到 Cursor Skills 目录：

```bash
git clone https://github.com/lll888666/bilibili-digest.git ~/.cursor/skills/bilibili-digest
```

或在 Cursor 中通过 Skill 安装流程指向本仓库。

### 2. 安装依赖

```bash
# macOS 系统依赖
brew install ffmpeg pkg-config

# B 站 CLI（含音频下载）
pip3 install "bilibili-cli[audio]"

# 本地 ASR 依赖
bash ~/.cursor/skills/bilibili-digest/scripts/setup.sh

# B 站登录（浏览器已登录 B 站时可能自动读取 Cookie）
bili login
```

### 3. 验证环境

```bash
bash ~/.cursor/skills/bilibili-digest/scripts/preflight.sh
```

各项输出应为 `OK`。也可运行无需登录的冒烟测试：

```bash
bash ~/.cursor/skills/bilibili-digest/scripts/test-smoke.sh
```

### 4. 在 Cursor 中使用

在 Agent 对话中发送 B 站链接或 BV 号，例如：

- `https://www.bilibili.com/video/BVxxxxxx`
- 「总结这个 B 站视频」
- 「提取字幕并画思维导图」

Agent 会自动调用本 Skill，提取内容并生成完整报告。

---

## 手动提取（可选）

不通过 Agent，也可直接运行脚本：

```bash
bash ~/.cursor/skills/bilibili-digest/scripts/extract.sh "https://www.bilibili.com/video/BVxxx"
```

脚本会输出临时目录路径，例如 `/tmp/bilibili-digest/<hash>/`，包含：

```
/tmp/bilibili-digest/<hash>/
├── meta.yaml          # 视频元数据
├── subtitle.txt       # 字幕或逐字稿
├── source.txt         # subtitle | faster-whisper
├── comments.yaml      # 高赞评论
├── ai-summary.txt     # B 站官方 AI 摘要（可选）
└── audio/             # 仅无字幕时存在
```

---

## 工作流程

```
B 站链接
  → preflight.sh（依赖检查）
  → extract.sh（提取内容）
  → Agent 读取输出文件
  → 按模板生成干货报告 + Mermaid 思维导图
```

### 字幕 vs 转录

| 情况 | 处理方式 |
|------|----------|
| 有字幕轨（UP / CC / ai-zh） | `fetch_subtitle.py` 直接拉取，优先 ai-zh |
| API 无任何字幕轨 | `bili audio` 下载音频 → `transcribe.py` 本地 ASR |

详见 [`references/subtitle-sources.md`](references/subtitle-sources.md) 与 [`references/workflow-branches.md`](references/workflow-branches.md)。

---

## 报告输出格式

Agent 按 [`references/output-template.md`](references/output-template.md) 生成报告，包含：

- 一句话总结
- 核心干货（5–10 条）
- 详细要点（分章节）
- 优质资源与链接表格
- 高赞评论洞察（共识 / 补充 / 争议）
- Mermaid 思维导图
- 附录：信息来源说明

---

## 前置依赖

| 组件 | 用途 |
|------|------|
| [bilibili-cli](https://pypi.org/project/bilibili-cli/) | 视频元数据、字幕、评论、音频下载 |
| [faster-whisper](https://github.com/SYSTRAN/faster-whisper) | 本地中文语音转文字 |
| ffmpeg | 音频处理（`bili audio` 依赖） |
| Python 3.9+ | 运行提取与转录脚本 |

**不需要**：DashScope / OpenAI / Anthropic API Key、openai-whisper CLI、XMind 等导图软件。

完整安装说明与常见问题见 [`references/prerequisites.md`](references/prerequisites.md)。

---

## 安全与隐私

- 登录凭证存储在 `~/.bilibili-cli/credential.json`（仅本机）
- 凭证不会发送给 Anthropic、OpenAI、阿里云或 faster-whisper
- 建议使用**专用小号**登录，用完可执行 `bili logout`
- Agent 不会在对话中要求粘贴 Cookie 或凭证内容

详见 [`references/security.md`](references/security.md)。

---

## 项目结构

```
bilibili-digest/
├── SKILL.md                    # Cursor Agent Skill 主文件
├── README.md                   # 本文件
├── references/
│   ├── prerequisites.md        # 安装与验证
│   ├── security.md             # 登录与隐私
│   ├── workflow-branches.md    # 字幕 / ASR 分支逻辑
│   ├── subtitle-sources.md     # 字幕来源说明
│   └── output-template.md      # 报告输出模板
└── scripts/
    ├── preflight.sh            # 依赖检查
    ├── extract.sh              # 一键提取
    ├── setup.sh                # 安装 Python 依赖
    ├── fetch_subtitle.py       # 字幕拉取
    ├── transcribe.py           # faster-whisper 转录
    ├── test-smoke.sh           # 冒烟测试
    ├── lib.sh                  # 公共函数
    └── requirements.txt        # Python 依赖
```

---

## 常见问题

| 情况 | 处理方式 |
|------|----------|
| `bili` 未安装 | 见 [prerequisites.md](references/prerequisites.md) |
| 未登录 B 站 | 运行 `bili login` |
| `faster-whisper` 缺失 | 运行 `bash scripts/setup.sh` |
| ffmpeg 未找到 | `brew install ffmpeg`，或使用 imageio-ffmpeg 方案（见 prerequisites） |
| 无字幕且音频下载失败 | 报告会注明限制，仅基于元数据与评论 |
| 长视频转录慢 | 正常现象；`medium` 模型首次需下载约 1.5GB |

---

## 设计原则

1. **零云端 ASR 费用** — 禁止调用 DashScope、OpenAI Whisper API 等需 API Key 的服务
2. **禁止 `--task translate`** — 避免把中文字幕翻成英文
3. **总结由 Cursor Agent 完成** — 走 Cursor 订阅额度，无需额外 LLM Key
4. **Mermaid 导图** — 嵌入 Markdown，无需安装第三方导图软件

---

## 相关链接

- 仓库：[github.com/lll888666/bilibili-digest](https://github.com/lll888666/bilibili-digest)
- Cursor Skills 文档：[cursor.com/docs/agent/skills](https://cursor.com/docs/agent/skills)
