#!/bin/bash
# Funciones comunes para los generate.sh de cada tema (se cargan con "source").

info() { printf '  · %s\n' "$*" >&2; }
die() { printf '\e[31mError:\e[0m %s\n' "$*" >&2; exit 1; }

# extract_scene VIDEO INICIO FIN FPS DESTINO PREFIJO
# Saca los fotogramas de una escena en Full HD como PREFIJO-0.png, PREFIJO-1.png…
# y devuelve (por stdout) cuántos fotogramas generó.
extract_scene() {
    local video=$1 start=$2 end=$3 fps=$4 dst=$5 prefix=$6 tmp
    tmp=$(mktemp -d)
    ffmpeg -v fatal -ss "$start" -to "$end" -i "$video" -vf "fps=$fps,scale=1920:1080:flags=lanczos" \
        -start_number 0 "$tmp/f-%d.png" </dev/null
    enhance_frames "$tmp"
    local n=0
    for f in $(ls "$tmp"/f-*.png | sort -t- -k2 -n); do
        optimize_png "$f" "$dst/$prefix-$n.png"
        n=$((n + 1))
    done
    rm -rf "$tmp"
    echo "$n"
}

# Limpia artefactos de compresión con Real-ESRGAN (modelo de anime) si está instalado:
# agranda x2 y vuelve a 1080p, lo que elimina bloques y bandas de YouTube.
# Se desactiva con CAELESTIA_THEMES_NO_AI=1 (por ejemplo, si el equipo se calienta).
enhance_frames() {
    local dir=$1
    command -v realesrgan-ncnn-vulkan >/dev/null || return 0
    [ "${CAELESTIA_THEMES_NO_AI:-0}" = 1 ] && return 0
    local up; up=$(mktemp -d)
    if realesrgan-ncnn-vulkan -i "$dir" -o "$up" -n realesr-animevideov3 -s 2 -f png >/dev/null 2>&1; then
        for f in "$up"/*.png; do
            magick "$f" -resize 1920x1080! "$dir/$(basename "$f")"
        done
        info "Frames enhanced with Real-ESRGAN (anime model)."
    else
        info "Real-ESRGAN could not process the frames; using them as they are."
    fi
    rm -rf "$up"
}

# Reduce el tamaño de un PNG para la imagen de arranque (paleta con difuminado)
optimize_png() {
    magick "$1" -dither FloydSteinberg -colors "${PNG_COLORS:-192}" \
        -define png:compression-level=9 -define png:compression-filter=5 PNG8:"$2"
}

# cut_audio VIDEO INICIO FIN DESTINO [filtros extra de ffmpeg]
# Recorta un fragmento de audio con fundido de entrada y salida, en Opus.
cut_audio() {
    local video=$1 start=$2 end=$3 dst=$4 extra=${5:-}
    local len; len=$(python3 -I -c "print(round($end - $start, 3))")
    local fade; fade=$(python3 -I -c "print(max(0, round($end - $start - 0.25, 3)))")
    ffmpeg -v fatal -y -ss "$start" -i "$video" -t "$len" -vn \
        -af "afade=t=in:d=0.08,${extra:+$extra,}afade=t=out:st=$fade:d=0.25,alimiter=limit=0.9" \
        -c:a libopus -b:a 160k "$dst" </dev/null
}

# duration VIDEO → duración en segundos
duration() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$1"; }
