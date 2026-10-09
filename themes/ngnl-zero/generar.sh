#!/bin/bash
# No Game No Life Zero: genera los recursos del tema desde el PV2 oficial de KADOKAWAanime.
# Uso: generar.sh VIDEO DESTINO     (lo llama install.sh)
set -euo pipefail
VIDEO=$1; OUT=$2
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../motor/lib.sh"
mkdir -p "$OUT/plymouth"

# Tiempos del PV 第2弾 (90 s). Se localizaron transcribiendo el audio con Whisper:
#   75,1 s「アッシェンテだ」   ·   80,3 s「ゲームを始めよう」
BOOT_INI=77.08; BOOT_FIN=81.00     # la mano en la oscuridad → Riku → el cielo rojo
OFF_INI=74.32;  OFF_FIN=77.05      # la cueva de cristales morados
SND_IN_INI=80.15; SND_IN_FIN=82.05     # "¡Que empiece el juego!"
SND_OFF_INI=74.95; SND_OFF_FIN=76.65   # "¡Aschente!"

# 1. Animaciones de arranque y apagado
N=$(extraer_escena "$VIDEO" $BOOT_INI $BOOT_FIN 12 "$OUT/plymouth" boot)
M=$(extraer_escena "$VIDEO" $OFF_INI $OFF_FIN 12 "$OUT/plymouth" off)
echo "$N" > "$OUT/boot_frames"; echo "$M" > "$OUT/off_frames"
echo $(( N * 85 / 100 )) > "$OUT/msg_frame"
info "$N fotogramas de arranque y $M de apagado."

# 2. Mensajes: japonés grande y español pequeño, en blanco con brillo suave
mkmsg() {
    magick -background none \
        \( -font Noto-Sans-CJK-JP-Bold -pointsize 64 -fill white label:"$1" \) \
        \( -font Noto-Sans-CJK-JP-Medium -pointsize 24 -kerning 6 -fill '#e8f1ff' label:"$2" \) \
        -gravity center -append -bordercolor none -border 28 \
        \( +clone -background '#9fd4ff' -shadow 85x9+0+0 \) +swap -background none -layers merge +repage \
        \( +clone -background black -shadow 50x4+0+2 \) +swap -background none -layers merge +repage PNG32:"$3"
}
mkmsg '【 ゲーム開始 】' 'QUE EMPIECE EL JUEGO' "$OUT/plymouth/mensaje.png"
mkmsg '【 ASCHENTE 】' 'LO JURO POR EL PACTO' "$OUT/plymouth/mensaje-adios.png"

# 3. Logo de la terminal: una pieza de ajedrez (dibujo propio, sin derechos de autor)
magick -background black -density 96 "$HERE/logo.svg" -colorspace gray "$OUT/logo-mask.png"

# 4. Sonidos
cortar_audio "$VIDEO" $SND_IN_INI $SND_IN_FIN "$OUT/entrada.ogg" "loudnorm=I=-20:TP=-2"
cortar_audio "$VIDEO" $SND_OFF_INI $SND_OFF_FIN "$OUT/apagado.ogg" "loudnorm=I=-20:TP=-2"
info "Sonidos de entrada y apagado listos."
