# ✨ Caelestia Themes

*[Leer en español](README.es.md)*

Series and movie themes for [Caelestia](https://github.com/caelestia-dots/shell) on Arch Linux + Hyprland.
Each theme changes the **boot and shutdown animation**, the **sounds**, the **terminal greeting**, the **Caelestia GIFs** and the **wallpapers**,
and a single command switches between themes or back to the original Caelestia.

```fish
theme list             # installed themes
theme gravity-falls    # 🌲🔺 Caelestia Falls
theme ngnl-zero        # 🎲♟️ Caelestia Zero
theme default          # ✨ original Caelestia
```

## Themes

### 🌲🔺 Caelestia Falls — *Gravity Falls*

| Moment | |
|---|---|
| 🎩 Boot | Grunkle Stan appears in a flash in front of the Mystery Shack and stays on the *"MYSTERY HACK"* sign with `YRVMEVMRWL HGZMULIW` |
| 👋 Shutdown | The sign with `SZHGZ OFVTL HGZMOVB` |
| 🔺 Login | Bill Cipher's reversed whisper from the end of the intro |
| 🖥️ Terminal | *Caelestia Falls* title, a **cryptogram of the day** (Atbash, Caesar +3 or A1Z26; `decode` shows the solution) and Bill's silhouette |
| 🎞️ GIFs | Grunkle Stan with his sunglasses in the session menu and the campfire band in the dashboard player |
| 🖼️ Wallpapers | ~44 from Wallhaven |

Video needed: the official *Gravity Falls Opening Theme Song* (~39 s).

### 🎲♟️ Caelestia Zero — *No Game No Life Zero*

| Moment | |
|---|---|
| 🎬 Boot | A hand in the dark → Riku → Disboard's red sky, with **【 ゲーム開始 】** · *let the game begin* |
| 🔮 Shutdown | The crystal cave, with **【 ASCHENTE 】** · *I swear by the pledges* |
| 🔊 Sounds | 「ゲームを始めよう」 on login and 「アッシェンテ」 on shutdown or reboot |
| 🖥️ Terminal | *Caelestia Zero* title, **the Ten Pledges of Disboard** (one per day) and a chess king |
| 🎞️ GIFs | Schwi opening her eyes in the session menu and Riku with Schwi in the dashboard player |
| 🖼️ Wallpapers | Schwi wallpapers from Wallhaven |

Video needed: the official KADOKAWAanime PV「映画『ノーゲーム・ノーライフ ゼロ』 PV 第2弾」(~90 s, 1080p).

Everything follows Caelestia's colours: when you change the wallpaper, the logo and the terminal change colour too.

> The on-screen texts and quotes of the current themes are in Spanish.

## Requirements

- Arch Linux with [Caelestia](https://github.com/caelestia-dots/caelestia) (shell + CLI) and the `fish` shell.
- **Your own copy of each theme's video.** This repository **does not include** frames, audio or wallpapers:
  the installer generates them on your machine from the video and downloads the wallpapers.
- For the animations: Plymouth with its `mkinitcpio` hook and `quiet splash` on the kernel command line (the installer warns you if something is missing).
- Optional: [`realesrgan-ncnn-vulkan-bin`](https://aur.archlinux.org/packages/realesrgan-ncnn-vulkan-bin) to enhance the animations with AI.

## Installation

```fish
git clone https://github.com/CMarinBenavides/caelestia-themes
cd caelestia-themes
./install.sh gravity-falls "~/Downloads/Gravity Falls - Opening Theme Song.mp4"
./install.sh ngnl-zero "~/Downloads/NGNL Zero PV2.mp4"
```

Options: `--no-plymouth`, `--no-wallpapers`, `--no-activate` and `--reuse` (skip generation if the assets already exist).

Switching themes rebuilds the boot image (asks for `sudo`). To switch only the terminal and wallpapers: `theme <name> --no-plymouth`.

Other commands: `decode` (solution of the encoded quote) and `theme-sound` (mute or unmute the theme sounds, handy for meetings).
To use your own GIFs, put `session.gif` and/or `media.gif` in `~/.config/caelestia-themes/gifs/<theme>/`.
Set `CAELESTIA_THEMES_NO_AI=1` to skip Real-ESRGAN, and `CAELESTIA_THEMES_VOLUME` (default `0.2`) for the sound volume.

## Creating a new theme

Each theme is a folder in `themes/<name>/`:

| File | Purpose |
|---|---|
| `theme.conf` | Name, emoji, expected video length, FPS, logo size, quotes mode (`cipher` or `plain`), wallpaper folder |
| `generate.sh` | Receives the video and a folder, and creates `plymouth/boot-*.png` (and optional `off-*.png`), `message.png`, `message-goodbye.png`, `logo-mask.png`, `login.ogg`, and optionally `shutdown.ogg`, `session.gif` and `media.gif` (the Caelestia session menu and dashboard player GIFs; `make_gif` creates them). It can use the helpers in `engine/lib.sh` |
| `banner.txt` | Terminal title (ASCII art) |
| `quotes.txt` | One quote per line; a different one each day |
| `wallpapers.txt` | [Wallhaven](https://wallhaven.cc) IDs |

The shared engine (`engine/`) takes care of Plymouth, the fish greeting, the sounds and the wallpapers.
Code comments are in Spanish.

## Uninstall

```fish
./uninstall.sh            # everything
./uninstall.sh ngnl-zero  # a single theme
```

## Credits

- *Gravity Falls* © Disney, created by Alex Hirsch.
- *No Game No Life Zero* © Yuu Kamiya, KADOKAWA / NGNL Zero Production Committee.
- Fan project not affiliated with the owners of these works; no material from the series is distributed.
- Wallpapers: their authors on [Wallhaven](https://wallhaven.cc), downloaded from there during installation.
- [Caelestia](https://github.com/caelestia-dots) by soramane and contributors.

The code in this repository is licensed under the MIT license.
