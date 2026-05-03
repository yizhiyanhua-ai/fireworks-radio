#!/usr/bin/env python3
"""Lightweight listening preference memory for fireworks-radio."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path


DEFAULT_DATA = {
    "preset_scores": {},
    "artist_scores": {},
    "tag_scores": {},
    "play_counts": {},
}

PRESET_TAGS = {
    "three-artists": ["coding-pop", "vocal", "mixed"],
    "focus-ambient": ["focus", "ambient", "instrumental"],
    "coding-pop": ["coding-pop", "vocal", "energetic"],
}


def _memory_home() -> Path:
    configured = os.environ.get("FIREWORKS_RADIO_MEMORY_HOME")
    if configured:
        return Path(os.path.expanduser(configured)).resolve()
    codex_home = os.environ.get("CODEX_HOME")
    if codex_home:
        return Path(codex_home).expanduser().resolve() / "memories" / "fireworks-radio"
    return Path.home() / ".fireworks-radio"


def _prefs_path(create: bool = False) -> Path:
    path = _memory_home() / "preferences.json"
    if create:
        path.parent.mkdir(parents=True, exist_ok=True)
    return path


def load_data() -> dict:
    path = _prefs_path(create=False)
    if not path.exists():
        return DEFAULT_DATA.copy()
    data = json.loads(path.read_text(encoding="utf-8"))
    merged = DEFAULT_DATA.copy()
    merged.update(data)
    return merged


def save_data(data: dict) -> Path:
    path = _prefs_path(create=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    return path


def _bump(bucket: dict, key: str, delta: int) -> None:
    if not key:
        return
    bucket[key] = int(bucket.get(key, 0)) + delta


def record_play(preset: str) -> Path:
    data = load_data()
    _bump(data["play_counts"], preset, 1)
    return save_data(data)


def reinforce(*, preset: str | None, artist: str | None, tag: str | None, feedback: str) -> Path:
    delta = 2 if feedback == "like" else -2
    data = load_data()
    if preset:
        _bump(data["preset_scores"], preset, delta)
        for preset_tag in PRESET_TAGS.get(preset, []):
            _bump(data["tag_scores"], preset_tag, delta)
    if artist:
        _bump(data["artist_scores"], artist, delta)
    if tag:
        _bump(data["tag_scores"], tag, delta)
    return save_data(data)


def recommend_preset() -> str:
    data = load_data()
    candidates = ["three-artists", "focus-ambient", "coding-pop"]
    best_name = "three-artists"
    best_score = -10**9
    for candidate in candidates:
        score = int(data["preset_scores"].get(candidate, 0))
        score += int(data["play_counts"].get(candidate, 0))
        for tag in PRESET_TAGS.get(candidate, []):
            score += int(data["tag_scores"].get(tag, 0))
        if score > best_score:
            best_score = score
            best_name = candidate
    return best_name


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="radio-memory")
    sub = parser.add_subparsers(dest="command", required=True)

    show = sub.add_parser("show")
    show.add_argument("--json", action="store_true")

    sub.add_parser("recommend-preset")

    play = sub.add_parser("record-play")
    play.add_argument("--preset", required=True)

    reinforce_cmd = sub.add_parser("reinforce")
    reinforce_cmd.add_argument("--preset")
    reinforce_cmd.add_argument("--artist")
    reinforce_cmd.add_argument("--tag")
    reinforce_cmd.add_argument("--feedback", choices=["like", "dislike"], required=True)

    return parser


def main() -> int:
    parser = _build_parser()
    args = parser.parse_args()

    if args.command == "show":
        data = load_data()
        if args.json:
            print(json.dumps(data, ensure_ascii=False, indent=2))
        else:
            print(f"prefs: {_prefs_path()}")
            print(json.dumps(data, ensure_ascii=False, indent=2))
        return 0

    if args.command == "recommend-preset":
        print(recommend_preset())
        return 0

    if args.command == "record-play":
        print(record_play(args.preset))
        return 0

    if args.command == "reinforce":
        print(
            reinforce(
                preset=args.preset,
                artist=args.artist,
                tag=args.tag,
                feedback=args.feedback,
            )
        )
        return 0

    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
