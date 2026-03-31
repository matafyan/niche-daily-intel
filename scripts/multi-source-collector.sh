#!/bin/bash
# multi-source-collector.sh - 多平台情报收集器
# 配置好顶部的4个变量即可使用

# ============ 配置区 ============
WEBHOOK="${WEBHOOK:-}"
KEYWORD="${KEYWORD:-}"
NICHE="${NICHE:-unknown}"
DATE=$(date "+%Y-%m-%d")
# ================================

if [ -z "$WEBHOOK" ] || [ -z "$KEYWORD" ]; then
  echo "错误：请设置 WEBHOOK 和 KEYWORD 环境变量"
  echo "Usage: WEBHOOK='https://...' KEYWORD='关键词' NICHE='开发者' bash collector.sh"
  exit 1
fi

TMP="/tmp/niche-intel-$$"
rm -rf "$TMP"; mkdir -p "$TMP"

echo "=== [$NICHE] 情报采集开始: $DATE ==="

# ---- 并行采集各个平台 ----
# 1. GitHub Java (30天新星)
timeout 12 gh api search/repositories \
  --jq '.items[:8] | .[] | "- \(.full_name) ⭐\(.stargazers_count)\n  \(.description // "无描述")"' \
  --header "Accept: application/vnd.github.v3+json" \
  -q "language:java created:>$(date -d '30 days ago' +%Y-%m-%d) sort:stars" \
  > "$TMP/gh_java.txt" 2>/dev/null &
P1=$!

# 2. GitHub JavaScript
timeout 12 gh api search/repositories \
  --jq '.items[:8] | .[] | "- \(.full_name) ⭐\(.stargazers_count)\n  \(.description // "无描述")"' \
  --header "Accept: application/vnd.github.v3+json" \
  -q "language:javascript created:>$(date -d '30 days ago' +%Y-%m-%d) sort:stars" \
  > "$TMP/gh_js.txt" 2>/dev/null &
P2=$!

# 3. Dev.to
timeout 10 curl -s "https://dev.to/api/articles?tag=javascript&per_page=8&top=7" | \
  python3 -c "import sys,json; a=json.load(sys.stdin); [print(f'- {i[\"title\"]} ❤️{i[\"public_reactions_count\"]}') for i in a[:8]]" \
  > "$TMP/devto.txt" 2>/dev/null &
P3=$!

# 4. npm
timeout 10 curl -s "https://registry.npmjs.org/-/v1/search?text=developer-tools&size=8" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'- {p[\"package\"][\"name\"]}: {p[\"package\"][\"description\"] or \"无描述\"}') for p in d.get('objects',[])[:8]]" \
  > "$TMP/npm.txt" 2>/dev/null &
P4=$!

# 5. Reddit r/programming
timeout 10 curl -s -H "User-Agent: Mozilla/5.0" \
  "https://www.reddit.com/r/programming/hot.json?limit=8" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'- {c[\"data\"][\"title\"]}') for c in d['data']['children'][:8]]" \
  > "$TMP/reddit.txt" 2>/dev/null &
P5=$!

# 6. 掘金
timeout 8 curl -s "https://api.juejin.cn/content_api/v1/article/list_by_tag?tag_id=1&category=1&limit=8&sort_type=7" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'- {i[\"article_info\"][\"title\"]}') for i in d.get('data',[])[:8]]" \
  > "$TMP/juejin.txt" 2>/dev/null &
P6=$!

# 7. Hacker News
timeout 10 curl -s "https://hn.algolia.com/api/v1/search?tags=story&hitsPerPage=8" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'- {h[\"title\"]}') for h in d.get('hits',[])[:8]]" \
  > "$TMP/hn.txt" 2>/dev/null &
P7=$!

# 8. 开源中国
timeout 8 curl -s "https://www.oschina.net/news/feed" 2>/dev/null | \
  python3 -c "import sys,xml.etree.ElementTree as ET; d=sys.stdin.read(); s=d.find('<channel>'); root=ET.fromstring(d[s:]); [print(f'- {i.findtext(\"title\",\"\")}') for i in root.findall('.//item')[:8]]" \
  > "$TMP/oschina.txt" 2>/dev/null &
P8=$!

# 等待所有进程
for pid in $P1 $P2 $P3 $P4 $P5 $P6 $P7 $P8; do
  wait $pid 2>/dev/null
done

# ---- 读取结果 ----
read_() { local f="$1"; cat "$f" 2>/dev/null | head -12 | sed 's/^/  /'; }
gh_java=$(read_ "$TMP/gh_java.txt")
gh_js=$(read_ "$TMP/gh_js.txt")
devto=$(read_ "$TMP/devto.txt")
npm=$(read_ "$TMP/npm.txt")
reddit=$(read_ "$TMP/reddit.txt")
juejin=$(read_ "$TMP/juejin.txt")
hn=$(read_ "$TMP/hn.txt")
oschina=$(read_ "$TMP/oschina.txt")

# 备用（平台超时时代替空白）
: "${gh_java:=  (GitHub数据获取超时)}"
: "${gh_js:=  (GitHub数据获取超时)}"
: "${devto:=  (Dev.to数据获取超时)}"
: "${npm:=  (npm数据获取超时)}"
: "${reddit:=  (Reddit数据获取超时)}"
: "${juejin:=  (掘金数据获取超时)}"
: "${hn:=  (HN数据获取超时)}"
: "${oschina:=  (开源中国数据获取超时)}"

# ---- 构造消息 ----
MESSAGE="🦞【${NICHE}每日情报】$DATE

📊 GitHub Trending Java（30天新星）
$gh_java

📊 GitHub Trending JavaScript（30天新星）
$gh_js

❤️ Dev.to JavaScript热文
$devto

📦 npm新兴工具包
$npm

🌐 Reddit r/programming热帖
$reddit

🇨🇳 掘金前端热帖
$juejin

💬 Hacker News
$hn

🇨🇳 开源中国热帖
$oschina

---
💡 发现好项目/痛点随时记

🦞 niche-intel | 每天6:10自动推送"

# ---- 发送 ----
PAYLOAD=$(jq -n \
  --arg kw "$KEYWORD\n$MESSAGE" \
  '{msgtype: "text", text: {content: $kw}}')

RESULT=$(curl -s -X POST "$WEBHOOK" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

echo "推送结果: $RESULT"
echo "完成: $(date)"
rm -rf "$TMP"