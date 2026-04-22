# syntax=docker/dockerfile:1
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# =============================================================================
# BASE LAYER - Packages that rarely change (cached)
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget gnupg2 apt-transport-https \
    dbus-x11 x11-xserver-utils xserver-xorg-core xserver-xorg-video-dummy xinit \
    xfce4 xfce4-goodies \
    xrdp \
    openssh-server \
    supervisor \
    pulseaudio \
    xdg-utils \
    libgl1 \
    libxkbcommon0 \
    libxkbcommon-x11-0 \
    libxcb-xinerama0 \
    libxcb-cursor0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-shape0 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# =============================================================================
# USER CONFIGURATION - rarely changes
# =============================================================================
RUN echo "ubuntu:ubuntu" | chpasswd && \
    mkdir -p /var/run/sshd /home/ubuntu/.ssh && \
    chown -R ubuntu:ubuntu /home/ubuntu

# =============================================================================
# X11 CONFIGURATION - rarely changes
# =============================================================================
RUN mkdir -p /etc/X11/xorg.conf.d && \
    printf '%s\n' \
    'Section "Device"' \
    '  Identifier  "DummyDevice"' \
    '  Driver      "dummy"' \
    '  VideoRam    256000' \
    'EndSection' \
    '' \
    'Section "Monitor"' \
    '  Identifier "DummyMonitor"' \
    '  HorizSync 31.5-48.5' \
    '  VertRefresh 50-70' \
    'EndSection' \
    '' \
    'Section "Screen"' \
    '  Identifier "DummyScreen"' \
    '  Device "DummyDevice"' \
    '  Monitor "DummyMonitor"' \
    '  DefaultDepth 24' \
    '  SubSection "Display"' \
    '    Depth 24' \
    '    Modes "1920x1080"' \
    '  EndSubSection' \
    'EndSection' \
    > /etc/X11/xorg.conf.d/10-dummy.conf

# =============================================================================
# xRDP CONFIGURATION
# =============================================================================
RUN sed -i 's/^address=127.0.0.1/address=0.0.0.0/' /etc/xrdp/xrdp.ini || true

RUN cat > /etc/xrdp/xorg.conf << 'XORGCONF'
Section "ServerLayout"
    Identifier "X.org Configured"
    Screen "Screen0" 0 0
    InputDevice "Mouse0" "CorePointer"
    InputDevice "Keyboard0" "CoreKeyboard"
EndSection

Section "Files"
    ModulePath "/usr/lib/xorg/modules"
    FontPath "/usr/share/fonts/X11:/usr/share/fonts/ttf"
EndSection

Section "Module"
    Load "dri"
    Load "extmod"
    Load "dbe"
    Load "glx"
EndSection

Section "InputDevice"
    Identifier "Keyboard0"
    Driver "kbd"
    Option "Protocol" "std"
    Option "XkbRules" "xfree86"
    Option "XkbModel" "pc105"
    Option "XkbLayout" "us"
EndSection

Section "InputDevice"
    Identifier "Mouse0"
    Driver "mouse"
    Option "Protocol" "auto"
    Option "Device" "/dev/input/mice"
    Option "Emulate3Buttons" "false"
EndSection

Section "Monitor"
    Identifier "Monitor0"
    VendorName "Monitor Vendor"
    ModelName "Monitor Model"
    HorizSync 30-80
    VertRefresh 50-120
EndSection

Section "Device"
    Identifier "Card0"
    Driver "dummy"
    VideoRam 256000
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "Card0"
    Monitor "Monitor0"
    DefaultDepth 24
    SubSection "Display"
        Viewport 0 0
        Depth 24
        Modes "1920x1080" "1024x768"
    EndSubSection
EndSection
XORGCONF

# =============================================================================
# SESSION STARTUP SCRIPT - THIS IS WHAT WE CHANGE MOST DURING DEVELOPMENT
# =============================================================================
RUN cat > /etc/xrdp/startwm.sh << 'WMSCRIPT'
#!/bin/sh
exec > /tmp/startwm.log 2>&1
set -x
USER=ubuntu
HOME=/home/ubuntu
export USER LOGNAME HOME
export HOME
export XDG_RUNTIME_DIR=/tmp/runtime-1000
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
chown ubuntu:ubuntu "$XDG_RUNTIME_DIR"
. /etc/profile
if [ -f "$HOME/.xsession" ]; then
    . "$HOME/.xsession"
elif which icewm >/dev/null 2>&1; then
    # icewm is simple - just exec it
    exec icewm
else
    # fallback to xfce
    export XDG_CURRENT_DESKTOP=xfce
    export XDG_SESSION_TYPE=x11
    if which startxfce4 >/dev/null 2>&1; then
        dbus-launch --exit-with-session startxfce4
    fi
fi
WMSCRIPT
RUN chmod +x /etc/xrdp/startwm.sh

# =============================================================================
# FINAL CONFIG
# =============================================================================
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 3389 22
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
