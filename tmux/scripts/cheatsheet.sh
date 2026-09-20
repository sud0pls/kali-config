#!/usr/bin/env bash
set -euo pipefail

if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    BOLD=$(tput bold)
    DIM=$(tput dim)
    RESET=$(tput sgr0)
    BLUE=$(tput setaf 39)
    YEL=$(tput setaf 214)
    GRAY=$(tput setaf 245)
else
    BOLD=""; DIM=""; RESET=""; BLUE=""; YEL=""; GRAY=""
fi

section() { printf "\n  %s%s%s\n" "${BOLD}${YEL}" "$1" "$RESET"; }
row()     { printf "    %s%-30s%s %s\n" "${BLUE}" "$1" "$RESET" "$2"; }

clear
printf "%s  Atajos de tmux%s\n" "${BOLD}${BLUE}" "$RESET"
printf "  %s(Alt+h o prefix+h para volver a abrir esta ayuda)%s\n" "$DIM" "$RESET"

section "Paneles"
row "prefix + |"        "Dividir a la derecha (vertical)"
row "prefix + -"        "Dividir abajo (horizontal)"
row "prefix + x"        "Cerrar el pane"
row "prefix + z"        "Maximizar / restaurar pane"
row "prefix + { / }"    "Mover el pane"
row "prefix + H J K L"  "Redimensionar (mantener presionado)"

section "Ventanas (tabs)"
row "prefix + c"        "Nueva tab"
row "Shift + <- / ->"   "Tab anterior / siguiente"
row "prefix + ,"        "Renombrar tab"

section "Busqueda y scroll"
row "Ctrl + r"          "Buscar en historial de comandos (fzf)"
row "Scroll up / Alt+Up"  "Modo scroll (vi): h j k l, v seleccionar,"
row ""                  "y copiar, q/Esc salir"

section "Ayuda"
row "Alt + h / prefix+h" "Esta ventana de ayuda"
row "Alt + e (zsh)"      "Comandos AD (fzf, inline)"

printf "\n  %sPresiona cualquier tecla para cerrar...%s" "$GRAY" "$RESET"
read -n 1 -s -r || true
printf "\n"
