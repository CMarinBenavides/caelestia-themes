# Caelestia Themes: saludo de la terminal y comandos del tema activo.
# Se carga desde ~/.config/caelestia/user-config.fish

set -l ct_conf (set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo $HOME/.config)/caelestia-themes
set -l ct_share (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $HOME/.local/share)/caelestia-themes

# Con un tema activo se sustituye el saludo original de Caelestia
if test -s $ct_conf/active
    set -g __ct_theme_dir $ct_share/(string trim < $ct_conf/active)
    function fish_greeting
        if test -f $__ct_theme_dir/banner.txt
            echo -ne '\x1b[38;5;16m'  # color principal del esquema
            cat $__ct_theme_dir/banner.txt
            set_color normal
            echo
        end
        command -v theme-quote &>/dev/null && theme-quote
        command -v theme-logo &>/dev/null && theme-logo
        command -v fastfetch &>/dev/null && fastfetch -c ~/.config/fastfetch/caelestia-themes.jsonc
    end
end

function decode --description 'Show the solution of today\'s encoded quote'
    theme-quote --solve
end

function theme-sound --description 'Mute or unmute the theme sounds (handy for meetings)'
    set -l flag (set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo $HOME/.config)/caelestia-themes/muted
    mkdir -p (dirname $flag)
    if test -e $flag
        rm $flag; and echo "🎵 Theme sounds ON"
    else
        touch $flag; and echo "🔇 Theme sounds MUTED"
    end
end
