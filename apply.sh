#!/bin/bash
# Copy these platform files into an AOSP tree created by the official setup guide.
set -euo pipefail
if [[ $# -ne 1 || ! -d $1/frameworks/base ]]; then
  echo "Usage: $0 /path/to/aosp" >&2
  exit 1
fi
root=$(cd "$1" && pwd)
src=$(cd "$(dirname "$0")" && pwd)
while IFS= read -r -d '' file; do
  rel=${file#"$src"/}
  mkdir -p "$root/$(dirname "$rel")"
  cp "$file" "$root/$rel"
  echo "applied $rel"
done < <(find "$src" -type f ! -path "$src/.git/*" ! -name apply.sh ! -name README.md -print0)
