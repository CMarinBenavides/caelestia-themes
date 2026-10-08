#!/bin/bash
# Caelestia Falls — desinstalador: vuelve a Caelestia original y borra todo lo instalado.
set -uo pipefail
CONF=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-falls
SHARE=${XDG_DATA_HOME:-$HOME/.local/share}/caelestia-falls
BIN=$HOME/.local/bin
CAEL=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia

read -rp "¿Borrar también los wallpapers de Gravity Falls? [s/N] " del_walls

[ -x "$BIN/tema" ] && "$BIN/tema" normal

# Quitar los bloques añadidos a la configuración de Caelestia
for f in "$CAEL/user-config.fish" "$CAEL/hypr-user.lua"; do
    [ -f "$f" ] && sed -i '/caelestia-falls >>>/,/caelestia-falls <<</d' "$f"
done

rm -f "$BIN"/{tema,criptograma,bill-logo,caelestia-falls-sonido}
rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/gravity-falls.jsonc" ~/.cache/fastfetch-bill.ansi
rm -rf "$CONF"
if [[ ${del_walls,,} == s* ]]; then
    rm -rf "$SHARE"
else
    find "$SHARE" -mindepth 1 -maxdepth 1 ! -name wallpapers -exec rm -rf {} +
    echo "Los wallpapers siguen en $SHARE/wallpapers"
fi

if [ -d /usr/share/plymouth/themes/gravity-falls ]; then
    echo "Quitando el tema de Plymouth (pide sudo)…"
    sudo rm -rf /usr/share/plymouth/themes/gravity-falls
fi
echo "Caelestia Falls desinstalado. Hasta luego, Stanley. 👋"
