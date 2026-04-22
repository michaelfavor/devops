FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
ARG USERNAME=devuser
ARG PASSWORD=devpass
ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget gnupg2 apt-transport-https \
    dbus-x11 x11-xserver-utils xserver-xorg-core xserver-xorg-video-dummy xinit \
    kde-plasma-desktop sddm \
    xrdp \
    openssh-server \
    supervisor \
    pulseaudio \
    xdg-utils \
 && apt-get clean && rm -rf /var/lib/apt/lists/*


# CREATE USERS AND GROUPS
RUN set -eux; \
    if getent group "${USERNAME}" >/dev/null; then \
      :; \
    else \
      if getent group "${USER_GID}" >/dev/null; then \
        USER_GID=$(awk -F: 'BEGIN{max=1000} {if($3>max) max=$3} END{print max+1}' /etc/group); \
      fi; \
      groupadd -g "${USER_GID}" "${USERNAME}"; \
    fi; \
    if id -u "${USERNAME}" >/dev/null 2>&1; then \
      :; \
    else \
      if getent passwd "${USER_UID}" >/dev/null; then \
        USER_UID=$(awk -F: 'BEGIN{max=1000} {if($3>max) max=$3} END{print max+1}' /etc/passwd); \
      fi; \
      useradd -m -u "${USER_UID}" -g "${USER_GID}" -s /bin/bash "${USERNAME}"; \
    fi; \
    echo "${USERNAME}:${PASSWORD}" | chpasswd; \
    mkdir -p /var/run/sshd /home/"${USERNAME}"/.ssh; \
    chown -R "${USERNAME}":"${USERNAME}" /home/"${USERNAME}"

RUN mkdir -p /etc/X11/xorg.conf.d
RUN printf '%s\n' \
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

RUN sed -i 's/^address=127.0.0.1/address=0.0.0.0/' /etc/xrdp/xrdp.ini || true

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 3389 22
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
