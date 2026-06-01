---
name: bilibili-digest
description: >-
  解析 B 站视频并生成干货报告：提取字幕或本地 faster-whisper 转录、抓取高赞评论、
  总结要点、提取资源链接、输出 Mermaid 思维导图。零第三方 API Key。
  当用户提供 bilibili.com 链接、BV 号，或说「总结这个 B 站视频」「B 站干货」
  「视频逐字稿」「消化 B 站视频」时必须使用本 skill。
---

# bilibili-digest

B 站视频一键消化：链接 → 字幕/转录 + 评论 → 完整干货报告 + Mermaid 思维导图。

## Quick Start

1. 运行前置检查：`bash scripts/preflight.sh`
2. 若未登录 B 站：`bili login`（或依赖浏览器已有 Cookie，见 [security.md](references/security.md)）
3. 提取内容：`bash scripts/extract.sh "https://www.bilibili.com/video/BVxxx"`
4. 读取输出目录中的 `meta.yaml`、`subtitle.txt`、`comments.yaml`
5. 按 [output-template.md](references/output-template.md) 生成完整报告（含 Mermaid mindmap）

## 触发场景

- 用户提供 B 站 URL 或 BV 号
- 「总结/消化/提炼这个 B 站视频」
- 「提取字幕」「高赞评论」「画思维导图」

## 工作流

```
链接 → preflight.sh → extract.sh → 读输出文件 → 按模板写报告
```

分支逻辑详见 [workflow-branches.md](references/workflow-branches.md)：

- **有字幕轨**（含 UP 上传 / B 站 CC / **ai-zh 自动生成**）：`scripts/fetch_subtitle.py`（优先 ai-zh）
- **API 无任何字幕轨**：`bili audio` → `scripts/transcribe.py`（faster-whisper 本地 ASR）

详见 [subtitle-sources.md](references/subtitle-sources.md)。

## Agent 规则

1. **禁止**要求用户在聊天中粘贴 Cookie、凭证或 `credential.json` 内容
2. **禁止**调用需第三方 API Key 的云端 ASR（DashScope、OpenAI Whisper API 等）
3. **禁止**使用 `--task translate`（会把中文翻成英文）
4. 总结、校对、导图由 **Cursor Agent** 完成（走订阅额度，无需 ANTHROPIC_API_KEY）
5. 思维导图用 **Mermaid mindmap 代码块**，无需安装 XMind 等软件
6. 若 `bili status` 失败，提示用户运行 `bili login`，不要绕过登录拉字幕/评论

## 输出

必须使用 [output-template.md](references/output-template.md) 完整版结构，包含：

- 一句话总结、核心干货、详细要点
- 优质资源表格
- 高赞评论洞察（共识 / 补充 / 争议）
- Mermaid mindmap
- 附录：信息来源（subtitle / faster-whisper）

## 错误处理

| 情况 | 动作 |
|------|------|
| `bili` 未安装 | 见 [prerequisites.md](references/prerequisites.md) |
| 未登录 | 提示 `bili login` |
| `faster-whisper` 缺失 | 运行 `bash scripts/setup.sh` |
| 无字幕且音频下载失败 | 报告注明限制，仅基于元数据与评论（若有） |
| 长视频转录慢 | 正常；可告知用户 medium 模型首次需下载约 1.5GB |

## 参考文档

- [prerequisites.md](references/prerequisites.md) — 安装与验证
- [security.md](references/security.md) — 登录与隐私
- [workflow-branches.md](references/workflow-branches.md) — 分支细节
- [subtitle-sources.md](references/subtitle-sources.md) — CC / ai-zh 字幕说明
- [output-template.md](references/output-template.md) — 报告模板

## 验证

```bash
bash scripts/test-smoke.sh   # 无需登录的冒烟测试
bash scripts/preflight.sh    # 完整依赖检查
```
