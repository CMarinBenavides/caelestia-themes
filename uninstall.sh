#!/bin/bash
# Caelestia Themes — desinstalador
#   ./uninstall.sh            quita todos los temas y vuelve a Caelestia original
#   ./uninstall.sh <tema>     quita solo ese tema
set -uo pipefail
CONF=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-temas
SHARE=${XDG_DATA_HOME:-$HOME/.local/share}/caelestia-temas
BIN=$HOME/.local/bin
CAEL=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia
TEMA=${1:-}

read -rp "¿Borrar también los wallpapers descargados? [s/N] " del_walls

quitar_tema() {
    local id=$1
    [ "$(cat "$CONF/activo" 2>/dev/null)" = "$id" ] && "$BIN/tema" normal
    if [[ ${del_walls,,} == s* ]]; then
        rm -rf "${SHARE:?}/$id"
    else
        find "$SHARE/$id" -mindepth 1 -maxdepth 1 ! -name wallpapers -exec rm -rf {} + 2>/dev/null
        [ -d "$SHARE/$id/wallpapers" ] && echo "Los wallpapers de $id siguen en $SHARE/$id/wallpapers"
    fi
    if [ -d "/usr/share/plymouth/themes/caelestia-$id" ]; then
        echo "Quitando la animación de arranque de $id (pide sudo)…"
        sudo rm -rf "/usr/share/plymouth/themes/caelestia-$id"
    fi
}

if [ -n "$TEMA" ]; then
    quitar_tema "$TEMA"
    echo "Tema $TEMA desinstalado."
    exit 0
fi

for d in "$SHARE"/*/; do [ -d "$d" ] && quitar_tema "$(basename "$d")"; done

# Quitar los bloques añadidos a la configuración de Caelestia
for f in "$CAEL/user-config.fish" "$CAEL/hypr-user.lua"; do
    [ -f "$f" ] && sed -i '/caelestia-temas >>>/,/caelestia-temas <<</d' "$f"
done
systemctl --user disable --now tema-apagado.service 2>/dev/null
rm -f ~/.config/systemd/user/tema-apagado.service
rm -f "$BIN"/{tema,tema-frase,tema-logo,tema-sonido}
rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/caelestia-temas.jsonc" ~/.cache/fastfetch-tema-logo.ansi*
rm -rf "$CONF"
echo "Caelestia Themes desinstalado. Hasta luego. 👋"
