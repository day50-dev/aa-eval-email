#!/bin/bash
web() {
    curl 'https://artificialanalysis.ai/leaderboards/models?is_open_weights=open_source&size_class=all'
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
    ) \(.name)"' | sort -n | sed 's/ /\t/;s/ /\t/;s/ /\t/'
}

touch -d "24 hours ago" /tmp/marke
[[ "/tmp/art-web" -nt /tmp/marker ]] || web  > /tmp/art-web 

filter 	< /tmp/art-web 	> /tmp/art-filter 
parse 	< /tmp/art-filter 
