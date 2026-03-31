# Platform Collection Reference

## GitHub API

Requires: `gh` CLI authenticated (`gh auth login`)

**Search repos by language (30-day new stars)**
```bash
gh api search/repositories \
  --jq '.items[:8] | .[] | "- \(.full_name) ⭐\(.stargazers_count)\n  \(.description // "无描述")"' \
  --header "Accept: application/vnd.github.v3+json" \
  -q "language:java created:>$(date -d '30 days ago' +%Y-%m-%d) sort:stars"
```

**Trending repos (all languages)**
```bash
curl -s "https://api.github.com/search/repositories?q=stars:>100+pushed:>$(date -d '7 days ago' +%Y-%m-%d)&sort=stars&order=desc&per_page=10"
```

## Dev.to

No auth needed.
```bash
curl -s "https://dev.to/api/articles?tag={TAG}&per_page=8&top=7"
# or newest:
curl -s "https://dev.to/api/articles?tag={TAG}&per_page=8&sort_by=published_at&order=desc"
```

Parse:
```python
python3 -c "import sys,json; a=json.load(sys.stdin); [print(f'- {i[\"title\"]} ❤️{i[\"public_reactions_count\"]}') for i in a[:8]]"
```

## Reddit

No auth (public endpoint).
```bash
curl -s -H "User-Agent: Mozilla/5.0" \
  "https://www.reddit.com/r/{SUBREDDIT}/hot.json?limit=8"
```

Parse:
```python
python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'- {c[\"data\"][\"title\"]}') for c in d['data']['children'][:8]]"
```

## npm Registry

No auth.
```bash
curl -s "https://registry.npmjs.org/-/v1/search?text={KEYWORD}&size=8"
```

Parse:
```python
python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'- {p[\"package\"][\"name\"]}: {p[\"package\"][\"description\"] or \"无描述\"}') for p in d.get('objects',[])[:8]]"
```

## Hacker News (Algolia API)

No auth.
```bash
curl -s "https://hn.algolia.com/api/v1/search?query={KEYWORD}&tags=story&hitsPerPage=8"
```

Parse:
```python
python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'- {h[\"title\"]}') for h in d.get('hits',[])[:8]]"
```

## 掘金 (juejin.cn)

No auth.
```bash
curl -s "https://api.juejin.cn/content_api/v1/article/list_by_tag?tag_id=1&category=1&limit=8&sort_type=7"
```

Sort types: 1=综合, 2=最新, 7=热榜

Parse:
```python
python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'- {i[\"article_info\"][\"title\"]}') for i in d.get('data',[])[:8]]"
```

## 开源中国 (oschina.net)

No auth.
```bash
curl -s "https://www.oschina.net/news/feed"
```

Parse:
```python
python3 -c "import sys,xml.etree.ElementTree as ET; d=sys.stdin.read(); root=ET.fromstring(d[d.find('<channel>'):]); [print(f'- {i.findtext(\"title\",\"\")}') for i in root.findall('.//item')[:8]]"
```

## Twitter/X (via nitter.net RSS)

No auth. Use RSS feeds:
```bash
curl -s "https://nitter.net/search?q={KEYWORD}&f=tweets"
```

Or use RSS Bridge (self-hosted) for better coverage.

## Product Hunt

Requires API token. Free tier available at producthunt.com/developers.

## Common Patterns

**Parallel collection with timeouts:**
```bash
timeout 10 curl -s "URL1" > /tmp/f1.txt &
timeout 10 curl -s "URL2" > /tmp/f2.txt &
...
for pid in $P1 $P2; do wait $pid 2>/dev/null; done
```

**Always provide fallback text:**
```bash
result=$(cat /tmp/f1.txt 2>/dev/null)
[ -z "$result" ] && result="  (数据获取超时)"
```

**JSON escape for DingTalk/webhook:**
Use `jq -n --arg` to safely embed shell variables in JSON:
```bash
PAYLOAD=$(jq -n \
  --arg kw "$KEYWORD\n$MESSAGE" \
  '{msgtype: "text", text: {content: $kw}}')
curl -X POST "$WEBHOOK" -H "Content-Type: application/json" -d "$PAYLOAD"
```
