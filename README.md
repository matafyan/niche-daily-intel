技能能力：

自动从 8 个平台采集数据（GitHub、Dev.to、Reddit、npm、Hacker News、掘金、开源中国）
并行抓取，单平台超时不影响整体
定时推送到钉钉/飞书/任意 webhook
任何垂直领域都能用（开发者、电商、家长……）

# niche-daily-intel

**垂直领域每日情报系统** — 自动从 8+ 平台采集数据，
AI 整理成可操作的情报报告，定时推送至钉钉/飞书/Slack。

---

## 🎯 解决什么问题？

独立开发者、内容创作者、电商卖家每天需要了解自己赛道的变化。
niche-daily-intel 把这件事自动化了 — 每天早上自动收集、自动整理、自动推送。

---

## ⚡ 能力

### 数据源（8个平台）
- GitHub Trending（Java/JS 30天新星）
- Dev.to JavaScript 热文
- npm Registry 新兴工具包
- Reddit r/programming 热帖
- Hacker News 技术讨论
- 掘金前端热帖
- 开源中国热帖

### 推送渠道
钉钉、飞书、Slack、任意 HTTP POST webhook

### 可靠性
- 8平台并行采集，单平台超时不影响整体
- 失败自动替换为友好占位符，报告总能发出

---

## 📦 安装

```bash
npx skills add niche-daily-intel
