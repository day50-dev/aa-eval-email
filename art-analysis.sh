#!/bin/bash
[[ -r .env ]] && source .env
web() {
    curl -X GET https://artificialanalysis.ai/api/v2/data/llms/models \
          -H "x-api-key: $KEY"
}
filter() {
    grep -Po  '(?<=self.__next_f.push\(\[1,).*?(?=\]\))' | grep oding | sed 's/^..../"/g' | tail -1 | jq -r 'fromjson'
}
parse() {
    jq -r '.data.[] |
     "\(
        10 * (.evaluations.artificial_analysis_coding_index // 0) | round / 10
    ) \(
      (
        now - (
        .release_date |
          try ( strptime("%Y-%m-%d") | mktime )
          catch (now + 86400)
      ) ) / 86400 | floor
    ) \(.sizeClass // "-"
    ) \(.name)"' | {
      [[ -z "$arg" ]] && sort -n || sort -rn
    } | sed 's/ /\t/;s/ /\t/;s/ /\t/'
}

arg=$1
touch -d "2 hours ago" "/tmp/art-marker"
[[ -s "/tmp/art-web" && "/tmp/art-web" -nt "/tmp/art-marker" ]] || web > "/tmp/art-web"

#filter 	< /tmp/art-web 	> /tmp/art-filter 
parse 	< /tmp/art-web
