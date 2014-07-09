#!/bin/sh

# for test
q=${1}
if [ -z "$q" ]; then
  q={query}
fi

cat <<EOF
<?xml version="1.0"?>
<items>
EOF

# check if prefix match first
files=`ls ~/.irkit.d/signals/ | grep ^${q}`
if [ -z ${files} ]; then
  files=`ls ~/.irkit.d/signals/ | grep ${q}`
fi

for file in ${files}; do
  basename=${file##*/}
  cat <<EOF
  <item arg="~/.irkit.d/signals/${file}" valid="YES" type="file">
    <title>${basename}</title>
    <subtitle>Send IR signal</subtitle>
    <icon type="fileicon">~/.irkit.d/signals/${file}</icon>
  </item>
EOF
done

cat <<EOF
</items>
EOF
