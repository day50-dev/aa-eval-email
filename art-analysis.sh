#!/bin/bash
# art-analysis.sh — model leaderboard from Artificial Analysis
# https://artificialanalysis.ai (attribution required by their free-API terms)
#
# Two sources:
#  1. official free Data API (primary — model list, scores, release dates):
#       GET https://artificialanalysis.ai/api/v2/language/models/free
#       header: x-api-key (free key: artificialanalysis.ai -> API key management)
#       free tier: 100 requests / 24 h, so responses are cached for 2 hours
#  2. the public leaderboard page (CritPt coding score, size class,
#     open-weights — none of which the free API returns; exact parameter
#     counts are Pro-only):
#       GET https://artificialanalysis.ai/leaderboards/models
#     this part is best-effort: if the page changes, Score shows 0 and
#     Size shows "-", but the model list, dates and names keep working
#
# Setup: put your key in .env (next to this script):
#   AA_API_KEY=...
#
# Output columns (tab separated): Score, Days, Size, Name
#   Score = AA CritPt coding benchmark x 100 (0 when not scored yet)
#   Days  = days since release_date (-1 when the API has no release date)
#   Size  = paramClass from the page: tiny/small/medium/large (- when unknown)
#   Name  = prefixed "open  " when the page marks it as open weights
#
# Usage: art-analysis.sh            -> scores ascending
#        art-analysis.sh <anything> -> scores descending

set -uo pipefail
cd "$(dirname "$0")"
[[ -f .env ]] && . .env
AA_API_KEY="${AA_API_KEY:-${KEY:-}}"
: "${AA_API_KEY:?AA_API_KEY missing --- put 'AA_API_KEY=...' in .env (free key from artificialanalysis.ai)}"

BASE="https://artificialanalysis.ai/api/v2/language/models/free"
LEADERBOARD="https://artificialanalysis.ai/leaderboards/models"
CACHE="/tmp/aa-models.json"
WEB="/tmp/aa-web"
PAGE="/tmp/aa-page.json"
MARKER="/tmp/aa-marker"
arg=${1:-}

fetch_all() {
    local page=1 merged
    merged=$(mktemp)
    while :; do
        curl -sf --max-time 60 -H "x-api-key: $AA_API_KEY" "$BASE?page=$page" > /tmp/aa-api-page.json \
            || { rm -f "$merged" /tmp/aa-api-page.json; return 1; }
        jq -c '.data[]' /tmp/aa-api-page.json >> "$merged"
        [[ "$(jq -r '.pagination.has_more // false' /tmp/aa-api-page.json)" == "true" ]] || break
        page=$(( page + 1 ))
        sleep 1
    done
    jq -s '.' "$merged" > "$CACHE"
    rm -f "$merged"
}

# pull size class + open-weights + family release dates out of the page's
# Next.js payload; join key is the model name (identical on both sides)
parse_page() {
    python3 - "$WEB" "$PAGE" <<'PYEOF'
import json, re, sys
src, dst = sys.argv[1], sys.argv[2]
html = open(src, encoding='utf-8').read()
chunks = re.findall(r'self\.__next_f\.push\(\[1,\s*"((?:[^"\\]|\\.)*)"\]\)', html)
blob = ""
for c in chunks:
    try:
        blob += json.loads('"' + c + '"')
    except Exception:
        pass

dec = json.JSONDecoder()
def find_array(key):
    i = blob.find('"%s":[' % key)
    if i < 0:
        return []
    val, _ = dec.raw_decode(blob, i + len('"%s":' % key))
    return val

models = find_array('initialModels')
releases = find_array('releases')
dates = {r['slug']: r.get('releaseDate') for r in releases if r.get('releaseDate')}
out = [{
    'name': m['name'],
    'open': bool(m.get('isOpenWeights')),
    'size': m.get('paramClass') or '-',
    'critpt': (m.get('scores') or {}).get('critpt'),
    'date': dates.get((m.get('release') or {}).get('slug')),
} for m in models]
json.dump(out, open(dst, 'w'))
PYEOF
}

parse() {
    jq -r --slurpfile page "$PAGE" '
      ($page[0] | map({(.name): .}) | add // {}) as $meta |
      .[] |
      ($meta[.name] // {size: "-", open: false, critpt: null}) as $m |
      [
        ( if $m.critpt != null then 1000 * $m.critpt | round / 10 else 0 end ),
        ( ( now - ( .release_date
            | try ( strptime("%Y-%m-%d") | mktime )
            catch ( now + 86400 ) ) ) / 86400 | floor ),
        ($m.size // "-"),
        ( if $m.open then "open " else "     " end + " " + .name )
      ] | @tsv' | {
      [[ -z "$arg" ]] && sort -n || sort -rn
    }
}

touch -d "2 hours ago" "$MARKER"
if [[ ! -s "$CACHE" || ! "$CACHE" -nt "$MARKER" ]]; then
    fetch_all || {
        [[ -s "$CACHE" ]] || { echo "art-analysis: API fetch failed and no cached data" >&2; exit 1; }
        echo "art-analysis: API fetch failed, using stale cache" >&2
    }
fi

if [[ ! -s "$WEB" || ! "$WEB" -nt "$MARKER" ]]; then
    curl -sf --max-time 60 "$LEADERBOARD" > "$WEB" || { rm -f "$WEB"; echo "art-analysis: leaderboard page fetch failed, Size will be '-'" >&2; }
fi
if [[ -s "$WEB" ]]; then
    parse_page || { rm -f "$PAGE"; echo "art-analysis: page parse failed, Size will be '-'" >&2; }
fi
[[ -s "$PAGE" ]] || echo '[]' > "$PAGE"

parse < "$CACHE"
