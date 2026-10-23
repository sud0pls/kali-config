#!/bin/sh
# Win+D: abre rofi; si ya esta abierto, lo cierra.
pkill -x rofi && exit 0
exec rofi -show drun
