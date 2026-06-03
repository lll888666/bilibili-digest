# bilibili-digest

B 站视频一键消化：链接 → 字幕/转录 + 评论 → Cursor Agent 生成干货报告 + Mermaid 思维导图。

**零第三方 API Key** — 字幕/评论走 [bilibili-cli](https://github.com/jackwener/bilibili-cli)，无字幕时本地 [faster-whisper](https://github.com/SYSTRAN/faster-whisper) 转录。

## 功能

- 优先拉取 B 站字幕轨（UP 上传 / CC / **ai-zh 自动生成**）
- 无字幕时自动下载音频并本地 ASR 转录
- 抓取高赞评论、视频元数据
- 配合 Cursor Agent 输出结构化干货报告（含 Mermaid mindmap）

## 环境要求

- **Python 3.10+**
- 网络（拉字幕/评论/模型；转录本身离线）
- B 站登录（`bili login` 或浏览器 Cookie 自动检测）

## 安装

在仓库根目录执行：

```bash
pip3 install -r scripts/requirements.txt
# 或
bash scripts/setup.sh
```

一条命令装齐：

| 包 | 用途 |
|---|---|
| `bilibili-cli[audio]` | `bili` 命令、字幕/评论/音频、`fetch_subtitle.py` |
| `faster-whisper` | `transcribe.py` 本地语音转文字 |

然后登录 B 站：

```bash
bili login
```

验证依赖：

```bash
bash scripts/preflight.sh
```

> **不要用 `pipreqs` 自动生成 `requirements.txt`**。`bili_cli` 等 import 名与 PyPI 包名 `bilibili-cli` 不一致，容易装错无关包。详见 [references/prerequisites.md](references/prerequisites.md)。

### PyAV 编译失败

```bash
pip3 install av --only-binary :all:
pip3 install -r scripts/requirements.txt
```

### ffmpeg（可选）

无字幕走音频分支时，`bili audio` 建议配置可用的 ffmpeg CLI。有 PyAV 时可先跑通大部分流程。详见 [references/prerequisites.md](references/prerequisites.md)。

## 快速使用

```bash
# 1. 检查依赖
bash scripts/preflight.sh

# 2. 提取字幕/转录 + 评论 + 元数据
bash scripts/extract.sh "https://www.bilibili.com/video/BVxxx"
# 输出目录路径会打印到 stdout，例如 /tmp/bilibili-digest/xxxxxxxx

# 3. 在 Cursor 中让 Agent 读取输出文件，按 templates 生成报告
```

输出目录包含：

| 文件 | 内容 |
|------|------|
| `meta.yaml` | 视频元数据 |
| `subtitle.txt` | 字幕或 ASR 逐字稿 |
| `comments.yaml` | 高赞评论 |
| `source.txt` | `subtitle` 或 `faster-whisper` |

## 作为 Cursor Skill

将本仓库放到 Cursor skills 目录，或在项目中引用 `SKILL.md`：

```bash
git clone https://github.com/lll888666/bilibili-digest.git ~/.cursor/skills/bilibili-digest
```

在 Cursor 中发送 B 站链接或说「消化这个 B 站视频」，Agent 会按 [SKILL.md](SKILL.md) 工作流执行。

## 项目结构

```
bilibili-digest/
├── SKILL.md                 # Cursor Agent 指令
├── README.md
├── references/              # 安装、安全、工作流、报告模板
│   ├── prerequisites.md
│   ├── security.md
│   ├── workflow-branches.md
│   ├── subtitle-sources.md
│   └── output-template.md
└── scripts/
    ├── requirements.txt     # 直接依赖（勿 pipreqs 自动生成）
    ├── setup.sh             # 一键安装 + 可选预下载 Whisper 模型
    ├── preflight.sh         # 依赖检查
    ├── extract.sh           # 主提取流程
    ├── fetch_subtitle.py    # 字幕（含 ai-zh 优先）
    ├── transcribe.py        # faster-whisper 转录
    └── test-smoke.sh        # 冒烟测试
```

## 工作流

```
链接 → preflight.sh → extract.sh → Agent 读输出 → 按模板写报告
```

- **有字幕轨**：`fetch_subtitle.py`（优先 `ai-zh`）
- **无字幕轨**：`bili audio` → `transcribe.py`

详见 [references/workflow-branches.md](references/workflow-branches.md)。

## 不需要

- `DASHSCOPE_API_KEY` / `ANTHROPIC_API_KEY` / `OPENAI_API_KEY`（总结走 Cursor 订阅）
- XMind / ProcessOn 等导图软件（报告用 Mermaid mindmap）

## 验证

```bash
bash scripts/test-smoke.sh   # 无需登录的冒烟测试
bash scripts/preflight.sh    # 完整依赖检查
```

## 参考文档

- [prerequisites.md](references/prerequisites.md) — 安装与排错
- [security.md](references/security.md) — 登录与隐私
- [output-template.md](references/output-template.md) — 报告模板

## License

MIT（如仓库未附带 LICENSE 文件，以发布者说明为准）
