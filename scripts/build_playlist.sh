#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <output.m3u> <query1> [query2 ...]" >&2
  exit 1
fi

output="$1"
shift

: > "$output"

for query in "$@"; do
  yt-dlp --print webpage_url "ytsearch1:${query}" >> "$output"
done

echo "Playlist written to $output"
