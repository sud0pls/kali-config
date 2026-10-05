#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_CONF_SRC="$SCRIPT_DIR/tmux/tmux.conf"
TMUX_SCRIPTS_SRC="$SCRIPT_DIR/tmux/scripts"

MARKER="# >>> config/autoinstall.sh <<<"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$1"; }

if [ ! -f "$TMUX_CONF_SRC" ] || [ ! -d "$SCRIPT_DIR/zsh" ]; then
    echo "No se encuentran los archivos esperados dentro de $SCRIPT_DIR" >&2
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

NEED_INSTALL=()
command -v tmux  >/dev/null 2>&1 || NEED_INSTALL+=("tmux")
command -v fzf   >/dev/null 2>&1 || NEED_INSTALL+=("fzf")
command -v xclip >/dev/null 2>&1 || NEED_INSTALL+=("xclip")

if [ "${#NEED_INSTALL[@]}" -gt 0 ]; then
    log "Instalando paquetes faltantes: ${NEED_INSTALL[*]}"
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq "${NEED_INSTALL[@]}"
else
    log "tmux, fzf y xclip ya estan instalados"
fi

if command -v tmux >/dev/null 2>&1; then
    TMUX_VER="$(tmux -V | grep -oE '[0-9]+\.[0-9]+' | head -1)"
    TMUX_MAJOR="${TMUX_VER%%.*}"
    TMUX_MINOR="${TMUX_VER#*.}"
    if [ -n "$TMUX_MAJOR" ] && { [ "$TMUX_MAJOR" -lt 3 ] || { [ "$TMUX_MAJOR" -eq 3 ] && [ "$TMUX_MINOR" -lt 2 ]; }; }; then
        warn "tmux $TMUX_VER detectado. Se requiere >= 3.2 (display-popup)"
    fi
fi

NERD_FONT_DIR="$HOME/.local/share/fonts/hack-nerd"
if fc-list : family | grep -qi "hack nerd"; then
    log "Hack Nerd Font ya esta instalada"
else
    log "Instalando Hack Nerd Font..."
    command -v curl >/dev/null 2>&1 || { $SUDO apt-get install -y -qq curl; }
    mkdir -p "$NERD_FONT_DIR"
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz \
        | tar -xJ -C "$NERD_FONT_DIR"
    fc-cache -f "$NERD_FONT_DIR"
    log "Hack Nerd Font instalada en $NERD_FONT_DIR"
    warn "Configura 'Hack Nerd Font Mono' como fuente de tu emulador de terminal"
fi

if [ -e "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
    if [ "$(readlink -f "$HOME/.tmux.conf" 2>/dev/null || true)" != "$(readlink -f "$TMUX_CONF_SRC")" ]; then
        log "Respaldando ~/.tmux.conf existente -> ~/.tmux.conf.backup.$TIMESTAMP"
        mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup.$TIMESTAMP"
    fi
fi
ln -sfn "$TMUX_CONF_SRC" "$HOME/.tmux.conf"
log "~/.tmux.conf -> $TMUX_CONF_SRC"

mkdir -p "$HOME/.tmux"
if [ -e "$HOME/.tmux/scripts" ] || [ -L "$HOME/.tmux/scripts" ]; then
    if [ "$(readlink -f "$HOME/.tmux/scripts" 2>/dev/null || true)" != "$(readlink -f "$TMUX_SCRIPTS_SRC")" ]; then
        log "Respaldando ~/.tmux/scripts existente -> ~/.tmux/scripts.backup.$TIMESTAMP"
        mv "$HOME/.tmux/scripts" "$HOME/.tmux/scripts.backup.$TIMESTAMP"
    fi
fi
ln -sfn "$TMUX_SCRIPTS_SRC" "$HOME/.tmux/scripts"
chmod +x "$TMUX_SCRIPTS_SRC"/*.sh
log "~/.tmux/scripts -> $TMUX_SCRIPTS_SRC"

ZSHRC="$HOME/.zshrc"
[ -f "$ZSHRC" ] || touch "$ZSHRC"

FZF_KEYBINDINGS=""
for candidate in \
    /usr/share/doc/fzf/examples/key-bindings.zsh \
    /usr/share/fzf/key-bindings.zsh \
    /usr/share/zsh/vendor-completions/fzf-key-bindings.zsh \
    /usr/local/opt/fzf/shell/key-bindings.zsh
do
    [ -f "$candidate" ] && { FZF_KEYBINDINGS="$candidate"; break; }
done

FZF_COMPLETION=""
for candidate in \
    /usr/share/doc/fzf/examples/completion.zsh \
    /usr/share/fzf/completion.zsh \
    /usr/local/opt/fzf/shell/completion.zsh
do
    [ -f "$candidate" ] && { FZF_COMPLETION="$candidate"; break; }
done

if [ -n "$FZF_KEYBINDINGS" ]; then
    if ! grep -qF "$FZF_KEYBINDINGS" "$ZSHRC" 2>/dev/null; then
        {
            echo ""
            echo "$MARKER fzf key-bindings"
            echo "[ -f \"$FZF_KEYBINDINGS\" ] && source \"$FZF_KEYBINDINGS\""
            [ -n "$FZF_COMPLETION" ] && echo "[ -f \"$FZF_COMPLETION\" ] && source \"$FZF_COMPLETION\""
        } >> "$ZSHRC"
        log "Ctrl+R (fzf) agregado a $ZSHRC"
    else
        log "fzf ya estaba integrado en $ZSHRC"
    fi
else
    warn "No se encontraron los scripts de shell de fzf (key-bindings.zsh)."
fi

if grep -qE '^HISTSIZE=' "$ZSHRC" 2>/dev/null; then
    sed -i -e 's/^HISTSIZE=.*/HISTSIZE=100000/' -e 's/^SAVEHIST=.*/SAVEHIST=100000/' "$ZSHRC"
    log "HISTSIZE/SAVEHIST actualizados a 100000"
else
    { echo ""; echo "HISTSIZE=100000"; echo "SAVEHIST=100000"; } >> "$ZSHRC"
    log "HISTSIZE/SAVEHIST agregados (100000)"
fi

for opt in share_history inc_append_history hist_reduce_blanks hist_find_no_dups; do
    if ! grep -qE "^setopt $opt" "$ZSHRC" 2>/dev/null; then
        echo "setopt $opt" >> "$ZSHRC"
        log "setopt $opt agregado"
    fi
done

if grep -qE "^bindkey '\\^\\[\\[5~'" "$ZSHRC" 2>/dev/null; then
    sed -i -e "s/^bindkey '\\^\\[\\[5~'/# bindkey '^[[5~'/" -e "s/^bindkey '\\^\\[\\[6~'/# bindkey '^[[6~'/" "$ZSHRC"
    log "Page up/down desactivados (scroll via tmux)"
fi

shopt -s nullglob 2>/dev/null || true
for addon in "$SCRIPT_DIR"/zsh/*.zsh; do
    if ! grep -qF "$addon" "$ZSHRC" 2>/dev/null; then
        {
            echo ""
            echo "$MARKER zsh addon: $(basename "$addon")"
            echo "[ -f \"$addon\" ] && source \"$addon\""
        } >> "$ZSHRC"
        log "Addon de zsh agregado a $ZSHRC: $(basename "$addon")"
    else
        log "Addon de zsh ya estaba agregado: $(basename "$addon")"
    fi
done

if command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1; then
    tmux source-file "$HOME/.tmux.conf" && log "Config de tmux recargada en la sesion activa"
fi

echo ""
log "Listo. Abri una terminal nueva (o corre 'exec zsh') para ver los cambios."
log "Dentro de tmux: Alt+h (o prefix+h) abre la ayuda con los atajos."
