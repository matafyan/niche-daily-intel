# Script Guide

## Overview

`multi-source-collector.sh` runs N platform collectors in parallel, each with its own timeout. Results are assembled into a formatted report and sent via webhook.

## Variables to Configure

At the top of the script, set these 4 variables:

```bash
WEBHOOK="https://oapi.dingtalk.com/robot/send?access_token=YOUR_TOKEN"
KEYWORD="your-dingtalk-robot-keyword"
NICHE="my-niche"       # appears in report title
DATE=$(date "+%Y-%m-%d")
TMP="/tmp/niche-intel"
```

## Adding a New Platform

1. Add a new `timeout XX curl ...` block in the parallel section
2. Save output to `$TMP/platform_name.txt`
3. Add `P$N=new_pid` to the wait list
4. Add a read_ block for the new platform
5. Add the section to the MESSAGE string

**Example: add a new Twitter collector**
```bash
# In parallel section:
timeout 10 curl -s "https://nitter.net/search?q=developer&f=tweets" | \
  grep -o '<a[^>]*href="/[a-zA-Z0-9_]*/status/[0-9]*"[^>]*>[^<]*</a>' | head -10 \
  > "$TMP/twitter.txt" 2>/dev/null &
P9=$!
```

## DingTalk Message Format

DingTalk text messages must:
1. Start with the exact keyword configured in the robot
2. Use `\n` for line breaks (not literal newlines in JSON)
3. Use `jq -n --arg` for safe JSON embedding

**Wrong:**
```bash
-d "{\"msgtype\":\"text\",\"text\":{\"content\":\"$KEYWORD\n$MESSAGE\"}}"
```

**Correct:**
```bash
PAYLOAD=$(jq -n \
  --arg kw "$KEYWORD\n$MESSAGE" \
  '{msgtype: "text", text: {content: $kw}}')
curl -X POST "$WEBHOOK" -H "Content-Type: application/json" -d "$PAYLOAD"
```

## Cron Schedule Format

```
┌───────────── minute (0-59)
│ ┌───────────── hour (0-23)
│ │ ┌───────────── day of month (1-31)
│ │ │ ┌───────────── month (1-12)
│ │ │ │ ┌───────────── day of week (0-6, Sunday=0)
│ │ │ │ │
│ │ │ │ │
10 6 * * *  → 6:10 AM every day
```

## Testing the Script

```bash
bash /path/to/multi-source-collector.sh
echo "Exit code: $?"
```

Expected output: `{"errcode":0,"errmsg":"ok"}`

## OpenClaw Cron Job Setup

```bash
openclaw cron add \
  --name "Niche Daily Intel" \
  --schedule "10 6 * * *" \
  --tz "Asia/Shanghai" \
  --session-target isolated \
  --message "Run /path/to/multi-source-collector.sh and verify delivery."
```

## Troubleshooting

**DingTalk errcode 40035 "缺少参数 json"**
→ JSON was malformed. Use `jq -n --arg` to build the payload safely.

**DingTalk errcode 310000 "关键词不匹配"**
→ Message doesn't start with the exact keyword configured in the robot.

**All platforms timeout**
→ Network issue. Check if the server can reach external APIs:
  ```bash
  curl -I https://api.github.com
  curl -I https://dev.to
  ```

**Parallel processes leave zombies**
→ Always add `wait $pid` for every background process, even if some timeout.
