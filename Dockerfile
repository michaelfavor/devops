FROM lscr.io/linuxserver/rdesktop:ubuntu-kde

ARG DEBIAN_FRONTEND=noninteractive

# Install openssh-server and configure
RUN apt-get update && apt-get install -y \
    firefox \
    chromium-browser \
    gimp \
    vlc \
    libreoffice \
    openssh-server

RUN apt-get install -y \
    iproute2 \
    nano \
    strace

# Clean up Temp files
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup SSH Server
RUN mkdir -p /run/sshd \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config

# Copy s6-overlay service for sshd
COPY root_data/ /
