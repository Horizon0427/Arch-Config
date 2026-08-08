#!/bin/bash

set -o pipefail

FORTUNE_BIN=/usr/bin/fortune

[[ -x "$FORTUNE_BIN" ]] || exit 0

"$FORTUNE_BIN" -e -s -n 120 science pratchett 2>/dev/null \
    | expand -t 4 \
    | awk '
        {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "")
            if ($0 == "")
                next

            if ($0 ~ /^--[[:space:]]*/)
                in_attribution = 1
            else if (!in_attribution)
                quote = quote (quote == "" ? "" : " ") $0
        }
        END {
            if (quote != "")
                print quote
        }
    ' \
    | fold -s -w 60 \
    | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
