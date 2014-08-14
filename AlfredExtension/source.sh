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

IFS_BACKUP=${IFS}
IFS=$'\n';

# check if prefix match first
files=(`ls ~/.irkit.d/signals/ | grep "^${q}"`)
if [ ${#files[@]} == 0 ]; then
  files=(`ls ~/.irkit.d/signals/ | grep "${q}"`)
fi

for file in "${files[@]}"; do
  basename=${file##*/}
  cat <<EOF
  <item arg="~/.irkit.d/signals/${file}" valid="YES" type="file">
    <title>${basename}</title>
    <subtitle>Send IR signal</subtitle>
    <icon type="fileicon">~/.irkit.d/signals/${file}</icon>
  </item>
EOF
done

IFS=${IFS_BACKUP}

cat <<EOF
</items>
EOF
