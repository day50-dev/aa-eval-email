#!/bin/bash
curl -s 'https://artificialanalysis.ai/leaderboards/models' \
    | grep -Po '(?<=self.__next_f.push\(\[1,).*?(?=\]\))' \
    | grep coding_inde \
    | sed 's/^".../"/g' | head -1 \
    | jq -r 'fromjson | .[3].children[0][3].models.[] | "\(.coding_index) \(.size_class) \(.name)"' \
    | sort -n > current

date > last_run
comm -3 current old > change
if [[ -s change ]] ; then
cat change | cut -d ' ' -f 3- | tr '\n' '/' | sed 's|\/$||g' > subj
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
$(cat change)
--who-cares/nomatter--

ENDL
} | /usr/bin/msmtp aa-new-model@googlegroups.com
fi
cp current old

