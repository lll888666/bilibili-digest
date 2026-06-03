# 安全与隐私

## 登录机制

`bilibili-cli` 认证方式（二选一）：

1. **浏览器 Cookie 自动检测**（Chrome / Firefox / Edge / Brave）— 浏览器已登录 B 站时可能无需扫码
2. **`bili login` 扫码** — 手机 B 站 App 确认

凭证存储：`~/.bilibili-cli/credential.json`（仅本机）

## 数据流向

```
B 站 API ← bili CLI（本机凭证）→ 字幕 / 评论 / 音频
音频文件 → faster-whisper（本机离线）→ 逐字稿
逐字稿 + 评论 → Cursor Agent → 干货报告
```

凭证**不会**发送给 Anthropic、OpenAI、阿里云或 faster-whisper。

## 风险与缓解

| 风险 | 缓解 |
|------|------|
| 凭证文件被本机程序读取 | `chmod 600 ~/.bilibili-cli/credential.json` |
| 会话 token 泄露 | 使用**专用小号**登录，不用主号 |
| 不想持久化登录 | 用完执行 `bili logout` |
| Agent 对话泄露 Cookie | skill 禁止在聊天中粘贴 Cookie / 凭证 |

## 必须登录的操作

字幕提取、评论、音频下载均需登录。无法完全绕过而不损失功能。

## Agent 禁止事项

- 禁止打印、上传或要求用户提供 `credential.json` 内容
- 禁止将 B 站凭证写入 skill 仓库或日志文件
