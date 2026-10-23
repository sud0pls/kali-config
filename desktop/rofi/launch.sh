#!/bin/sh
pkill -x rofi && exit 0
exec rofi -show drun
