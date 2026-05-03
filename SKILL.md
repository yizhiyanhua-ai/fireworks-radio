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
- `按我的历史偏好自动挑一个 preset`
- `停止当前混播`
- `如果 Spotify CLI 失败就自动降级`

## Operational Rules

- Prefer short playlists first: 9-15 tracks.
- Prefer official audio, lyric video, or official MV queries.
- Do not promise `ncm-cli` or Spotify will work if the root problem is rights or Premium.
- Do not leave a foreground test track running after validating playback.
- Always tell the user why the fallback happened.
- Explain clearly that `stream` and `cache` are workflow modes, not media-rights permissions.
