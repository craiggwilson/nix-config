#!/usr/bin/env bash

pkill rofi || rofi \
    -show drun \
    -theme launcher-menu.rasi \
    -run-command 'launcher-exec {cmd}'