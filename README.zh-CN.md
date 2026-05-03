<div align="center">

<img src="assets/images/fireworks-radio-icon.png" alt="fireworks-radio icon" width="120" />

<br />

# fireworks-radio

**一个很务实的 Codex 音频播放 skill。**

当 `ncm-cli` 被版权/音源卡死、Spotify CLI 被 OAuth 或 Premium 限制卡死时，它直接降级到 `yt-dlp + mpv`，目标只有一个：**别再修播放器，先把声音播出来。**

[English](README.md) · [License](LICENSE) · [法律边界](LEGAL.md)

</div>

![fireworks-radio landing image](assets/images/fireworks-radio-landing.png)

---

## 为什么要做这个项目

这不是“做一个更优雅的音乐播放器”，而是把一次非常典型的真实世界翻车过程沉淀下来。

当时碰到的问题很现实：

1. `ncm-cli` 能搜到歌，但很多歌一播就报“暂无音源或暂无播放权限”。
2. Spotify CLI 的 OAuth 回调、缓存状态、Premium 限制会把链路搞得很脆。
3. 测试播放和正式混播如果同时活着，会直接变成双声道灾难。
4. 用户真正关心的不是“你用了哪个 CLI”，而是“我现在能不能听到歌”。

所以这个 skill 的核心思路不是继续嘴硬，而是：

1. 首选链路能试就试。
2. 一旦确认是版权、Premium、回调、音源可用性问题，就别再浪费时间。
3. 直接切到 `yt-dlp + mpv`。
4. 用明确的搜索词拼一个短清单。
5. 把重复播放进程收掉，只留一条真的在播的链路。

## 它到底能做什么

`fireworks-radio` 不是一个通用流媒体客户端，而是一个面向编码场景的终端音频 fallback skill。它重点解决的不是“音乐从哪来”，而是“当常见 CLI 链路不稳定时，怎么尽快恢复到可听状态”。

它现在能做这些事：

- 播放音乐、播客、访谈、技术分享、环境音等可听内容
- 把 `yt-dlp + mpv` 当成稳定降级链路
- 根据搜索词快速拼一条短播放清单
- 提供 `stream` 和 `cache` 两种播放模式
- 记住一层用户收听偏好，用于下次自动选 preset
- 清理重复播放器进程，避免测试单曲和正式混播叠音

## 两种播放模式

### `stream`

默认模式。  
`yt-dlp` 负责解析可播放地址，`mpv` 直接流式播放，不必先完整下载到本地。

适合：

- 临时听
- 网络稳定
- 想尽快开始播放

### `cache`

先把音频拉到本地缓存目录，再用 `mpv` 播本地文件。

适合：

- 网络不稳
- 想反复听同一批内容
- 想把一条混播固化下来
- 后面可能还要做转录、剪辑、摘要

## 技术栈

- `yt-dlp`：从 YouTube 解析可播放资源
- `mpv`：稳定本地播放
- Shell 脚本：生成清单、启动播放、停止播放
- 偏好记忆脚本：记录 preset / 艺人 / 标签反馈
- `SKILL.md`：让 Codex 在后续会话里稳定复用同一套方法

## 目录结构

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

## 环境要求

- macOS / Linux
- 已安装 `yt-dlp`
- 已安装 `mpv`
- 能访问 YouTube

## 快速开始

### 1. 根据搜索词生成播放清单

```bash
./scripts/build_playlist.sh /private/tmp/fireworks-radio.m3u \
  "萧亚轩 爱的主打歌 official" \
  "Ed Sheeran Shape of You official lyric video" \
  "Lady Gaga Bad Romance official"
```

### 2. 开始播放

```bash
./scripts/play_mix.sh /private/tmp/fireworks-radio.m3u
```

### 2b. 先缓存再播放

```bash
./scripts/play_mix.sh --mode cache /private/tmp/fireworks-radio.m3u
```

### 3. 停止播放

```bash
./scripts/stop_mix.sh
```

## 常见用法

### 1. 直接播放一条临时清单

```bash
./scripts/build_playlist.sh /private/tmp/fireworks-radio.m3u \
  "Tycho Awake official audio" \
  "Ed Sheeran Perfect official" \
  "Lady Gaga Bad Romance official"

./scripts/play_mix.sh /private/tmp/fireworks-radio.m3u
```

### 2. 同一条清单改成缓存模式

```bash
./scripts/play_mix.sh --mode cache /private/tmp/fireworks-radio.m3u
```

### 3. 直接用内置 preset

```bash
./scripts/play_mix.sh --preset three-artists
./scripts/play_mix.sh --preset focus-ambient
./scripts/play_mix.sh --preset coding-pop
```

### 4. 让它按历史偏好自动选

```bash
./scripts/play_mix.sh --auto
```

## 内置预设

```bash
./scripts/play_mix.sh --preset three-artists
./scripts/play_mix.sh --auto
```

当前内置的 preset 包括：

- `three-artists`
  萧亚轩 / Ed Sheeran / Lady Gaga 的流行混播
- `focus-ambient`
  更安静、更偏专注的器乐 / ambient
- `coding-pop`
  更提神、更偏节奏感的流行向混播

`--auto` 会根据已经沉淀下来的偏好信号自动挑 preset。

## 用户收听偏好记忆

`fireworks-radio` 可以记住一层轻量偏好，用于后续自动决策。

比如：

```bash
python3 ./scripts/radio_memory.py reinforce --preset three-artists --feedback like
python3 ./scripts/radio_memory.py reinforce --artist "Lady Gaga" --feedback like
python3 ./scripts/radio_memory.py show
```

它会逐步沉淀这些信息：

- 哪些 preset 你更常选
- 哪些艺人你明确偏好
- 哪些标签更适合你当前工作
- 哪些预设只是播过，哪些是明确喜欢

这层记忆目前是轻量的，不做复杂推荐系统。它的目标不是“猜你所有口味”，而是减少重复手动选 preset。

## 这个 skill 更适合什么场景

- `用 fireworks-radio 播一个适合编码的混播`
- `如果 ncm-cli 失败，就直接降级到 YouTube + mpv`
- `给我做一条 12 首的 萧亚轩 / Ed Sheeran / Lady Gaga 混播`
- `按我的历史偏好自动挑一个更适合的 preset`
- `先试播 1 首，确认有声后再扩成完整歌单`
- `停止当前混播，改成更提神的版本`

尤其适合下面这种情况：

- 你不是在做“音乐工程”，只是想赶紧进入工作状态
- 你已经知道常见音乐 CLI 真实环境里经常翻车
- 你更在乎闭环，而不是播放器路线纯不纯

## 设计原则

- 短反馈回路比“完美架构”更重要
- 版权和 Premium 限制不是错觉，是现实约束
- 降级策略必须明确，不能靠无限重试碰运气
- 试听链路必须在验证后清理，不能遗留双开进程

## 授权边界

这个仓库更准确地说是 **source-available**，不是严格意义上的 OSI 开源。

默认软件许可采用 PolyForm Noncommercial 1.0.0，不允许未经单独书面授权的商业使用。

更关键的是，这个仓库**不授予任何第三方媒体内容的版权或传播权**。用户如果用它去抓取、缓存、播放第三方内容，相关合规责任由用户自己承担，而不是从本仓库获得任何隐含授权。

换句话说：

- `stream` / `cache` 是工作模式，不是版权许可
- 仓库提供的是自动化能力，不是媒体授权
