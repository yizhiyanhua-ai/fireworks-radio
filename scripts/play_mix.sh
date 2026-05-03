#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLAYLIST_DEFAULT="/private/tmp/fireworks-radio.m3u"
PID_FILE="/private/tmp/fireworks-radio.pid"
CACHE_DIR_DEFAULT="/private/tmp/fireworks-radio-cache"
MODE="stream"

build_focus_ambient() {
  "$ROOT_DIR/scripts/build_playlist.sh" "$PLAYLIST_DEFAULT" \
    "Tycho Awake official audio" \
    "Kiasmos Looped official audio" \
    "Nils Frahm Says official audio" \
    "Olafur Arnalds Near Light official audio" \
    "C418 Sweden official audio" \
    "Biosphere Kobresia official audio"
}

build_coding_pop() {
  "$ROOT_DIR/scripts/build_playlist.sh" "$PLAYLIST_DEFAULT" \
    "Dua Lipa Houdini official audio" \
    "The Weeknd Blinding Lights official audio" \
    "Ed Sheeran Shivers official" \
    "Lady Gaga Poker Face official" \
    "Bruno Mars Treasure official audio" \
    "Charlie Puth Attention official audio"
}

build_three_artists() {
  "$ROOT_DIR/scripts/build_playlist.sh" "$PLAYLIST_DEFAULT" \
    "萧亚轩 爱的主打歌 official" \
    "萧亚轩 潇洒小姐 official" \
    "萧亚轩 突然想起你 official" \
    "萧亚轩 遗失的心跳 official" \
    "Ed Sheeran Shape of You official lyric video" \
    "Ed Sheeran Perfect official" \
    "Ed Sheeran Thinking Out Loud official" \
    "Ed Sheeran Shivers official" \
    "Lady Gaga Poker Face official" \
    "Lady Gaga Bad Romance official" \
    "Lady Gaga Paparazzi official" \
    "Lady Gaga Always Remember Us This Way official"
}

cache_dir="$CACHE_DIR_DEFAULT"
preset=""
auto=0
playlist=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --preset)
      preset="${2:-}"
      shift 2
      ;;
    --auto)
      auto=1
      shift
      ;;
    --mode)
      MODE="${2:-stream}"
      shift 2
      ;;
    --cache-dir)
      cache_dir="${2:-$CACHE_DIR_DEFAULT}"
      shift 2
      ;;
    *)
      playlist="${1:-}"
      shift
      ;;
  esac
done

if [[ "$auto" -eq 1 ]]; then
  preset="$(python3 "$ROOT_DIR/scripts/radio_memory.py" recommend-preset)"
fi

if [[ -n "$preset" ]]; then
  case "$preset" in
    three-artists) build_three_artists ;;
    focus-ambient) build_focus_ambient ;;
    coding-pop) build_coding_pop ;;
    *)
      echo "Unknown preset: $preset" >&2
      exit 1
      ;;
  esac
  playlist="$PLAYLIST_DEFAULT"
fi

if [[ -z "$playlist" ]]; then
  echo "Usage: $0 <playlist.m3u> | $0 --preset <name> | $0 --auto [--mode stream|cache]" >&2
  exit 1
fi

if [[ -f "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE" || true)"
  if [[ -n "${old_pid}" ]] && kill -0 "$old_pid" 2>/dev/null; then
    kill "$old_pid" 2>/dev/null || true
  fi
fi

if [[ "$MODE" == "cache" ]]; then
  mkdir -p "$cache_dir"
  local_playlist="$cache_dir/playlist.m3u"
  : > "$local_playlist"
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    yt-dlp \
      --extract-audio \
      --audio-format mp3 \
      --audio-quality 0 \
      --output "$cache_dir/%(title)s.%(ext)s" \
      "$url"
  done < "$playlist"
  find "$cache_dir" -maxdepth 1 -type f \( -name "*.mp3" -o -name "*.m4a" -o -name "*.webm" -o -name "*.opus" \) | sort > "$local_playlist"
  playlist="$local_playlist"
fi

nohup mpv --no-video --playlist="$playlist" >/private/tmp/fireworks-radio.log 2>&1 &
echo $! > "$PID_FILE"
if [[ -n "$preset" ]]; then
  python3 "$ROOT_DIR/scripts/radio_memory.py" record-play --preset "$preset" >/dev/null 2>&1 || true
fi
echo "Started mix with PID $(cat "$PID_FILE")"
