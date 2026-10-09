#!/bin/bash
# Caelestia Themes — desinstalador
# Usage: ./uninstall.sh            remove every theme and go back to the original Caelestia
#        ./uninstall.sh <theme>    remove only that theme
set -uo pipefail
CONF=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-themes
SHARE=${XDG_DATA_HOME:-$HOME/.local/share}/caelestia-themes
BIN=$HOME/.local/bin
CAEL=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia
THEME=${1:-}

read -rp "Also delete the downloaded wallpapers? [y/N] " del_walls

# Quita un tema: lo desactiva si está activo, borra sus recursos y su animación de Plymouth
remove_theme() {
    local id=$1
    [ "$(cat "$CONF/active" 2>/dev/null)" = "$id" ] && "$BIN/theme" default
    if [[ ${del_walls,,} == y* ]]; then
        rm -rf "${SHARE:?}/$id"
    else
        find "$SHARE/$id" -mindepth 1 -maxdepth 1 ! -name wallpapers -exec rm -rf {} + 2>/dev/null
        [ -d "$SHARE/$id/wallpapers" ] && echo "The $id wallpapers are kept in $SHARE/$id/wallpapers"
    fi
    if [ -d "/usr/share/plymouth/themes/caelestia-$id" ]; then
        echo "Removing the $id boot animation (asks for sudo)…"
        sudo rm -rf "/usr/share/plymouth/themes/caelestia-$id"
    fi
}

if [ -n "$THEME" ]; then
    remove_theme "$THEME"
    echo "Theme $THEME uninstalled."
    exit 0
fi

for d in "$SHARE"/*/; do [ -d "$d" ] && remove_theme "$(basename "$d")"; done

# Quitar los bloques añadidos a la configuración de Caelestia
for f in "$CAEL/user-config.fish" "$CAEL/hypr-user.lua"; do
    [ -f "$f" ] && sed -i '/caelestia-themes >>>/,/caelestia-themes <<</d' "$f"
done
systemctl --user disable --now theme-shutdown.service 2>/dev/null
rm -f ~/.config/systemd/user/theme-shutdown.service
rm -f "$BIN"/{theme,theme-quote,theme-logo,theme-play}
rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/caelestia-themes.jsonc" ~/.cache/fastfetch-theme-logo.ansi*
rm -rf "$CONF"
echo "Caelestia Themes uninstalled. See you later. 👋"
