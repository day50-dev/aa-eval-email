#!/bin/bash
#. .env
web() {
    curl -s 'https://artificialanalysis.ai/leaderboards/models?is_open_weights=open_source&size_class=all'
}
filter() {
    grep -Po  '(?<=self.__next_f.push\(\[1,).*?(?=\]\))' | grep oding | sed 's/^..../"/g' | tail -1 | jq -r 'fromjson'
}
parse() {
    jq -r '.[3].children[0][3].models.[] |
     "\(
        10 * (.codingIndex // 0) | round / 10
    ) \(
      (
        now - (
        .releaseDate |
          try ( strptime("%Y-%m-%d") | mktime )
          catch (now + 86400)
      ) ) / 86400 | floor
    ) \(.sizeClass // "-"
    ) \({"true":"open ", "false":"     "}[(.isOpenWeights | tostring)]
    ) \(.name)"' | {
      [[ -z "$arg" ]] && sort -n || sort -rn
    } | sed 's/ /\t/;s/ /\t/;s/ /\t/'
}

arg=$1
touch -d "2 hours ago" "/tmp/art-marker"
[[ -s "/tmp/art-web" && "/tmp/art-web" -nt "/tmp/art-marker" ]] || web > "/tmp/art-web"

filter 	< /tmp/art-web 	> /tmp/art-filter 
parse 	< /tmp/art-filter 
