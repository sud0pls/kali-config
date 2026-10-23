#!/bin/sh
# Pega el portapapeles (CLIPBOARD; si esta vacio, PRIMARY) en el pane indicado.
# Uso: clip-paste.sh <pane_id>
# - Quita los \r que trae el texto copiado en Windows (si no, actuan como Enter)
# - Pega con bracketed paste: zsh no ejecuta las lineas al pegarlas
# - Si el portapapeles esta vacio avisa en vez de pegar un buffer viejo de tmux

[ -n "$DISPLAY" ] || export DISPLAY=:0
pane="${1:-}"

out=$(xsel --output --clipboard 2>/dev/null | tr -d '\r')
[ -n "$out" ] || out=$(xsel --output --primary 2>/dev/null | tr -d '\r')

if [ -z "$out" ]; then
    tmux display-message "Portapapeles vacio (o sin acceso a X, DISPLAY=$DISPLAY)"
    exit 0
fi

printf '%s' "$out" | tmux load-buffer -b clip-paste - \
    && tmux paste-buffer -p -d -b clip-paste ${pane:+-t "$pane"}
