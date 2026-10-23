#!/bin/sh

SELF="$(readlink -f "$0")"

iface=tun0
ip link show tun0 >/dev/null 2>&1 || iface="$(ip tuntap show 2>/dev/null | cut -d : -f1 | head -n 1)"
ip=""
[ -n "$iface" ] && ip="$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{split($4, a, "/"); print a[1]; exit}')"

if [ "${1:-}" = "copy" ]; then
    [ -n "$ip" ] || exit 0
    if [ -x "$HOME/.tmux/scripts/clip-copy.sh" ]; then
        printf '%s' "$ip" | "$HOME/.tmux/scripts/clip-copy.sh"
    else
        printf '%s' "$ip" | xsel --input --clipboard >/dev/null 2>&1
    fi
    command -v notify-send >/dev/null 2>&1 && notify-send -t 1500 -i network-vpn "IP copiada" "$ip ($iface)"
    exit 0
fi

if [ -n "$ip" ]; then
    printf '<txt> 󰖂  %s </txt>' "$ip"
    printf '<txtclick>%s copy</txtclick>' "$SELF"
    printf '<tool>%s: %s  (clic para copiar)</tool>' "$iface" "$ip"
    printf '<css>.genmon_valuebutton { background: #00afff; border-radius: 8px; margin: 4px 2px; }'
    printf ' .genmon_value { color: #0b0f14; font-weight: bold; }</css>'
else
    printf '<txt> 󰖂  VPN off </txt>'
    printf '<tool>Sin interfaz tun (VPN desconectada)</tool>'
    printf '<css>.genmon_valuebutton { background: rgba(255,255,255,0.08); border-radius: 8px; margin: 4px 2px; }'
    printf ' .genmon_value { color: #6c7086; }</css>'
fi
