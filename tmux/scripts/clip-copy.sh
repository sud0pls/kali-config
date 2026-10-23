#!/bin/sh
# Lee la seleccion de tmux por stdin y la pone en CLIPBOARD y PRIMARY.
# Se ponen ambas para que open-vm-tools la sincronice con el host Windows
# sin importar cual selection monitoree esa version de vmtoolsd.

# Si el server de tmux arranco sin X (SSH, antes del login grafico) no hay DISPLAY
[ -n "$DISPLAY" ] || export DISPLAY=:0

notify() { [ -n "$TMUX" ] && tmux display-message "$1"; }

buf=$(cat)
[ -n "$buf" ] || exit 0

if ! command -v xsel >/dev/null 2>&1; then
    notify "clip-copy: xsel no esta instalado (sudo apt install xsel)"
    exit 1
fi

if ! printf '%s' "$buf" | xsel --input --clipboard >/dev/null 2>&1; then
    notify "clip-copy: no se pudo copiar al portapapeles (DISPLAY=$DISPLAY)"
    exit 1
fi
printf '%s' "$buf" | xsel --input --primary >/dev/null 2>&1
exit 0
