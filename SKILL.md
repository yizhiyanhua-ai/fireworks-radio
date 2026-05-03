---
name: fireworks-radio
description: Reliable coding-session audio fallback skill. Use when the user wants music or long-form audio during coding, when ncm-cli or Spotify CLI fails because of rights, auth, Premium, callback, or source availability issues, or when the user wants a quick YouTube + mpv mix with minimal friction.
---

# fireworks-radio

Use this skill when the user wants music or long-form audio while coding and the normal media stack is unreliable.

## Why This Exists

In practice, terminal music automation fails for boring real-world reasons:

1. `ncm-cli` can search tracks but still fail at playback because the song has no playable source.
2. Spotify CLI can fail on OAuth callbacks, stale auth state, or Premium-only API restrictions.
3. Background player processes can stack and cause double playback.
4. The user does not care about audio-stack purity. The user cares about hearing music now.

This skill treats `yt-dlp + mpv` as the reliable fallback path.

## Default Strategy

1. Check whether a current player is already running.
2. If the requested stack is `ncm-cli` or Spotify CLI, try it briefly only when there is a good reason.
3. If playback fails because of source availability, auth, Premium, callback, or rights restrictions, stop wasting time.
4. Switch to `yt-dlp + mpv`.
5. Build a short, concrete playlist from artist/title queries.
6. Decide whether the user needs `stream` mode or `cache` mode.
7. Use listening-preference memory when choosing a preset or fallback style.
8. Start playback in a real Terminal session or a stable background process.
9. Avoid duplicate processes. If there is already a test track and a playlist track, kill the test track.

## Source Policy For All Audio Playback

This rule applies to all audio playback in this skill, not only AI news.

### Hard Constraints

1. Use only publicly accessible, already-published, directly playable sources.
2. Do not synthesize a local spoken track unless the user explicitly asks for generation.
3. Do not open a webpage if direct terminal playback is possible.
4. Play inside the current terminal audio path only, typically `mpv --no-video`.
5. Prefer one concrete source that already exists over stitched or invented content.
6. After one source works, identify at least one alternative source class as backup.

### Allowed Source Types

- public YouTube videos where only audio is played
- public podcast RSS feeds with direct `enclosure` audio URLs
- public direct MP3 episode links from a podcast host
- free and public music catalogs where the track is already published and directly accessible

### Disallowed by Default

- local TTS generated from a web summary
- opening a browser page just so the user can press play there
- stitching unrelated articles into a fake “podcast episode”
- silently drifting from playback into article reading, newsletter summarization, or other non-playback forms

### Music Source Guidance

When the user wants music, prefer free and public source classes first, such as:

- Creative Commons catalogs like `ccMixter`
- open-licensed catalogs like `Free Music Archive`
- public-domain or royalty-free classical catalogs like `Musopen`
- public-domain recording archives like `Open Music Archive`

Per-track rights still matter. “Free” or “public” at the catalog level is not a blanket license claim for every downstream use.

## AI News Mode

When the user asks for AI news, apply the global source policy above and narrow it further.

### Preferred Order

1. public YouTube AI news video playable through `mpv --no-video`
2. public podcast RSS / MP3 enclosure playable directly in terminal
3. only if both fail, explain the failure clearly and ask before switching formats

## Commands

### Build a playlist

```bash
./scripts/build_playlist.sh /private/tmp/fireworks-radio.m3u \
  "萧亚轩 爱的主打歌 official" \
  "Ed Sheeran Shape of You official lyric video" \
  "Lady Gaga Bad Romance official"
```

### Play a playlist

```bash
./scripts/play_mix.sh /private/tmp/fireworks-radio.m3u
```

### Play in cache mode

```bash
./scripts/play_mix.sh --mode cache /private/tmp/fireworks-radio.m3u
```

### Stop the current mix

```bash
./scripts/stop_mix.sh
```

### One-shot preset

```bash
./scripts/play_mix.sh --preset three-artists
./scripts/play_mix.sh --auto
```

### Preference memory

```bash
python3 ./scripts/radio_memory.py reinforce --preset three-artists --feedback like
python3 ./scripts/radio_memory.py reinforce --artist "Lady Gaga" --feedback like
python3 ./scripts/radio_memory.py show
```

## Common User Requests

- `用 fireworks-radio 播一个适合编码的混播`
- `别折腾 ncm-cli 了，直接走 YouTube + mpv`
- `给我做一条 萧亚轩 / Ed Sheeran / Lady Gaga 的混播`
- `直接播今天的 AI 新闻，不要自己合成`
- `不要打开页面，直接在当前窗口播现成的 AI 新闻`
- `按我的历史偏好自动挑一个 preset`
- `停止当前混播`
- `如果 Spotify CLI 失败就自动降级`

## Operational Rules

- Prefer short playlists first: 9-15 tracks.
- Prefer official audio, lyric video, or official MV queries.
- For all audio playback, prefer an existing public source over any locally generated narration.
- For all audio playback, keep playback format narrow: direct terminal playback only, no browser detour.
- For all audio playback, always leave behind at least one backup source class after the first successful source.
- In AI news mode, prefer one finished public news source instead of assembling a synthetic recap.
- Do not promise `ncm-cli` or Spotify will work if the root problem is rights or Premium.
- Do not leave a foreground test track running after validating playback.
- Always tell the user why the fallback happened.
- Explain clearly that `stream` and `cache` are workflow modes, not media-rights permissions.
