---
name: niche-daily-intel
description: "Build and automate a daily intelligence report system for any vertical niche. Use when: (1) Building a \"daily newsletter\" or \"daily intelligence\" product that collects data from multiple platforms and delivers a formatted report via webhook (DingTalk/WeChat/email). (2) Creating a subscription-based niche news SaaS. (3) Automating competitor/market monitoring for a specific industry. (4) Building a \"pain point collector\" that gathers developer complaints, e-commerce trends, or industry pain points daily. Supports: GitHub Trending, Reddit, Dev.to, 掘金, Hacker News, npm, DingTalk robot, any webhook endpoint. Triggered by: daily report, niche intelligence, market monitoring, pain point collection,垂直领域日报,自动情报收集,定时推送."
---

# Niche Daily Intel

Build a fully automated daily intelligence report pipeline: collect data from configurable sources, analyze/format, deliver to any webhook (DingTalk, WeChat Work, email, etc.).

## Workflow

### Step 1: Define the Niche

Identify what domain you're building for:

| Niche | Keywords to track | Platforms |
|-------|------------------|-----------|
| Developers | vscode, npm, java, typescript, github | GitHub, Reddit, Dev.to, HN |
| E-commerce sellers | 1688, dropshipping, 淘宝客, 抖店 | 1688, 淘宝, 拼多多 |
| Parents | 儿童玩具, 早教, 母婴 | 小红书, 知乎, 淘宝 |
| Crypto | defi, nft, trading | Twitter, Reddit, CoinGecko |

### Step 2: Configure Data Sources

Each platform has a specific collection method. See [references/platforms.md](references/platforms.md) for detailed API specs.

Core platforms:

**GitHub Trending**
```bash
gh api search/repositories \
  --jq '.items[:8] | .[] | "- \(.full_name) ⭐\(.stargazers_count)\n  \(.description)"' \
  -q "language:javascript created:>$(date -d '30 days ago' +%Y-%m-%d) sort:stars"
```

**Dev.to**
```bash
curl -s "https://dev.to/api/articles?tag=javascript&per_page=8&top=7"
```

**Reddit**
```bash
curl -s -H "User-Agent: Mozilla/5.0" \
  "https://www.reddit.com/r/programming/hot.json?limit=8"
```

**npm Registry**
```bash
curl -s "https://registry.npmjs.org/-/v1/search?text=developer-tools&size=8"
```

**Hacker News (Algolia)**
```bash
curl -s "https://hn.algolia.com/api/v1/search?tags=story&hitsPerPage=8"
```

**掘金 (juejin.cn)**
```bash
curl -s "https://api.juejin.cn/content_api/v1/article/list_by_tag?tag_id=1&category=1&limit=8&sort_type=7"
```

### Step 3: Configure Delivery

Set up a DingTalk robot webhook:
1. Open DingTalk group → Group Settings → Smart Group Assistant → Add Robot → Custom
2. Copy the webhook URL and the keyword you set
3. Send message with keyword at the start: `YOUR_KEYWORD\n<MESSAGE>`

```bash
curl -X POST "$WEBHOOK" \
  -H "Content-Type: application/json" \
  -d '{"msgtype":"text","text":{"content":"'"$KEYWORD\n$MESSAGE"'"}}'
```

Alternative: use any HTTP POST webhook (Slack, Discord, custom endpoint).

### Step 4: Deploy the Pipeline

Use the provided collector script as-is or customize it. See [references/script-guide.md](references/script-guide.md).

**Quick start**: copy `scripts/multi-source-collector.sh` to your project, configure the 4 variables at the top:

```bash
WEBHOOK="https://your-webhook-here"
KEYWORD="your-dingtalk-keyword"
NICHE="developers"    # used in report header
DATE=$(date "+%Y-%m-%d")
```

### Step 5: Schedule with OpenClaw Cron

Set up a daily cron job in OpenClaw to run the collector script.

## Output Format

The daily report follows this structure:

```
🦞【{NICHE}每日情报】{DATE}

📊 {Platform Name} - {Description}
{item1}
{item2}
...

💡【今日洞察】
{One actionable insight derived from the data}

---
{niche}-intel | 每天{AUTO}推送
```

## Script Architecture

See `scripts/multi-source-collector.sh` — it runs all platform collectors in parallel with per-source timeouts. Failed sources are replaced with placeholder text so the report always sends.

Key design: **failures are silent**, no source blocks the whole report. This is critical for reliability — you always want to deliver even if one platform is down.
