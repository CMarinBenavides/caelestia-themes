#!/bin/bash
# Funciones comunes para los generar.sh de cada tema (se cargan con "source").

info() { printf '  · %s\n' "$*" >&2; }
die() { printf '\e[31mError:\e[0m %s\n' "$*" >&2; exit 1; }

# extraer_escena VIDEO INICIO FIN FPS DESTINO PREFIJO
# Saca los fotogramas de una escena en Full HD como PREFIJO-0.png, PREFIJO-1.png…
extraer_escena() {
    local video=$1 ini=$2 fin=$3 fps=$4 dst=$5 pre=$6 tmp
    tmp=$(mktemp -d)
    ffmpeg -v fatal -ss "$ini" -to "$fin" -i "$video" -vf "fps=$fps,scale=1920:1080:flags=lanczos" \
        -start_number 0 "$tmp/f-%d.png" </dev/null
    mejorar_fotogramas "$tmp"
    local n=0
    for f in $(ls "$tmp"/f-*.png | sort -t- -k2 -n); do
        optimizar_png "$f" "$dst/$pre-$n.png"
        n=$((n + 1))
    done
    rm -rf "$tmp"
    echo "$n"
}

# Limpia artefactos de compresión con Real-ESRGAN (modelo de anime) si está instalado:
# agranda x2 y vuelve a 1080p, lo que elimina bloques y bandas de YouTube.
mejorar_fotogramas() {
    local dir=$1
    command -v realesrgan-ncnn-vulkan >/dev/null || return 0
    [ "${CAELESTIA_TEMAS_SIN_IA:-0}" = 1 ] && return 0
    local up; up=$(mktemp -d)
    if realesrgan-ncnn-vulkan -i "$dir" -o "$up" -n realesr-animevideov3 -s 2 -f png >/dev/null 2>&1; then
        for f in "$up"/*.png; do
            magick "$f" -resize 1920x1080! "$dir/$(basename "$f")"
        done
        info "Fotogramas mejorados con Real-ESRGAN (anime)."
    else
        info "Real-ESRGAN no pudo procesar los fotogramas; se usan sin mejorar."
    fi
    rm -rf "$up"
}

# Reduce el tamaño de un PNG para la imagen de arranque (paleta con difuminado)
optimizar_png() {
    magick "$1" -dither FloydSteinberg -colors "${COLORES_PNG:-192}" \
        -define png:compression-level=9 -define png:compression-filter=5 PNG8:"$2"
}

# cortar_audio VIDEO INICIO FIN DESTINO [filtros extra]
cortar_audio() {
    local video=$1 ini=$2 fin=$3 dst=$4 extra=${5:-}
    local dur; dur=$(python3 -I -c "print(round($fin - $ini, 3))")
    local fade; fade=$(python3 -I -c "print(max(0, round($fin - $ini - 0.25, 3)))")
    ffmpeg -v fatal -y -ss "$ini" -i "$video" -t "$dur" -vn \
        -af "afade=t=in:d=0.08,${extra:+$extra,}afade=t=out:st=$fade:d=0.25,alimiter=limit=0.9" \
        -c:a libopus -b:a 160k "$dst" </dev/null
}

# duracion VIDEO
duracion() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$1"; }
