#!/bin/bash
export DISPLAY=:99
export XDG_RUNTIME_DIR=/tmp/runtime-1000
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_TYPE=x11
mkdir -p "$XDG_RUNTIME_DIR"
chown ubuntu:ubuntu "$XDG_RUNTIME_DIR"

Xvfb :99 -screen 0 1920x1080x24 -noreset +extension GLX +extension RANDR +extension RENDER +extension MIT-SHM +extension XTEST &

sleep 2

x11vnc -display :99 -forever -shared -bg -rfbport 5900 -xkb &

sleep 1

sudo -u ubuntu DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus init && \
    sudo -u ubuntu bash -c 'export DISPLAY=:99 && export XDG_RUNTIME_DIR=/tmp/runtime-1000 && export XDG_CURRENT_DESKTOP=KDE && export XDG_SESSION_TYPE=x11 && startplasma-x11'