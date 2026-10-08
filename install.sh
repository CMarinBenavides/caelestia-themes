#!/bin/bash
# Caelestia Falls — instalador
# Uso: ./install.sh "/ruta/a/Gravity Falls - Opening Theme Song.mp4" [--sin-plymouth] [--sin-wallpapers]
#
# Genera en tu equipo, a partir de TU copia del vídeo de la intro, los fotogramas del Tío Stan,
# la silueta de Bill y el audio final. Este repositorio no incluye material con derechos de autor.
set -euo pipefail

REPO=$(cd "$(dirname "$0")" && pwd)
CONF=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-falls
SHARE=${XDG_DATA_HOME:-$HOME/.local/share}/caelestia-falls
BIN=$HOME/.local/bin
CAEL=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia
MARK_BEGIN="caelestia-falls >>>"
MARK_END="caelestia-falls <<<"

VIDEO=""; NO_PLY=0; NO_WALL=0
for a in "$@"; do
    case "$a" in
        --sin-plymouth) NO_PLY=1 ;;
        --sin-wallpapers) NO_WALL=1 ;;
        -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
        *) VIDEO=$a ;;
    esac
done

say() { printf '\n\e[1;38;5;16m==>\e[0m %s\n' "$*"; }
info() { printf '  · %s\n' "$*"; }
die() { printf '\e[31mError:\e[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- 1. Dependencias
say "Comprobando dependencias"
[ -d "$CAEL" ] || die "No encuentro la configuración de Caelestia en $CAEL."
need=(ffmpeg imagemagick python fastfetch pipewire ttf-dejavu curl)
[ $NO_PLY = 1 ] || need+=(plymouth)
missing=()
for p in "${need[@]}"; do pacman -Q "$p" &>/dev/null || missing+=("$p"); done
if [ ${#missing[@]} -gt 0 ]; then
    info "Faltan: ${missing[*]}"
    sudo pacman -S --needed "${missing[@]}"
fi
info "Todo listo."

# ---------------------------------------------------------------- 2. Vídeo
if [ -z "$VIDEO" ]; then
    read -rp "Ruta del vídeo de la intro de Gravity Falls (.mp4): " VIDEO
fi
VIDEO=${VIDEO/#\~/$HOME}
[ -f "$VIDEO" ] || die "No existe el vídeo: $VIDEO"
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VIDEO")
python3 -I -c "import sys; d=float(sys.argv[1]); sys.exit(0 if 34 <= d <= 45 else 1)" "$DUR" \
    || die "El vídeo dura ${DUR}s; se espera la intro oficial (~39 s)."
info "Vídeo: $(basename "$VIDEO") (${DUR%.*} s)"

mkdir -p "$SHARE" "$CONF"
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------- 3. Detectar escenas
say "Buscando la escena del Tío Stan, la silueta de Bill y el final"
# Brillo medio de cada fotograma entre 4 y 10 s: el destello mágico es el más brillante
read -r FLASH < <(ffmpeg -v error -ss 4 -t 6 -i "$VIDEO" -vf "signalstats,metadata=print:key=lavfi.signalstats.YAVG:file=-" -f null - \
    | python3 -I -c '
import re, sys
best = (0, 0)
t = None
for l in sys.stdin:
    m = re.search(r"pts_time:([\d.]+)", l)
    if m: t = float(m.group(1)); continue
    m = re.search(r"YAVG=([\d.]+)", l)
    if m and t is not None and float(m.group(1)) > best[0]: best = (float(m.group(1)), t)
print(f"{4 + best[1]:.3f}")')
# Primer corte de escena después del destello: ahí termina la escena
CUT=$(ffmpeg -v info -ss "$(python3 -I -c "print($FLASH + 1.5)")" -t 3 -i "$VIDEO" \
    -vf "select='gt(scene,0.3)',showinfo" -f null - 2>&1 | grep -Po 'pts_time:\K[\d.]+' | head -1)
[ -n "$CUT" ] || die "No encontré el final de la escena del Tío Stan."
START=$FLASH
END=$(python3 -I -c "print(f'{$FLASH + 1.5 + $CUT - 0.04:.3f}')")
info "Escena del Tío Stan: ${START}s → ${END}s"

# ---------------------------------------------------------------- 4. Fotogramas de Plymouth
say "Generando la animación de arranque (Full HD)"
mkdir -p "$WORK/raw" "$SHARE/plymouth"
rm -f "$SHARE"/plymouth/frame-*.png
ffmpeg -v error -ss "$START" -to "$END" -i "$VIDEO" -vf "fps=15,scale=1920:1080:flags=lanczos" -start_number 0 "$WORK/raw/frame-%d.png"
N=$(ls "$WORK/raw" | wc -l)
for f in "$WORK"/raw/*.png; do
    magick "$f" -dither FloydSteinberg -colors 192 -define png:compression-level=9 PNG8:"$SHARE/plymouth/$(basename "$f")"
done
MSG_FRAME=$(( N * 76 / 100 ))
sed -e "s/^NUM_FRAMES = .*/NUM_FRAMES = $N;/" -e "s/^MSG_FRAME = .*/MSG_FRAME = $MSG_FRAME;/" \
    "$REPO/plymouth/gravity-falls.script" > "$SHARE/plymouth/gravity-falls.script"
cp "$REPO/plymouth/gravity-falls.plymouth" "$SHARE/plymouth/"
info "$N fotogramas ($(du -sh "$SHARE/plymouth" | cut -f1))."

# Mensajes cifrados (Atbash): BIENVENIDO STANFORD / HASTA LUEGO STANLEY
FONT=$(fc-match -f '%{file}' 'DejaVu Serif:bold')
mkmsg() {
    magick -size 1700x150 xc:none -font "$FONT" -pointsize 58 -kerning 10 -gravity center \
        -stroke '#1e120a' -strokewidth 12 -fill '#1e120a' -annotate +0+0 "$1" \
        -stroke none -fill '#f6e7b8' -annotate +0+0 "$1" -trim +repage -bordercolor none -border 16 \
        \( +clone -background black -shadow 60x10+0+6 \) +swap -background none -layers merge +repage PNG32:"$2"
}
mkmsg 'YRVMEVMRWL HGZMULIW' "$SHARE/plymouth/mensaje.png"
mkmsg 'SZHGZ OFVTL HGZMOVB' "$SHARE/plymouth/mensaje-adios.png"

# ---------------------------------------------------------------- 5. Bill Cipher y audio
say "Extrayendo la silueta de Bill y el susurro final"
T0=$(python3 -I -c "print(max(0, $DUR - 1.6))")
ffmpeg -v error -ss "$T0" -i "$VIDEO" -vf fps=24 "$WORK/b_%02d.png"
BEST=""; BESTV=0
for f in "$WORK"/b_*.png; do
    read -r mean maxi < <(magick "$f" -colorspace gray -format '%[fx:mean] %[fx:maxima]\n' info:)
    if python3 -I -c "import sys; sys.exit(0 if $mean < 0.08 and $maxi > $BESTV else 1)"; then BEST=$f; BESTV=$maxi; fi
done
[ -n "$BEST" ] || die "No encontré la silueta de Bill al final del vídeo."
magick "$BEST" -colorspace gray -auto-level -trim +repage -resize 200% -unsharp 0x3+1.5+0 -level 18%,85% \
    -morphology Dilate Disk:5 -resize 50% -level 0%,70% "$SHARE/bill-mask.png"

ASTART=$(python3 -I -c "print(f'{$DUR - 2.9:.2f}')")
ffmpeg -v error -y -ss "$ASTART" -i "$VIDEO" -t 2.9 -vn \
    -af "afade=t=in:d=0.15,volume=volume=2.8:enable='gte(t,0.3)',afade=t=out:st=2.5:d=0.4,alimiter=limit=0.9" \
    -c:a libopus -b:a 160k "$SHARE/intro.ogg"
info "Bill y audio listos."

# ---------------------------------------------------------------- 6. Scripts y configuración
say "Instalando scripts y configuración"
mkdir -p "$BIN"
install -m 755 "$REPO"/bin/{tema,criptograma,bill-logo,caelestia-falls-sonido} "$BIN/"
install -m 644 "$REPO/fish/caelestia-falls.fish" "$CONF/caelestia-falls.fish"

add_block() {  # archivo, prefijo de comentario, contenido
    local file=$1 c=$2 body=$3
    touch "$file"
    if ! grep -q "$MARK_BEGIN" "$file"; then
        printf '\n%s %s\n%s\n%s %s\n' "$c" "$MARK_BEGIN" "$body" "$c" "$MARK_END" >> "$file"
    fi
}
add_block "$CAEL/user-config.fish" "#" \
    'test -f ~/.config/caelestia-falls/caelestia-falls.fish; and source ~/.config/caelestia-falls/caelestia-falls.fish'
add_block "$CAEL/hypr-user.lua" "--" \
    'hl.on("hyprland.start", function() hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/caelestia-falls-sonido") end)'

# fastfetch: copia de tu configuración con Bill como logo
FF=${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch
python3 -I - "$FF/config.jsonc" "$FF/gravity-falls.jsonc" <<'PY'
import re, sys
src, dst = sys.argv[1:3]
try:
    t = open(src).read()
except OSError:
    t = '{\n    "logo": null,\n    "modules": ["kernel", "uptime", "shell", "memory", "packages", "os"]\n}\n'
logo = '"logo": {\n        "type": "file-raw",\n        "source": "~/.cache/fastfetch-bill.ansi",\n        "padding": { "top": 1, "left": 4, "right": 4 }\n    },'
if re.search(r'"logo":\s*null,', t):
    t = re.sub(r'"logo":\s*null,', logo, t, count=1)
elif re.search(r'"logo":\s*\{.*?\n    \},', t, re.S):
    t = re.sub(r'"logo":\s*\{.*?\n    \},', logo, t, count=1, flags=re.S)
else:
    t = t.replace("{", "{\n    " + logo, 1)
open(dst, "w").write(t)
PY
info "Scripts en $BIN, saludo de fish, sonido de inicio y fastfetch configurados."

# ---------------------------------------------------------------- 7. Wallpapers
if [ $NO_WALL = 0 ]; then
    say "Descargando wallpapers de Gravity Falls desde Wallhaven"
    WD="$SHARE/wallpapers"
    WALLDIR=$(python3 -I -c 'import json,os,sys
try: print(os.path.expanduser(json.load(open(sys.argv[1]))["paths"]["wallpaperDir"]))
except Exception: print(os.path.expanduser("~/Pictures/Wallpapers"))' "$CAEL/shell.json")
    [ -d "$WALLDIR/Gravity Falls Theme" ] && WD="$WALLDIR/Gravity Falls Theme"
    mkdir -p "$WD"
    ok=0
    while read -r id; do
        [ -n "$id" ] || continue
        ls "$WD"/wallhaven-"$id".* &>/dev/null && { ok=$((ok + 1)); continue; }
        url=$(curl -sf "https://wallhaven.cc/api/v1/w/$id" | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["data"]["path"])' 2>/dev/null) || continue
        curl -sfL -o "$WD/$(basename "$url")" "$url" && ok=$((ok + 1))
        sleep 1.5
    done < "$REPO/data/wallpapers.txt"
    info "$ok wallpapers en $WD"
fi

# ---------------------------------------------------------------- 8. Plymouth
if [ $NO_PLY = 0 ]; then
    say "Instalando el tema de Plymouth (pide sudo)"
    sudo install -d /usr/share/plymouth/themes/gravity-falls
    sudo install -m 644 "$SHARE"/plymouth/* /usr/share/plymouth/themes/gravity-falls/
    grep -qE '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf \
        || info "AVISO: añade 'plymouth' a HOOKS en /etc/mkinitcpio.conf (después de 'udev' o de 'systemd')."
    if [ -f /etc/kernel/cmdline ]; then
        grep -qw splash /etc/kernel/cmdline || info "AVISO: añade 'quiet splash' a /etc/kernel/cmdline."
    else
        grep -qw splash /proc/cmdline || info "AVISO: añade 'quiet splash' a la línea del kernel de tu gestor de arranque."
    fi
    [ -f /etc/plymouth/plymouthd.conf ] || printf '[Daemon]\nTheme=bgrt\nShowDelay=0\n' | sudo tee /etc/plymouth/plymouthd.conf >/dev/null
    # Si el tema ya estaba activo, regenerar para incluir los fotogramas nuevos
    if grep -q '^Theme=gravity-falls' /etc/plymouth/plymouthd.conf; then
        info "Regenerando la imagen de arranque con la animación nueva…"
        sudo mkinitcpio -P >/dev/null
    fi
fi

# ---------------------------------------------------------------- 9. Activar
say "Activando Caelestia Falls"
if [ $NO_PLY = 1 ]; then "$BIN/tema" gravity-falls --sin-plymouth; else "$BIN/tema" gravity-falls; fi
echo
echo "🌲🔺 ¡Bienvenido a Caelestia Falls! Cambia de tema con:  tema gravity-falls | tema normal | tema estado"
