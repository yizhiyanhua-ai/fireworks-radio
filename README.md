<div align="center">

<img src="assets/images/fireworks-radio-icon.png" alt="fireworks-radio icon" width="120" />

<br />

# fireworks-radio

**A pragmatic Codex skill for reliable coding-session audio playback.**

When `ncm-cli` fails on source rights and Spotify CLI fails on OAuth or Premium restrictions, this project falls back to `yt-dlp + mpv` and gets audio playing fast.

[中文文档](README.zh-CN.md) · [License](LICENSE) · [Legal Notes](LEGAL.md)

</div>

![fireworks-radio landing image](assets/images/fireworks-radio-landing.png)

---

## Why This Project Exists

This project came from a very unglamorous reality:

- `ncm-cli` could search tracks, but many target songs still had no playable source.
- Spotify CLI could authenticate halfway, then fail on callback behavior or return `403` because the app owner did not have an active Premium subscription.
- Even when playback worked, multiple player processes could stack and create double audio.

The core lesson was simple:

> Users do not care which audio stack is ideologically correct. They care about hearing the music now.

So this project codifies a more honest strategy:

1. Try the preferred path only briefly.
2. Stop pretending auth or rights failures are “just one more retry away.”
3. Fall back to `yt-dlp + mpv`.
4. Keep the playlist short, explicit, and stable.
5. Clean up duplicate playback processes.

## What It Actually Does

`fireworks-radio` is not trying to be a full streaming client. It is a coding-session audio fallback skill.

Its job is operational:

- recover quickly when common terminal media stacks break
- build small explicit playlists from search queries
- prefer existing public sources for all audio playback instead of generating new spoken content
- support both `stream` and `cache` playback modes
- remember lightweight listening preferences for future preset selection
- avoid duplicate player processes and overlapping audio

## One Hard-Won Lesson Added

One real failure we hit was source switching overlap: killing only the PID saved in the skill was not enough.

The reason is straightforward:

- a foreground `mpv` test may never get written to the PID file
- a later source switch may stop only the remembered background process
- the leftover foreground `mpv` keeps playing, so the user hears two streams at once

That lesson is now part of the default behavior:

- source switches do not rely only on the saved PID
- they also clear residual `mpv --no-video` processes
- the goal is not “usually no overlap”; the goal is **no overlap by default**

It can be used for:

- music
- podcasts
- interviews
- long-form technical talks
- ambient or focus audio

## Playback Modes

### `stream`

Default mode. `yt-dlp` resolves playable media URLs and `mpv` streams them directly.

Best for:

- quick listening
- stable networks
- low-friction playback

### `cache`

Downloads audio into a local cache directory first, then plays the local files.

Best for:

- unstable networks
- repeated listening
- reusable mixes
- downstream transcription or editing

## Stack

- `yt-dlp` for resolving playable media URLs from YouTube
- `mpv` for stable local playback
- shell scripts for playlist generation and lifecycle control
- a lightweight preference memory script for presets, artists, and feedback
- `SKILL.md` so Codex can use the workflow consistently

## Project Structure

```text
fireworks-radio/
├── SKILL.md
├── LICENSE
├── LEGAL.md
├── README.md
├── README.zh-CN.md
├── assets/
│   └── images/
│       ├── fireworks-radio-icon.png
│       └── fireworks-radio-landing.png
└── scripts/
    ├── build_playlist.sh
    ├── play_mix.sh
    ├── radio_memory.py
    └── stop_mix.sh
```

## Requirements

- macOS or Linux
- `yt-dlp`
- `mpv`
- network access to YouTube

## Quick Start

### 1. Build a playlist from queries

```bash
./scripts/build_playlist.sh /private/tmp/fireworks-radio.m3u \
  "萧亚轩 爱的主打歌 official" \
  "Ed Sheeran Shape of You official lyric video" \
  "Lady Gaga Bad Romance official"
```

### 2. Play it

```bash
./scripts/play_mix.sh /private/tmp/fireworks-radio.m3u
```

### 2b. Cache first, then play local files

```bash
./scripts/play_mix.sh --mode cache /private/tmp/fireworks-radio.m3u
```

### 3. Stop it

```bash
./scripts/stop_mix.sh
```

## Common Workflows

### 1. Play a hand-built short list

```bash
./scripts/build_playlist.sh /private/tmp/fireworks-radio.m3u \
  "Tycho Awake official audio" \
  "Ed Sheeran Perfect official" \
  "Lady Gaga Bad Romance official"

./scripts/play_mix.sh /private/tmp/fireworks-radio.m3u
```

### 2. Reuse the same list in cache mode

```bash
./scripts/play_mix.sh --mode cache /private/tmp/fireworks-radio.m3u
```

### 3. Use built-in presets

```bash
./scripts/play_mix.sh --preset three-artists
./scripts/play_mix.sh --preset focus-ambient
./scripts/play_mix.sh --preset coding-pop
```

### 4. Let preference memory choose

```bash
./scripts/play_mix.sh --auto
```

## General Audio Source Policy

This is not only for AI news. It is the default policy for all audio playback inside `fireworks-radio`.

Hard rules:

- use only public, currently accessible, already-published, directly playable sources
- do not synthesize a local spoken track from web content unless the user explicitly asks
- do not open a webpage just to get playback
- prefer direct playback in the current terminal window
- start with one finished source instead of stitching fake shows or fake episodes
- after one source works, confirm at least one backup source class

Allowed source types:

- public YouTube videos, audio-only playback
- public podcast RSS feeds
- direct MP3 `enclosure` links exposed by a podcast host
- free and public music sources where the work is already published and directly accessible

Default disallowed behavior:

- summarizing the web and then reading it back with local TTS
- opening a browser page and offloading playback to the user
- stitching unrelated web pages into a pretend program
- drifting into article reading, newsletter summarization, or other non-playback forms unless the user explicitly asks

### Music Source Guidance

For music, this skill may prefer free and public source classes such as:

- `ccMixter`
- `Free Music Archive`
- `Musopen`
- `Open Music Archive`

That still does not mean every track grants every downstream use. Per-track rights and platform rules still matter.

## AI News Mode

AI news is only a narrower sub-mode under the global source policy above:

- prefer public YouTube AI news videos through `mpv --no-video`
- if YouTube is unreliable, prefer public podcast RSS / MP3 `enclosure`
- if both fail, explain the failure instead of silently switching back to local synthesis

Currently verified source classes:

- `YouTube`
  good for direct `mpv --no-video` playback of public AI news videos
- `Podcast RSS / MP3 enclosure`
  for example, `The AI News Daily Brief` exposes a public RSS feed:
  `https://feeds.podcastai.com/lzSp5oGSGEaLNzHdqUBaTh.xml`

That feed already exposes direct `enclosure` audio URLs, so it works as a non-YouTube backup.

## Built-in Preset

```bash
./scripts/play_mix.sh --preset three-artists
./scripts/play_mix.sh --auto
```

Built-in presets currently include:

- `three-artists`
  Elva Hsiao / Ed Sheeran / Lady Gaga
- `focus-ambient`
  quieter instrumental and ambient listening
- `coding-pop`
  higher-energy pop for active work blocks

The `--auto` mode uses remembered preference signals to choose a preset.

## Preference Memory

`fireworks-radio` stores lightweight listening preferences so future runs can make better decisions without pretending to be a full recommendation engine.

Examples:

```bash
python3 ./scripts/radio_memory.py reinforce --preset three-artists --feedback like
python3 ./scripts/radio_memory.py reinforce --artist "Lady Gaga" --feedback like
python3 ./scripts/radio_memory.py show
```

Stored signals include:

- liked or disliked presets
- liked artists
- tags such as `coding-pop`, `focus`, or `ambient`
- play counts for presets

## Common Codex Usage

- `Use fireworks-radio to play a coding mix and fall back to YouTube if ncm-cli fails.`
- `Play existing public audio directly in the current window. Do not open a webpage.`
- `For AI news, do not synthesize anything. Play a real public source.`
- `Play a 12-track mix of Elva Hsiao, Ed Sheeran, and Lady Gaga.`
- `Choose a preset automatically from my past listening preferences.`
- `Stop the current mix and rebuild it with faster songs.`
- `Test one track first, then expand to a full playlist if playback works.`

## Design Principles

- Short feedback loops beat perfect architecture.
- Rights failures are operational facts, not bugs to deny.
- Fallbacks should be explicit and fast.
- Existing public audio is the default. Local synthesis is opt-in only.
- Test tracks must be cleaned up after validation.

## Licensing Position

This repository is **source-available**, not OSI open source.

The default software license is PolyForm Noncommercial 1.0.0. Commercial use is
not allowed without separate written permission.

This repository does not grant any rights to third-party media. If a user
chooses to stream, cache, or play content from third-party platforms, the user
is responsible for copyright and platform-term compliance.

In other words:

- `stream` and `cache` are workflow modes, not rights grants
- the repository automates playback workflows, not content licensing
