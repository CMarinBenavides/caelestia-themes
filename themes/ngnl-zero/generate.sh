#!/bin/bash
# No Game No Life Zero: genera los recursos del tema desde el PV2 oficial de KADOKAWAanime.
# Uso: generate.sh VIDEO DESTINO     (lo llama install.sh)
set -euo pipefail
VIDEO=$1; OUT=$2
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../engine/lib.sh"
mkdir -p "$OUT/plymouth"

# Tiempos del PV 第2弾 (90 s). Se localizaron transcribiendo el audio con Whisper:
#   75,1 s「アッシェンテだ」   ·   80,3 s「ゲームを始めよう」
BOOT_START=77.08; BOOT_END=81.00          # la mano en la oscuridad → Riku → el cielo rojo
OFF_START=74.32;  OFF_END=77.05           # la cueva de cristales morados
LOGIN_START=80.15; LOGIN_END=82.05        # "¡Que empiece el juego!"
SHUTDOWN_START=74.95; SHUTDOWN_END=76.65  # "¡Aschente!"

# 1. Animaciones de arranque y apagado
N=$(extract_scene "$VIDEO" $BOOT_START $BOOT_END 12 "$OUT/plymouth" boot)
M=$(extract_scene "$VIDEO" $OFF_START $OFF_END 12 "$OUT/plymouth" off)
echo "$N" > "$OUT/boot_frames"; echo "$M" > "$OUT/off_frames"
echo $(( N * 85 / 100 )) > "$OUT/msg_frame"
info "$N boot frames and $M shutdown frames."

# 2. Mensajes: japonés grande y español pequeño, en blanco con brillo suave
make_message() {
    magick -background none \
        \( -font Noto-Sans-CJK-JP-Bold -pointsize 64 -fill white label:"$1" \) \
        \( -font Noto-Sans-CJK-JP-Medium -pointsize 24 -kerning 6 -fill '#e8f1ff' label:"$2" \) \
        -gravity center -append -bordercolor none -border 28 \
        \( +clone -background '#9fd4ff' -shadow 85x9+0+0 \) +swap -background none -layers merge +repage \
        \( +clone -background black -shadow 50x4+0+2 \) +swap -background none -layers merge +repage PNG32:"$3"
}
make_message '【 ゲーム開始 】' 'QUE EMPIECE EL JUEGO' "$OUT/plymouth/message.png"
make_message '【 ASCHENTE 】' 'LO JURO POR EL PACTO' "$OUT/plymouth/message-goodbye.png"

# 3. Logo de la terminal: una pieza de ajedrez (dibujo propio, sin derechos de autor)
magick -background black -density 96 "$HERE/logo.svg" -colorspace gray "$OUT/logo-mask.png"

# 4. Sonidos
cut_audio "$VIDEO" $LOGIN_START $LOGIN_END "$OUT/login.ogg" "loudnorm=I=-20:TP=-2"
cut_audio "$VIDEO" $SHUTDOWN_START $SHUTDOWN_END "$OUT/shutdown.ogg" "loudnorm=I=-20:TP=-2"
info "Login and shutdown sounds ready."
