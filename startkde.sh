#!/bin/bash
export DISPLAY=:99
export XDG_RUNTIME_DIR=/tmp/runtime-1000
mkdir -p "$XDG_RUNTIME_DIR"
chown ubuntu:ubuntu "$XDG_RUNTIME_DIR"

/usr/bin/Xvnc :99 -geometry 1920x1080 -depth 24 -SecurityTypes None -CompareFB 0 2>&1 | tee /tmp/vnc.log &

sleep 3

# Launch basic X apps to test
sudo -u ubuntu bash -c '
export DISPLAY=:99
xterm -bg black -fg white &
xclock -digital -bg black -fg green &
xeyes &
sleep 2
' &

# Start plasma in background
sudo -u ubuntu bash -c '
export DISPLAY=:99
export XDG_RUNTIME_DIR=/tmp/runtime-1000
export XDG_CURRENT_DESKTOP=KDE
dbus-launch --exit-with-session startplasma-x11
' &

echo "Started"