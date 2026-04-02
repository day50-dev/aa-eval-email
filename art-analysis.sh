#!/bin/bash
web() {
    curl -s 'https://artificialanalysis.ai/leaderboards/models?is_open_weights=open_source&size_class=all'
}
filter() {
    grep -Po  '(?<=self.__next_f.push\(\[1,).*?(?=\]\))' \
    | grep oding | sed 's/^".../"/g' | head -1 | jq -r 'fromjson'
}
parse() {
    jq -r '
    .[3].models.[] | 
        "\(10 * (.codingIndex // 0) | round / 10 ) \( (now - (.releaseDate | strptime("%Y-%m-%d") | mktime ) )/86400 | floor) \(.sizeClass // "-") \(.name)"'  | sort -n | sed 's/ /\t/;s/ /\t/;s/ /\t/' 
}
send() {
    [[ -n "$DEBUG" ]] && cat || /usr/bin/msmtp aa-new-model@googlegroups.com
}

web | filter | parse > holding

# Make sure we got something
[[ ! -s holding ]] && exit

cp holding current
lcdiff=$(wc -l old current | awk ' { print $1 } ' | uniq | wc -l)

# If there's 2 lines here then we had 
# identical numbers of line per file
[[ $lcdiff == 2 ]] && exit

# This craziness is done because diffs are
# actually normal ... we are displaying
# days since release which naturally increment
# daily. 
# So we need to look for line number increase instead

date > last_run
diff -C 2 old current | grep -E '^[ \-\+] ' > change
if [[ -s change ]] ; then
cat change | grep -E '^\+' | cut -d ' ' -f 4- | tr '\n' '/' | sed 's|\/$||g' > subj
{
cat << ENDL
MIME-Version: 1.0
Content-Type: multipart/alternative;
 boundary="who-cares/nomatter"
From: New Model! <chris@9ol.es>
Subject: $(cat subj)

This is a MIME-encapsulated message
--who-cares/nomatter
Content-Type: text/plain

  Score Age     Size    Name
  ----- ------- ------- --------------------------------------
$(cat change)

--who-cares/nomatter--

ENDL
} | send
fi
cp current old

