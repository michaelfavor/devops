# =============================================================================
# Virtual Desktop and Development Environment with Remote Access by RDP and SSH 
# =============================================================================
# Based on LinuxServer Remote Ubuntu KDE
# 
# Port 3389: RDP Remote GUI Desktop
# Port 2222: SSH Secure Shell Terminal
# Login user/pass: abc / abc (change with passwd)
# =============================================================================

FROM lscr.io/linuxserver/rdesktop:ubuntu-kde

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PUID=1000 \
    PGID=1000 \
    TZ=America/Los_Angeles

# Switch to root for system installation
USER root

# Restore packages normally needed by users who log in
RUN yes | /usr/bin/unminimize

# =============================================================================
# Update and Install System Software
# =============================================================================

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    # System utilities
    htop \
    lsof \
    less \
    members \
    neofetch \
    nano \
    supervisor \
    tmux \
    vim \
    unzip \
    zip \
    # Network essentials
    avahi-utils \
    avahi-daemon \
    dnsmasq \
    iproute2 \
    iputils-ping \
    net-tools \
    openssh-server \
    strace \
    # VS Code dependencies
    libnss3 \
    libgtk-3-0 \
    libgbm1 \
    libasound2t64 \
    libsecret-1-0 \
    # Build essentials
    build-essential \
    curl \
    wget \
    git \
    git-lfs \
    golang-go \
    ssh \
    # Python ecosystem
    python3 \
    python3-pip \
    python3-venv \
    python-is-python3 \
    # Node.js ecosystem
    nodejs \
    npm \
    # Java
    default-jdk \
    # VS Code dependencies
    libnss3 \
    libgtk-3-0 \
    libgbm1 \
    libasound2t64 \
    libsecret-1-0 \
    # GUI apps for testing
    chromium-browser \
    firefox \
    gimp \
    libreoffice \
    vlc \
    xterm \
    # Misc
    libnss-mdns

# Clean up Temp files
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup SSH Server
RUN mkdir -p /run/sshd \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config

# Copy s6-overlay service for sshd
COPY root_data/ /
