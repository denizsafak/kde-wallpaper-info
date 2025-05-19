#!/usr/bin/env bash
set -euo pipefail

if (( $# != 1 )); then
  echo "Usage: $0 <jpeg-file>" >&2
  exit 1
fi

file=$1

# Slurp the entire file (binary-safe), then apply the three regexes in order.
perl -0777 -lne '
  # 1) <dc:title>…<rdf:li…>TITLE</rdf:li>
  if (/<dc:title>.*?<rdf:li[^>]*>([^<]+)/s) {
    print $1;
    exit
  }
  # 2) <dc:title>TITLE</dc:title>
  if (/<dc:title>\s*([^<]+?)\s*<\/dc:title>/s) {
    print $1;
    exit
  }
  # 3) XPTitle : TITLE
  if (/XPTitle\s*:\s*(.+)/) {
    print $1;
    exit
  }
' "$file"