# Caelestia Temas: saludo de la terminal y comandos del tema activo.
# Se carga desde ~/.config/caelestia/user-config.fish

set -l ct_conf (set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo $HOME/.config)/caelestia-temas
set -l ct_share (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $HOME/.local/share)/caelestia-temas

# Con un tema activo se sustituye el saludo original de Caelestia
if test -s $ct_conf/activo
    set -g __ct_tema_dir $ct_share/(string trim < $ct_conf/activo)
    function fish_greeting
        if test -f $__ct_tema_dir/banner.txt
            echo -ne '\x1b[38;5;16m'  # color principal del esquema
            cat $__ct_tema_dir/banner.txt
            set_color normal
            echo
        end
        command -v tema-frase &>/dev/null && tema-frase
        command -v tema-logo &>/dev/null && tema-logo
        command -v fastfetch &>/dev/null && fastfetch -c ~/.config/fastfetch/caelestia-temas.jsonc
    end
end

function descifrar --description 'Muestra la solución de la frase cifrada de hoy'
    tema-frase --sol
end

function sonido-inicio --description 'Activa o silencia los sonidos del tema (para reuniones)'
    set -l flag (set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo $HOME/.config)/caelestia-temas/sin-sonido
    mkdir -p (dirname $flag)
    if test -e $flag
        rm $flag; and echo "🎵 Sonidos del tema ACTIVADOS"
    else
        touch $flag; and echo "🔇 Sonidos del tema SILENCIADOS"
    end
end
