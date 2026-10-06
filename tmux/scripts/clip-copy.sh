#!/bin/sh
# Lee la seleccion de tmux por stdin y la pone en CLIPBOARD y PRIMARY.
# Se ponen ambas para que open-vm-tools la sincronice con el host Windows
# sin importar cual selection monitoree esa version de vmtoolsd.
buf=$(cat)
printf '%s' "$buf" | xsel --input --clipboard 2>/dev/null
printf '%s' "$buf" | xsel --input --primary   2>/dev/null
