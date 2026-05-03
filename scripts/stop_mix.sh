#!/usr/bin/env bash
set -euo pipefail

PID_FILE="/private/tmp/fireworks-radio.pid"

if [[ ! -f "$PID_FILE" ]]; then
  echo "No PID file found."
  exit 0
fi

pid="$(cat "$PID_FILE" || true)"
if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
  kill "$pid"
  echo "Stopped mix PID $pid"
else
  echo "Stored PID is not running."
fi

rm -f "$PID_FILE"
