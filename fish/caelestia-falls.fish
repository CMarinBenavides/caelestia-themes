# Caelestia Falls: saludo de la terminal y comandos del tema.
# Se carga desde ~/.config/caelestia/user-config.fish

set -l cf_conf (set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo $HOME/.config)/caelestia-falls

# Solo con el tema activo se sustituye el saludo original de Caelestia
if test -e $cf_conf/activo
    function fish_greeting
        echo -ne '\x1b[38;5;16m'  # color principal del esquema
        echo '     ______           __          __  _           ______      ____     '
        echo '    / ____/___ ____  / /__  _____/ /_(_)___ _    / ____/___ _/ / /____ '
        echo '   / /   / __ `/ _ \/ / _ \/ ___/ __/ / __ `/   / /_  / __ `/ / / ___/ '
        echo '  / /___/ /_/ /  __/ /  __(__  ) /_/ / /_/ /   / __/ / /_/ / / (__  )  '
        echo '  \____/\__,_/\___/_/\___/____/\__/_/\__,_/   /_/    \__,_/_/_/____/   '
        set_color normal
        echo
        command -v criptograma &>/dev/null && criptograma
        command -v bill-logo &>/dev/null && bill-logo
        command -v fastfetch &>/dev/null && fastfetch -c ~/.config/fastfetch/gravity-falls.jsonc
    end
end

function descifrar --description 'Muestra la solución del criptograma de hoy'
    criptograma --sol
end

function sonido-inicio --description 'Activa o silencia el sonido de inicio de Caelestia Falls'
    set -l flag (set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo $HOME/.config)/caelestia-falls/sin-sonido
    mkdir -p (dirname $flag)
    if test -e $flag
        rm $flag; and echo "🎵 Sonido de inicio ACTIVADO"
    else
        touch $flag; and echo "🔇 Sonido de inicio SILENCIADO"
    end
end
