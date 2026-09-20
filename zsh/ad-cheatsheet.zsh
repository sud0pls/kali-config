ad-cheatsheet-widget() {
    emulate -L zsh
    setopt localoptions pipefail no_aliases 2>/dev/null

    local cmds_file="$HOME/.tmux/scripts/ad-commands.txt"

    if ! command -v fzf >/dev/null 2>&1; then
        zle -M "fzf no esta instalado (corre autoinstall.sh)"
        return 0
    fi
    if [[ ! -s "$cmds_file" ]]; then
        zle -M "No se encontro $cmds_file"
        return 0
    fi

    local selected
    selected="$(
        grep -v '^[[:space:]]*#' "$cmds_file" | grep -v '^[[:space:]]*$' | fzf \
            --prompt='comando AD > ' \
            --header='Enter: insertar en la linea   Esc: cancelar'
    )"

    if [[ -n "$selected" ]]; then
        local cmd="${selected#*|}"
        cmd="${cmd# }"
        LBUFFER="${LBUFFER}${cmd}"
    fi

    zle reset-prompt
}
zle -N ad-cheatsheet-widget
bindkey '^[e' ad-cheatsheet-widget
