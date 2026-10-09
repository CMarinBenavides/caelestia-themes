#!/bin/bash
# Caelestia Themes — instalador
# Usage: ./install.sh <theme> "/path/to/video.mp4" [--no-plymouth] [--no-wallpapers] [--no-activate] [--reuse]
#   Themes: gravity-falls, ngnl-zero  (see the themes/ folder)
#   --reuse: do not regenerate the assets if they already exist
#
# Los recursos (animación, logo y sonidos) se generan en tu equipo a partir de TU copia del vídeo.
# Este repositorio no incluye material con derechos de autor.
set -euo pipefail

REPO=$(cd "$(dirname "$0")" && pwd)
CONF=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-themes
SHARE=${XDG_DATA_HOME:-$HOME/.local/share}/caelestia-themes
BIN=$HOME/.local/bin
CAEL=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia
FF=${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch
MARK_BEGIN="caelestia-themes >>>"
MARK_END="caelestia-themes <<<"

THEME=""; VIDEO=""; NO_PLY=0; NO_WALL=0; NO_ACT=0; REUSE=0
for a in "$@"; do
    case "$a" in
        --no-plymouth) NO_PLY=1 ;;
        --no-wallpapers) NO_WALL=1 ;;
        --no-activate) NO_ACT=1 ;;
        --reuse) REUSE=1 ;;
        -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
        *) if [ -z "$THEME" ]; then THEME=$a; else VIDEO=$a; fi ;;
    esac
done

say() { printf '\n\e[1;38;5;16m==>\e[0m %s\n' "$*"; }
source "$REPO/engine/lib.sh"

[ -n "$THEME" ] || { echo "Available themes:"; ls "$REPO/themes"; echo; sed -n '3p' "$0"; exit 1; }
TDIR="$REPO/themes/$THEME"
[ -f "$TDIR/theme.conf" ] || die "Theme '$THEME' does not exist. Available: $(ls "$REPO/themes" | tr '\n' ' ')"
# shellcheck source=/dev/null
source "$TDIR/theme.conf"
DEST="$SHARE/$THEME"
PLY_NAME="caelestia-$THEME"

# ---------------------------------------------------------------- 1. Dependencias
say "Checking dependencies"
[ -d "$CAEL" ] || die "Caelestia config not found in $CAEL."
need=(ffmpeg imagemagick python fastfetch pipewire curl ${DEPENDENCIES:-})
[ $NO_PLY = 1 ] || need+=(plymouth)
missing=()
for p in "${need[@]}"; do pacman -Q "$p" &>/dev/null || missing+=("$p"); done
if [ ${#missing[@]} -gt 0 ]; then
    info "Missing: ${missing[*]}"
    sudo pacman -S --needed "${missing[@]}"
fi
command -v realesrgan-ncnn-vulkan >/dev/null && info "Real-ESRGAN found: frames will be enhanced." \
    || info "Tip: install realesrgan-ncnn-vulkan-bin (AUR) to enhance the animation quality."

# ---------------------------------------------------------------- 2. Migración de versiones anteriores
# 2a. "Caelestia Falls" (primera versión, solo Gravity Falls)
OLD_FALLS=${XDG_DATA_HOME:-$HOME/.local/share}/caelestia-falls
if [ -d "$OLD_FALLS" ] || grep -qs 'caelestia-falls >>>' "$CAEL/user-config.fish" "$CAEL/hypr-user.lua"; then
    say "Migrating the old Caelestia Falls install"
    for f in "$CAEL/user-config.fish" "$CAEL/hypr-user.lua"; do
        [ -f "$f" ] && sed -i '/caelestia-falls >>>/,/caelestia-falls <<</d' "$f"
    done
    mkdir -p "$SHARE/gravity-falls"
    [ -d "$OLD_FALLS/wallpapers" ] && [ ! -d "$SHARE/gravity-falls/wallpapers" ] && mv "$OLD_FALLS/wallpapers" "$SHARE/gravity-falls/wallpapers"
    rm -rf "$OLD_FALLS" "${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-falls" "$FF/gravity-falls.jsonc" ~/.cache/fastfetch-bill.ansi
    rm -f "$BIN"/{criptograma,bill-logo,caelestia-falls-sonido}
    if [ -d /usr/share/plymouth/themes/gravity-falls ]; then
        grep -q '^Theme=gravity-falls' /etc/plymouth/plymouthd.conf && sudo sed -i 's/^Theme=gravity-falls/Theme=bgrt/' /etc/plymouth/plymouthd.conf
        sudo rm -rf /usr/share/plymouth/themes/gravity-falls
    fi
fi
# 2b. "Caelestia Temas" (versión con nombres en español)
OLD_CONF=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-temas
OLD_SHARE=${XDG_DATA_HOME:-$HOME/.local/share}/caelestia-temas
if [ -d "$OLD_SHARE" ] || [ -d "$OLD_CONF" ] || grep -qs 'caelestia-temas >>>' "$CAEL/user-config.fish" "$CAEL/hypr-user.lua"; then
    say "Migrating the previous install (Caelestia Temas → Caelestia Themes)"
    for f in "$CAEL/user-config.fish" "$CAEL/hypr-user.lua"; do
        [ -f "$f" ] && sed -i '/caelestia-temas >>>/,/caelestia-temas <<</d' "$f"
    done
    mkdir -p "$SHARE" "$CONF"
    if [ -d "$OLD_SHARE" ]; then
        for d in "$OLD_SHARE"/*/; do
            [ -d "$d" ] || continue
            id=$(basename "$d")
            [ -e "$SHARE/$id" ] || mv "$d" "$SHARE/$id"
            t="$SHARE/$id"
            # Nombres de archivo en inglés
            [ -f "$t/entrada.ogg" ] && mv "$t/entrada.ogg" "$t/login.ogg"
            [ -f "$t/apagado.ogg" ] && mv "$t/apagado.ogg" "$t/shutdown.ogg"
            [ -f "$t/plymouth/mensaje.png" ] && mv "$t/plymouth/mensaje.png" "$t/plymouth/message.png"
            [ -f "$t/plymouth/mensaje-adios.png" ] && mv "$t/plymouth/mensaje-adios.png" "$t/plymouth/message-goodbye.png"
            rm -f "$t/tema.conf" "$t/frases.txt" "$t"/plymouth/caelestia-*.script "$t"/plymouth/caelestia-*.plymouth
        done
        rm -rf "$OLD_SHARE"
    fi
    [ -f "$OLD_CONF/activo" ] && [ ! -f "$CONF/active" ] && cp "$OLD_CONF/activo" "$CONF/active"
    [ -e "$OLD_CONF/sin-sonido" ] && touch "$CONF/muted"
    rm -rf "$OLD_CONF" "$FF/caelestia-temas.jsonc" ~/.cache/fastfetch-tema-logo.ansi*
    rm -f "$BIN"/{tema,tema-frase,tema-logo,tema-sonido}
    systemctl --user disable --now tema-apagado.service >/dev/null 2>&1 || true
    rm -f ~/.config/systemd/user/tema-apagado.service
fi

# ---------------------------------------------------------------- 3. Vídeo y recursos
say "Generating the assets for $NAME"
mkdir -p "$DEST"
if [ $REUSE = 1 ] && [ -f "$DEST/boot_frames" ] && [ -d "$DEST/plymouth" ]; then
    info "Reusing the assets already generated in $DEST"
else
    if [ -z "$VIDEO" ]; then
        echo "  I need $VIDEO_HINT."
        read -rp "  Video path: " VIDEO
    fi
    VIDEO=${VIDEO/#\~/$HOME}
    [ -f "$VIDEO" ] || die "Video not found: $VIDEO"
    DUR=$(duration "$VIDEO")
    python3 -I -c "import sys; lo, hi = map(float, sys.argv[2].split('-')); sys.exit(0 if lo <= float(sys.argv[1]) <= hi else 1)" "$DUR" "$VIDEO_DURATION" \
        || die "The video is ${DUR%.*} s long; expected $VIDEO_HINT."
    info "Video: $(basename "$VIDEO") (${DUR%.*} s)"
    rm -rf "$DEST/plymouth"
    bash "$TDIR/generate.sh" "$VIDEO" "$DEST"
fi
cp "$TDIR/theme.conf" "$DEST/"
for f in banner.txt quotes.txt; do [ -f "$TDIR/$f" ] && cp "$TDIR/$f" "$DEST/"; done

# Plymouth: script común con los valores del tema
BOOT_FRAMES=$(cat "$DEST/boot_frames"); OFF_FRAMES=$(cat "$DEST/off_frames" 2>/dev/null || echo 0)
MSG_FRAME=$(cat "$DEST/msg_frame")
sed -e "s/@BOOT_FRAMES@/$BOOT_FRAMES/" -e "s/@OFF_FRAMES@/$OFF_FRAMES/" -e "s/@FPS@/$FPS/" -e "s/@MSG_FRAME@/$MSG_FRAME/" \
    "$REPO/engine/plymouth.script" > "$DEST/plymouth/$PLY_NAME.script"
printf '[Plymouth Theme]\nName=%s\nDescription=%s\nModuleName=script\n\n[script]\nImageDir=/usr/share/plymouth/themes/%s\nScriptFile=/usr/share/plymouth/themes/%s/%s.script\n' \
    "$NAME" "$DESCRIPTION" "$PLY_NAME" "$PLY_NAME" "$PLY_NAME" > "$DEST/plymouth/$PLY_NAME.plymouth"
info "Animation: $BOOT_FRAMES boot frames, $OFF_FRAMES shutdown frames ($(du -sh "$DEST/plymouth" | cut -f1))."

# ---------------------------------------------------------------- 4. Comandos y configuración
say "Installing the theme engine"
mkdir -p "$BIN" "$CONF" ~/.config/systemd/user
install -m 755 "$REPO"/bin/{theme,theme-quote,theme-logo,theme-play} "$BIN/"
install -m 644 "$REPO/engine/fish.fish" "$CONF/fish.fish"

# Añade un bloque marcado a un archivo de configuración (solo una vez)
add_block() {  # archivo, prefijo de comentario, contenido
    local file=$1 c=$2 body=$3
    touch "$file"
    grep -q "$MARK_BEGIN" "$file" || printf '\n%s %s\n%s\n%s %s\n' "$c" "$MARK_BEGIN" "$body" "$c" "$MARK_END" >> "$file"
}
add_block "$CAEL/user-config.fish" "#" \
    'test -f ~/.config/caelestia-themes/fish.fish; and source ~/.config/caelestia-themes/fish.fish'
add_block "$CAEL/hypr-user.lua" "--" \
    'hl.on("hyprland.start", function() hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/theme-play login") end)'

install -m 644 "$REPO/engine/theme-shutdown.service" ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable theme-shutdown.service >/dev/null 2>&1 && systemctl --user restart theme-shutdown.service || true

# fastfetch: copia de tu configuración con el logo del tema
python3 -I - "$FF/config.jsonc" "$FF/caelestia-themes.jsonc" <<'PY'
import re, sys
src, dst = sys.argv[1:3]
try:
    t = open(src).read()
except OSError:
    t = '{\n    "logo": null,\n    "modules": ["kernel", "uptime", "shell", "memory", "packages", "os"]\n}\n'
logo = '"logo": {\n        "type": "file-raw",\n        "source": "~/.cache/fastfetch-theme-logo.ansi",\n        "padding": { "top": 1, "left": 4, "right": 4 }\n    },'
if re.search(r'"logo":\s*null,', t):
    t = re.sub(r'"logo":\s*null,', logo, t, count=1)
elif re.search(r'"logo":\s*\{.*?\n    \},', t, re.S):
    t = re.sub(r'"logo":\s*\{.*?\n    \},', logo, t, count=1, flags=re.S)
else:
    t = t.replace("{", "{\n    " + logo, 1)
open(dst, "w").write(t)
PY
info "Commands in $BIN, fish greeting, login/shutdown sounds and fastfetch configured."

# ---------------------------------------------------------------- 5. Wallpapers
if [ $NO_WALL = 0 ] && [ -f "$TDIR/wallpapers.txt" ]; then
    say "Downloading wallpapers from Wallhaven"
    WALLDIR=$(python3 -I -c 'import json,os,sys
try: print(os.path.expanduser(json.load(open(sys.argv[1]))["paths"]["wallpaperDir"]))
except Exception: print(os.path.expanduser("~/Pictures/Wallpapers"))' "$CAEL/shell.json")
    WD="$DEST/wallpapers"
    [ -d "$WALLDIR/$WALLPAPER_FOLDER" ] && WD="$WALLDIR/$WALLPAPER_FOLDER"
    mkdir -p "$WD"; ok=0
    while read -r id; do
        [ -n "$id" ] || continue
        ls "$WD"/wallhaven-"$id".* &>/dev/null && { ok=$((ok + 1)); continue; }
        url=$(curl -sf "https://wallhaven.cc/api/v1/w/$id" | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["data"]["path"])' 2>/dev/null) || continue
        curl -sfL -o "$WD/$(basename "$url")" "$url" && ok=$((ok + 1))
        sleep 1.5
    done < "$TDIR/wallpapers.txt"
    info "$ok wallpapers in $WD"
fi

# ---------------------------------------------------------------- 6. Plymouth
if [ $NO_PLY = 0 ]; then
    say "Installing the boot animation (asks for sudo)"
    sudo rm -rf "/usr/share/plymouth/themes/$PLY_NAME"
    sudo install -d "/usr/share/plymouth/themes/$PLY_NAME"
    sudo install -m 644 "$DEST"/plymouth/* "/usr/share/plymouth/themes/$PLY_NAME/"
    grep -qE '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf \
        || info "NOTE: add 'plymouth' to HOOKS in /etc/mkinitcpio.conf (after 'udev' or 'systemd')."
    if [ -f /etc/kernel/cmdline ]; then
        grep -qw splash /etc/kernel/cmdline || info "NOTE: add 'quiet splash' to /etc/kernel/cmdline."
    else
        grep -qw splash /proc/cmdline || info "NOTE: add 'quiet splash' to your boot loader's kernel command line."
    fi
    [ -f /etc/plymouth/plymouthd.conf ] || printf '[Daemon]\nTheme=bgrt\nShowDelay=0\n' | sudo tee /etc/plymouth/plymouthd.conf >/dev/null
    if grep -q "^Theme=$PLY_NAME$" /etc/plymouth/plymouthd.conf; then
        info "Rebuilding the boot image with the new animation…"
        sudo mkinitcpio -P >/dev/null
    fi
fi

# ---------------------------------------------------------------- 7. Activar
if [ $NO_ACT = 0 ]; then
    say "Activating $NAME"
    if [ $NO_PLY = 1 ]; then "$BIN/theme" "$THEME" --no-plymouth; else "$BIN/theme" "$THEME"; fi
fi
echo
echo "$EMOJI $NAME installed. Switch themes with:  theme list | theme $THEME | theme default"
