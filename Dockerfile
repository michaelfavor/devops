# syntax=docker/dockerfile:1
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget gnupg2 \
    dbus-x11 xserver-xorg-video-dummy \
    kde-plasma-desktop plasma-desktop plasma-workspace kwin-x11 \
    pulseaudio xvfb websockify python3-novnc x11vnc \
    openssh-server \
    supervisor \
    xdg-utils \
    nginx \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN echo "ubuntu:ubuntu" | chpasswd && \
    mkdir -p /var/run/sshd /home/ubuntu/.ssh && \
    chown -R ubuntu:ubuntu /home/ubuntu

RUN mkdir -p /etc/X11/xorg.conf.d && cat > /etc/X11/xorg.conf.d/10-dummy.conf << 'EOF'
Section "Device"
  Identifier  "DummyDevice"
  Driver      "dummy"
  VideoRam    256000
EndSection

Section "Monitor"
  Identifier "DummyMonitor"
  HorizSync 31.5-48.5
  VertRefresh 50-70
EndSection

Section "Screen"
  Identifier "DummyScreen"
  Device "DummyDevice"
  Monitor "DummyMonitor"
  DefaultDepth 24
  SubSection "Display"
    Depth 24
    Modes "1920x1080"
  EndSubSection
EndSection
EOF

RUN mkdir -p /tmp/runtime-1000 && chown ubuntu:ubuntu /tmp/runtime-1000 && chmod 700 /tmp/runtime-1000

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY startkde.sh /startkde.sh
RUN chmod +x /startkde.sh

EXPOSE 6080 22
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]