#!/bin/sh
# Devuelve el contenido del portapapeles (CLIPBOARD); si esta vacio, PRIMARY.
out=$(xsel --output --clipboard 2>/dev/null)
[ -n "$out" ] || out=$(xsel --output --primary 2>/dev/null)
printf '%s' "$out"
