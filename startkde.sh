#!/bin/bash
export DISPLAY=:99
export XDG_RUNTIME_DIR=/tmp/runtime-1000
mkdir -p "$XDG_RUNTIME_DIR"
chown ubuntu:ubuntu "$XDG_RUNTIME_DIR"

# Clean up
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99

# Download noVNC if not present
if [ ! -d "/opt/novnc" ]; then
    mkdir -p /opt/novnc
    cd /opt/novnc
    wget -q https://github.com/novnc/noVNC/archive/refs/heads/master.tar.gz -O master.tar.gz
    tar -xzf master.tar.gz --strip-components=1
    rm -f master.tar.gz
fi

# Run Xvfb as ubuntu user
exec sudo -u ubuntu /usr/bin/Xvfb \
    "${DISPLAY}" \
    -screen 0 "1920x1080x24" \
    -dpi "96" \
    +extension "COMPOSITE" +extension "DAMAGE" +extension "GLX" \
    +extension "RANDR" +extension "RENDER" +extension "MIT-SHM" \
    +extension "XFIXES" +extension "XTEST" +iglx +render \
    -nolisten "tcp" -ac -noreset -shmem &

sleep 2

# Start x11vnc on port 5900 (mapped)
x11vnc -display :99 -forever -shared -bg -rfbport 5900 -nopw -noxdamage -noshm 2>&1 &

sleep 2

# Start websockify noVNC
cd /opt/novnc
exec websockify --web /opt/novnc 6080 localhost:5900