#!/bin/bash
# Gravity Falls: genera los recursos del tema desde la intro oficial.
# Uso: generar.sh VIDEO DESTINO     (lo llama install.sh)
set -euo pipefail
VIDEO=$1; OUT=$2
source "$(dirname "$0")/../../motor/lib.sh"
mkdir -p "$OUT/plymouth"
DUR=$(duracion "$VIDEO")

# 1. Escena del Tío Stan: el fotograma más brillante entre 4 y 10 s es el destello mágico,
#    y la escena termina en el siguiente corte.
FLASH=$(ffmpeg -v fatal -ss 4 -t 6 -i "$VIDEO" -vf "signalstats,metadata=print:key=lavfi.signalstats.YAVG:file=-" -f null - </dev/null \
    | python3 -I -c '
import re, sys
best, t = (0, 0), None
for l in sys.stdin:
    m = re.search(r"pts_time:([\d.]+)", l)
    if m: t = float(m.group(1)); continue
    m = re.search(r"YAVG=([\d.]+)", l)
    if m and t is not None and float(m.group(1)) > best[0]: best = (float(m.group(1)), t)
print(f"{4 + best[1]:.3f}")')
CUT=$(ffmpeg -v info -ss "$(python3 -I -c "print($FLASH + 1.5)")" -t 3 -i "$VIDEO" \
    -vf "select='gt(scene,0.3)',showinfo" -f null - </dev/null 2>&1 | grep -Po 'pts_time:\K[\d.]+' | head -1)
[ -n "$CUT" ] || die "No encontré el final de la escena del Tío Stan."
END=$(python3 -I -c "print(f'{$FLASH + 1.5 + $CUT - 0.04:.3f}')")
info "Escena del Tío Stan: ${FLASH}s → ${END}s"
N=$(extraer_escena "$VIDEO" "$FLASH" "$END" 15 "$OUT/plymouth" boot)
echo "$N" > "$OUT/boot_frames"
echo $(( N * 76 / 100 )) > "$OUT/msg_frame"
info "$N fotogramas de arranque."

# 2. Mensajes cifrados (Atbash): BIENVENIDO STANFORD / HASTA LUEGO STANLEY
FONT=$(fc-match -f '%{file}' 'DejaVu Serif:bold')
mkmsg() {
    magick -size 1700x150 xc:none -font "$FONT" -pointsize 58 -kerning 10 -gravity center \
        -stroke '#1e120a' -strokewidth 12 -fill '#1e120a' -annotate +0+0 "$1" \
        -stroke none -fill '#f6e7b8' -annotate +0+0 "$1" -trim +repage -bordercolor none -border 16 \
        \( +clone -background black -shadow 60x10+0+6 \) +swap -background none -layers merge +repage PNG32:"$2"
}
mkmsg 'YRVMEVMRWL HGZMULIW' "$OUT/plymouth/mensaje.png"
mkmsg 'SZHGZ OFVTL HGZMOVB' "$OUT/plymouth/mensaje-adios.png"

# 3. Silueta de Bill: el fotograma oscuro más brillante del último segundo y medio
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
ffmpeg -v fatal -ss "$(python3 -I -c "print(max(0, $DUR - 1.6))")" -i "$VIDEO" -vf fps=24 "$W/b_%02d.png" </dev/null
BEST=""; BESTV=0
for f in "$W"/b_*.png; do
    read -r mean maxi < <(magick "$f" -colorspace gray -format '%[fx:mean] %[fx:maxima]\n' info:)
    if python3 -I -c "import sys; sys.exit(0 if $mean < 0.08 and $maxi > $BESTV else 1)"; then BEST=$f; BESTV=$maxi; fi
done
[ -n "$BEST" ] || die "No encontré la silueta de Bill al final del vídeo."
magick "$BEST" -colorspace gray -auto-level -trim +repage -resize 200% -unsharp 0x3+1.5+0 -level 18%,85% \
    -morphology Dilate Disk:5 -resize 50% -level 0%,70% "$OUT/logo-mask.png"
info "Silueta de Bill lista."

# 4. Sonido de entrada: el susurro invertido de Bill (últimos 2,9 s), realzado
INI=$(python3 -I -c "print(f'{$DUR - 2.9:.2f}')")
cortar_audio "$VIDEO" "$INI" "$DUR" "$OUT/entrada.ogg" "volume=volume=2.8:enable='gte(t,0.3)'"
info "Sonido de entrada listo."
