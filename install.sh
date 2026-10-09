#!/bin/bash
# Caelestia Temas — instalador
# Uso: ./install.sh <tema> "/ruta/al/video.mp4" [--sin-plymouth] [--sin-wallpapers] [--sin-activar] [--reusar]
#   --reusar: no vuelve a generar los recursos si ya existen (p. ej. generados antes con "seguro")
#   Temas: gravity-falls, ngnl-zero  (ver la carpeta temas/)
#
# Los recursos (animación, logo y sonidos) se generan en tu equipo a partir de TU copia del vídeo.
# Este repositorio no incluye material con derechos de autor.
set -euo pipefail

REPO=$(cd "$(dirname "$0")" && pwd)
CONF=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-temas
SHARE=${XDG_DATA_HOME:-$HOME/.local/share}/caelestia-temas
BIN=$HOME/.local/bin
CAEL=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia
FF=${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch
MARK_BEGIN="caelestia-temas >>>"
MARK_END="caelestia-temas <<<"

TEMA=""; VIDEO=""; NO_PLY=0; NO_WALL=0; NO_ACT=0; REUSAR=0
for a in "$@"; do
    case "$a" in
        --sin-plymouth) NO_PLY=1 ;;
        --sin-wallpapers) NO_WALL=1 ;;
        --sin-activar) NO_ACT=1 ;;
        --reusar) REUSAR=1 ;;
        -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
        *) if [ -z "$TEMA" ]; then TEMA=$a; else VIDEO=$a; fi ;;
    esac
done

say() { printf '\n\e[1;38;5;16m==>\e[0m %s\n' "$*"; }
source "$REPO/motor/lib.sh"

[ -n "$TEMA" ] || { echo "Temas disponibles:"; ls "$REPO/temas"; echo; sed -n '3p' "$0"; exit 1; }
TDIR="$REPO/temas/$TEMA"
[ -f "$TDIR/tema.conf" ] || die "No existe el tema '$TEMA'. Disponibles: $(ls "$REPO/temas" | tr '\n' ' ')"
# shellcheck source=/dev/null
source "$TDIR/tema.conf"
DEST="$SHARE/$TEMA"
PLY_NAME="caelestia-$TEMA"

# ---------------------------------------------------------------- 1. Dependencias
say "Comprobando dependencias"
[ -d "$CAEL" ] || die "No encuentro la configuración de Caelestia en $CAEL."
need=(ffmpeg imagemagick python fastfetch pipewire curl ${DEPENDENCIAS:-})
[ $NO_PLY = 1 ] || need+=(plymouth)
missing=()
for p in "${need[@]}"; do pacman -Q "$p" &>/dev/null || missing+=("$p"); done
if [ ${#missing[@]} -gt 0 ]; then
    info "Faltan: ${missing[*]}"
    sudo pacman -S --needed "${missing[@]}"
fi
command -v realesrgan-ncnn-vulkan >/dev/null && info "Real-ESRGAN disponible: se mejorarán los fotogramas." \
    || info "Consejo: instala realesrgan-ncnn-vulkan-bin (AUR) para mejorar la calidad de la animación."

# ---------------------------------------------------------------- 2. Migración desde "Caelestia Falls"
OLD=${XDG_DATA_HOME:-$HOME/.local/share}/caelestia-falls
if [ -d "$OLD" ] || grep -qs 'caelestia-falls >>>' "$CAEL/user-config.fish" "$CAEL/hypr-user.lua"; then
    say "Migrando la instalación antigua de Caelestia Falls"
    for f in "$CAEL/user-config.fish" "$CAEL/hypr-user.lua"; do
        [ -f "$f" ] && sed -i '/caelestia-falls >>>/,/caelestia-falls <<</d' "$f"
    done
    mkdir -p "$SHARE/gravity-falls"
    [ -d "$OLD/wallpapers" ] && [ ! -d "$SHARE/gravity-falls/wallpapers" ] && mv "$OLD/wallpapers" "$SHARE/gravity-falls/wallpapers"
    rm -rf "$OLD" "${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-falls" "$FF/gravity-falls.jsonc" ~/.cache/fastfetch-bill.ansi
    rm -f "$BIN"/{criptograma,bill-logo,caelestia-falls-sonido}
    if [ -d /usr/share/plymouth/themes/gravity-falls ]; then
        grep -q '^Theme=gravity-falls' /etc/plymouth/plymouthd.conf && sudo sed -i 's/^Theme=gravity-falls/Theme=bgrt/' /etc/plymouth/plymouthd.conf
        sudo rm -rf /usr/share/plymouth/themes/gravity-falls
    fi
    info "Listo."
fi

# ---------------------------------------------------------------- 3. Vídeo y recursos
say "Generando los recursos de $NOMBRE"
if [ -z "$VIDEO" ]; then
    echo "  Necesito $VIDEO_PISTA."
    read -rp "  Ruta del vídeo: " VIDEO
fi
VIDEO=${VIDEO/#\~/$HOME}
[ -f "$VIDEO" ] || die "No existe el vídeo: $VIDEO"
DUR=$(duracion "$VIDEO")
python3 -I -c "import sys; lo, hi = map(float, sys.argv[2].split('-')); sys.exit(0 if lo <= float(sys.argv[1]) <= hi else 1)" "$DUR" "$VIDEO_DURACION" \
    || die "El vídeo dura ${DUR%.*} s; se espera $VIDEO_PISTA."
info "Vídeo: $(basename "$VIDEO") (${DUR%.*} s)"

mkdir -p "$DEST"
if [ $REUSAR = 1 ] && [ -f "$DEST/boot_frames" ] && [ -d "$DEST/plymouth" ]; then
    info "Reutilizando los recursos ya generados en $DEST"
else
    rm -rf "$DEST/plymouth"
    bash "$TDIR/generar.sh" "$VIDEO" "$DEST"
fi
cp "$TDIR/tema.conf" "$DEST/"
for f in banner.txt frases.txt; do [ -f "$TDIR/$f" ] && cp "$TDIR/$f" "$DEST/"; done

# Plymouth: script común con los valores del tema
BOOT_FRAMES=$(cat "$DEST/boot_frames"); OFF_FRAMES=$(cat "$DEST/off_frames" 2>/dev/null || echo 0)
MSG_FRAME=$(cat "$DEST/msg_frame")
sed -e "s/@BOOT_FRAMES@/$BOOT_FRAMES/" -e "s/@OFF_FRAMES@/$OFF_FRAMES/" -e "s/@FPS@/$FPS/" -e "s/@MSG_FRAME@/$MSG_FRAME/" \
    "$REPO/motor/plymouth.script" > "$DEST/plymouth/$PLY_NAME.script"
printf '[Plymouth Theme]\nName=%s\nDescription=%s\nModuleName=script\n\n[script]\nImageDir=/usr/share/plymouth/themes/%s\nScriptFile=/usr/share/plymouth/themes/%s/%s.script\n' \
    "$NOMBRE" "$DESCRIPCION" "$PLY_NAME" "$PLY_NAME" "$PLY_NAME" > "$DEST/plymouth/$PLY_NAME.plymouth"
info "Animación: $BOOT_FRAMES fotogramas de arranque, $OFF_FRAMES de apagado ($(du -sh "$DEST/plymouth" | cut -f1))."

# ---------------------------------------------------------------- 4. Scripts y configuración
say "Instalando el motor de temas"
mkdir -p "$BIN" "$CONF" ~/.config/systemd/user
install -m 755 "$REPO"/bin/{tema,tema-frase,tema-logo,tema-sonido} "$BIN/"
install -m 644 "$REPO/motor/fish.fish" "$CONF/fish.fish"

add_block() {  # archivo, prefijo de comentario, contenido
    local file=$1 c=$2 body=$3
    touch "$file"
    grep -q "$MARK_BEGIN" "$file" || printf '\n%s %s\n%s\n%s %s\n' "$c" "$MARK_BEGIN" "$body" "$c" "$MARK_END" >> "$file"
}
add_block "$CAEL/user-config.fish" "#" \
    'test -f ~/.config/caelestia-temas/fish.fish; and source ~/.config/caelestia-temas/fish.fish'
add_block "$CAEL/hypr-user.lua" "--" \
    'hl.on("hyprland.start", function() hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/tema-sonido entrada") end)'

install -m 644 "$REPO/motor/tema-apagado.service" ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now tema-apagado.service >/dev/null 2>&1 || true

# fastfetch: copia de tu configuración con el logo del tema
python3 -I - "$FF/config.jsonc" "$FF/caelestia-temas.jsonc" <<'PY'
import re, sys
src, dst = sys.argv[1:3]
try:
    t = open(src).read()
except OSError:
    t = '{\n    "logo": null,\n    "modules": ["kernel", "uptime", "shell", "memory", "packages", "os"]\n}\n'
logo = '"logo": {\n        "type": "file-raw",\n        "source": "~/.cache/fastfetch-tema-logo.ansi",\n        "padding": { "top": 1, "left": 4, "right": 4 }\n    },'
if re.search(r'"logo":\s*null,', t):
    t = re.sub(r'"logo":\s*null,', logo, t, count=1)
elif re.search(r'"logo":\s*\{.*?\n    \},', t, re.S):
    t = re.sub(r'"logo":\s*\{.*?\n    \},', logo, t, count=1, flags=re.S)
else:
    t = t.replace("{", "{\n    " + logo, 1)
open(dst, "w").write(t)
PY
info "Comandos en $BIN, saludo de fish, sonidos de entrada y apagado, y fastfetch configurados."

# ---------------------------------------------------------------- 5. Wallpapers
if [ $NO_WALL = 0 ] && [ -f "$TDIR/wallpapers.txt" ]; then
    say "Descargando wallpapers desde Wallhaven"
    WALLDIR=$(python3 -I -c 'import json,os,sys
try: print(os.path.expanduser(json.load(open(sys.argv[1]))["paths"]["wallpaperDir"]))
except Exception: print(os.path.expanduser("~/Pictures/Wallpapers"))' "$CAEL/shell.json")
    WD="$DEST/wallpapers"
    [ -d "$WALLDIR/$CARPETA_WALLPAPERS" ] && WD="$WALLDIR/$CARPETA_WALLPAPERS"
    mkdir -p "$WD"; ok=0
    while read -r id; do
        [ -n "$id" ] || continue
        ls "$WD"/wallhaven-"$id".* &>/dev/null && { ok=$((ok + 1)); continue; }
        url=$(curl -sf "https://wallhaven.cc/api/v1/w/$id" | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["data"]["path"])' 2>/dev/null) || continue
        curl -sfL -o "$WD/$(basename "$url")" "$url" && ok=$((ok + 1))
        sleep 1.5
    done < "$TDIR/wallpapers.txt"
    info "$ok wallpapers en $WD"
fi

# ---------------------------------------------------------------- 6. Plymouth
if [ $NO_PLY = 0 ]; then
    say "Instalando la animación de arranque (pide sudo)"
    sudo rm -rf "/usr/share/plymouth/themes/$PLY_NAME"
    sudo install -d "/usr/share/plymouth/themes/$PLY_NAME"
    sudo install -m 644 "$DEST"/plymouth/* "/usr/share/plymouth/themes/$PLY_NAME/"
    grep -qE '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf \
        || info "AVISO: añade 'plymouth' a HOOKS en /etc/mkinitcpio.conf (después de 'udev' o de 'systemd')."
    if [ -f /etc/kernel/cmdline ]; then
        grep -qw splash /etc/kernel/cmdline || info "AVISO: añade 'quiet splash' a /etc/kernel/cmdline."
    else
        grep -qw splash /proc/cmdline || info "AVISO: añade 'quiet splash' a la línea del kernel de tu gestor de arranque."
    fi
    [ -f /etc/plymouth/plymouthd.conf ] || printf '[Daemon]\nTheme=bgrt\nShowDelay=0\n' | sudo tee /etc/plymouth/plymouthd.conf >/dev/null
    if grep -q "^Theme=$PLY_NAME$" /etc/plymouth/plymouthd.conf; then
        info "Regenerando la imagen de arranque con la animación nueva…"
        sudo mkinitcpio -P >/dev/null
    fi
fi

# ---------------------------------------------------------------- 7. Activar
if [ $NO_ACT = 0 ]; then
    say "Activando $NOMBRE"
    if [ $NO_PLY = 1 ]; then "$BIN/tema" "$TEMA" --sin-plymouth; else "$BIN/tema" "$TEMA"; fi
fi
echo
echo "$EMOJI $NOMBRE instalado. Cambia de tema con:  tema lista | tema $TEMA | tema normal"
