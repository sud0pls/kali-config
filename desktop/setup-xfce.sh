#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PANEL_SRC="$SCRIPT_DIR/panel"
WALLPAPER_SRC="$SCRIPT_DIR/wallpaper.png"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
MARKER="/* >>> Pen-tmux panel <<< */"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$1"; }

if [ "$(id -u)" -eq 0 ]; then
    warn "setup-xfce.sh se corre con tu usuario, no con root/sudo: se omite"
    exit 0
fi
[ -n "${DISPLAY:-}" ] || export DISPLAY=:0
if ! command -v xfconf-query >/dev/null 2>&1 || ! xfconf-query -c xfce4-panel -l >/dev/null 2>&1; then
    warn "No hay sesion de XFCE activa: se omite la barra, rofi y el wallpaper"
    exit 0
fi

xq()     { xfconf-query -c xfce4-panel "$@"; }
setp()   { xq -p "$1" -n -t "$2" -s "$3"; }
plugin() { setp "/plugins/plugin-$1" string "$2"; }

BACKUP_DIR="$HOME/.local/share/xfce4-panel-profiles"
if [ ! -f "$HOME/.config/xfce4/panel/.pen-tmux" ]; then
    mkdir -p "$BACKUP_DIR"
    if command -v xfce4-panel-profiles >/dev/null 2>&1; then
        xfce4-panel-profiles save "$BACKUP_DIR/backup-$TIMESTAMP.tar.bz2"
        log "Barra original respaldada: $BACKUP_DIR/backup-$TIMESTAMP.tar.bz2"
        log "  (restaurar: xfce4-panel-profiles load <archivo>)"
    else
        tar -C "$HOME/.config/xfce4" -cjf "$BACKUP_DIR/backup-$TIMESTAMP.tar.bz2" \
            panel xfconf/xfce-perchannel-xml/xfce4-panel.xml
        log "Barra original respaldada: $BACKUP_DIR/backup-$TIMESTAMP.tar.bz2"
    fi
fi

mkdir -p "$HOME/.config/pen-tmux"
ln -sfn "$PANEL_SRC" "$HOME/.config/pen-tmux/panel"
chmod +x "$PANEL_SRC"/*.sh

GTK_CSS="$HOME/.config/gtk-3.0/gtk.css"
mkdir -p "$(dirname "$GTK_CSS")"
touch "$GTK_CSS"
if ! grep -qF "$MARKER" "$GTK_CSS"; then
    printf '\n%s\n@import url("file://%s/.config/pen-tmux/panel/gtk.css");\n' "$MARKER" "$HOME" >> "$GTK_CSS"
    log "Estilo de la barra agregado a $GTK_CSS"
fi

xfce4-panel --quit >/dev/null 2>&1 || true
for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -x xfce4-panel >/dev/null || break; sleep 0.5; done

for id in $(xq -l | grep -oE '^/plugins/plugin-[0-9]+' | sort -u | grep -v '^/plugins/plugin-1$'); do
    xq -p "$id" -r -R
done
rm -rf "$HOME/.config/xfce4/panel"/launcher-*

PANEL=/panels/panel-1
xq -p /panels -n --force-array -t int -s 1
setp $PANEL/position          string "p=6;x=0;y=0"
setp $PANEL/position-locked   bool   true
setp $PANEL/length            uint   100
setp $PANEL/size              uint   34
setp $PANEL/icon-size         uint   18
setp $PANEL/background-style  uint   0

plugin 1 whiskermenu
setp /plugins/plugin-1/button-icon       string kali-menu
setp /plugins/plugin-1/show-button-title bool   false

plugin 2 separator
setp /plugins/plugin-2/style uint 0

launcher() {
    local id="$1" desktop="$2" dir="$HOME/.config/xfce4/panel/launcher-$1"
    [ -f "$desktop" ] || return 1
    mkdir -p "$dir"
    cp "$desktop" "$dir/$id.desktop"
    plugin "$id" launcher
    xq -p "/plugins/plugin-$id/items" -n --force-array -t string -s "$id.desktop"
}

TERM_DESKTOP="$HOME/.config/pen-tmux/tmux-terminal.desktop"
cat > "$TERM_DESKTOP" <<'EOF'
[Desktop Entry]
Type=Application
Name=Terminal (tmux)
Comment=qterminal con la sesion tmux "main" (la crea o se engancha)
Exec=qterminal -e "tmux new-session -A -s main"
Icon=utilities-terminal
Terminal=false
EOF

IDS=(1 2)
for pair in \
    "3:$TERM_DESKTOP" \
    "4:/usr/share/applications/firefox-esr.desktop" \
    "5:/usr/share/applications/kali-burpsuite.desktop" \
    "6:/usr/share/applications/com.microsoft.VSCode.desktop"
do
    launcher "${pair%%:*}" "${pair#*:}" && IDS+=("${pair%%:*}")
done

plugin 7 separator;  setp /plugins/plugin-7/style uint 0
plugin 8 pager;      setp /plugins/plugin-8/miniature-view bool false
plugin 9 tasklist
setp /plugins/plugin-9/show-labels   bool false
setp /plugins/plugin-9/grouping      uint 1
setp /plugins/plugin-9/middle-click  uint 1
setp /plugins/plugin-9/show-handle   bool false
plugin 10 separator
setp /plugins/plugin-10/style  uint 0
setp /plugins/plugin-10/expand bool true

plugin 11 genmon
setp /plugins/plugin-11/command       string "$HOME/.config/pen-tmux/panel/vpn-ip.sh"
setp /plugins/plugin-11/use-label     bool   false
setp /plugins/plugin-11/update-period int    3000
setp /plugins/plugin-11/font          string "Hack Nerd Font Bold 10"
setp /plugins/plugin-11/enable-single-row bool true

plugin 12 cpugraph
setp /plugins/plugin-12/mode        int 1
setp /plugins/plugin-12/frame       int 0
setp /plugins/plugin-12/border      int 0
setp /plugins/plugin-12/size        int 64
setp /plugins/plugin-12/color-mode  int 0
setp /plugins/plugin-12/bars        int 0
xq -p /plugins/plugin-12/background   -n -t double -s 0 -t double -s 0 -t double -s 0 -t double -s 0
xq -p /plugins/plugin-12/foreground-1 -n -t double -s 0 -t double -s 0.686 -t double -s 1 -t double -s 1

plugin 13 systray
setp /plugins/plugin-13/square-icons bool true
setp /plugins/plugin-13/size-max     uint 20
plugin 14 pulseaudio
setp /plugins/plugin-14/enable-keyboard-shortcuts bool true
plugin 15 notification-plugin
plugin 16 power-manager-plugin

plugin 17 clock
setp /plugins/plugin-17/digital-layout      uint   3
setp /plugins/plugin-17/digital-time-format string "%a %d %b  %H:%M"
setp /plugins/plugin-17/digital-time-font   string "Hack Nerd Font Bold 10"

plugin 18 actions
setp /plugins/plugin-18/appearance uint 0
xq -p /plugins/plugin-18/items -n --force-array \
    -t string -s "+lock-screen" -t string -s "-switch-user" -t string -s "-separator" \
    -t string -s "-suspend" -t string -s "-hibernate" -t string -s "-hybrid-sleep" \
    -t string -s "-separator" -t string -s "+shutdown" -t string -s "+restart" \
    -t string -s "-separator" -t string -s "+logout" -t string -s "-logout-dialog"

IDS+=(7 8 9 10 11 12 13 14 15 16 17 18)
args=()
for id in "${IDS[@]}"; do args+=(-t int -s "$id"); done
xq -p $PANEL/plugin-ids -n --force-array "${args[@]}"

touch "$HOME/.config/xfce4/panel/.pen-tmux"
setsid xfce4-panel >/dev/null 2>&1 < /dev/null &
log "Barra de XFCE configurada"

if [ -f "$WALLPAPER_SRC" ]; then
    WP_DIR="$HOME/.local/share/backgrounds"
    mkdir -p "$WP_DIR"
    cp -f "$WALLPAPER_SRC" "$WP_DIR/pen-tmux.png"
    props="$(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/last-image$' || true)"
    ws_count="$(xfconf-query -c xfwm4 -p /general/workspace_count 2>/dev/null || echo 1)"
    for mon in $(xrandr --listmonitors 2>/dev/null | awk 'NR>1 {print $NF}'); do
        for ((ws = 0; ws < ws_count; ws++)); do
            props+=$'\n'"/backdrop/screen0/monitor$mon/workspace$ws/last-image"
        done
    done
    for p in $(printf '%s\n' "$props" | sort -u); do
        xfconf-query -c xfce4-desktop -p "$p" -n -t string -s "$WP_DIR/pen-tmux.png"
        xfconf-query -c xfce4-desktop -p "${p%/last-image}/image-style" -n -t int -s 5
    done
    log "Wallpaper aplicado: $WP_DIR/pen-tmux.png"
fi

ROFI_SRC="$SCRIPT_DIR/rofi"
ln -sfn "$ROFI_SRC" "$HOME/.config/pen-tmux/rofi"
chmod +x "$ROFI_SRC"/*.sh
ROFI_CONF="$HOME/.config/rofi/config.rasi"
mkdir -p "$(dirname "$ROFI_CONF")"
if [ -e "$ROFI_CONF" ] && [ "$(readlink -f "$ROFI_CONF")" != "$(readlink -f "$ROFI_SRC/config.rasi")" ]; then
    mv "$ROFI_CONF" "$ROFI_CONF.backup.$TIMESTAMP"
    log "Respaldando config de rofi -> $ROFI_CONF.backup.$TIMESTAMP"
fi
ln -sfn "$ROFI_SRC/config.rasi" "$ROFI_CONF"

KS="xfconf-query -c xfce4-keyboard-shortcuts"

unbind_key() {
    local k
    for k in "/xfwm4/custom/$1" "/commands/custom/$1"; do
        $KS -p "$k" >/dev/null 2>&1 && $KS -p "$k" -r
    done
    return 0
}

wm_bind() {
    local key="$1" action="$2" prop
    while IFS= read -r prop; do
        [ -n "$prop" ] && [ "$prop" != "/xfwm4/custom/$key" ] && $KS -p "$prop" -r
    done < <($KS -l -v | awk -v a="$action" '$1 ~ "^/xfwm4/custom/" && $NF == a {print $1}')
    unbind_key "$key"
    $KS -p "/xfwm4/custom/$key" -n -t string -s "$action"
}

unbind_key "<Super>d"
$KS -p "/commands/custom/<Super>d" -n -t string -s "$HOME/.config/pen-tmux/rofi/launch.sh"
log "Win+D -> rofi (mostrar escritorio queda en Ctrl+Alt+D)"

for n in 1 2 3 4; do
    wm_bind "<Super>$n" "workspace_${n}_key"
done
log "Win+1..4 -> cambiar de workspace"
command -v rofi >/dev/null 2>&1 || warn "rofi no esta instalado (sudo apt install rofi)"

for _ in $(seq 1 20); do pgrep -u "$(id -u)" -x xfce4-panel >/dev/null && break; sleep 0.5; done

FAIL=0
check() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        printf '   \033[1;32mOK\033[0m %s\n' "$desc"
    else
        printf '   \033[1;31mFALLA\033[0m %s\n' "$desc"; FAIL=1
    fi
}
echo ""
log "Verificando configuracion de XFCE:"
check "Barra corriendo"                pgrep -u "$(id -u)" -x xfce4-panel
check "Barra con el layout nuevo"      test "$(xq -p $PANEL/plugin-ids | grep -cE '^[0-9]+$')" -ge 14
check "Widget VPN (genmon)"            test "$(xq -p /plugins/plugin-11/command)" = "$HOME/.config/pen-tmux/panel/vpn-ip.sh"
check "Estilo de la barra (gtk.css)"   grep -qF "$MARKER" "$GTK_CSS"
check "Scripts de la barra enlazados"  test -x "$HOME/.config/pen-tmux/panel/vpn-ip.sh"
check "Wallpaper aplicado"             test -f "$HOME/.local/share/backgrounds/pen-tmux.png"
check "rofi instalado"                 command -v rofi
check "Config de rofi enlazada"        test -f "$ROFI_CONF"
check "Tema de rofi valido"            rofi -dump-theme
check "Win+D abre rofi"                test "$($KS -p '/commands/custom/<Super>d')" = "$HOME/.config/pen-tmux/rofi/launch.sh"
check "Win+D ya no muestra escritorio" bash -c "! $KS -p '/xfwm4/custom/<Super>d'"
for n in 1 2 3 4; do
    check "Win+$n va al workspace $n"     test "$($KS -p "/xfwm4/custom/<Super>$n")" = "workspace_${n}_key"
    check "workspace $n sin teclas duplicadas" test "$($KS -l -v | awk -v a="workspace_${n}_key" '$1 ~ "^/xfwm4/custom/" && $NF == a' | wc -l)" -eq 1
done

if [ "$FAIL" -eq 0 ]; then
    log "XFCE configurado correctamente"
else
    warn "Algunas configuraciones de XFCE fallaron (ver arriba)"
fi
