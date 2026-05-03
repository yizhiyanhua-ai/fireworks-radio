#!/usr/bin/env bash
set -euo pipefail

PID_FILE="/private/tmp/fireworks-radio.pid"

cleanup_existing_players() {
  if [[ -f "$PID_FILE" ]]; then
    pid="$(cat "$PID_FILE" || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      sleep 1
      kill -9 "$pid" 2>/dev/null || true
      echo "Stopped mix PID $pid"
    else
      echo "Stored PID is not running."
    fi
    rm -f "$PID_FILE"
  else
    echo "No PID file found."
  fi

  pkill -f "mpv --no-video" 2>/dev/null || true
  sleep 1
  pkill -9 -f "mpv --no-video" 2>/dev/null || true
}

cleanup_existing_players
