FROM lscr.io/linuxserver/rdesktop:ubuntu-kde

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    firefox \
    chromium-browser \
    gimp \
    vlc \
    libreoffice \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*