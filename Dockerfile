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


# =============================================================================
# Setup SSH Server
# =============================================================================
RUN mkdir -p /run/sshd \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config

# Copy s6-overlay service for sshd
COPY root_data/ /

# INSTALL Visual Studio VS-CODE
# =============================================================================
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' && \
    rm -f packages.microsoft.gpg && \
    apt-get update && \
    apt-get install -y code && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# INSTALL DOCKER CLI (for Docker-in-Docker workflows)
# =============================================================================
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# INSTALL LATEST NODE.JS (via NodeSource - gets Node 20 LTS)
# =============================================================================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn pnpm && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# INSTALL CODING AGENTS
# =============================================================================
# kilocode
RUN npm install -g kilocode
# opencode
#RUN go install github.com/opencode-ai/opencode@latest
RUN npm install -g opencode-ai
# qwencode
RUN npm install -g @qwen-code/qwen-code@latest
# pi.dev
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# =============================================================================
# CONFIGURE DESKTOP ENVIRONMENT
# =============================================================================
# Pre-configure VS Code settings for remote development
RUN mkdir -p /config/.config/Code/User && \
    cat > /config/.config/Code/User/settings.json << 'EOF'
{
    "workbench.colorTheme": "Dark+ (default dark)",
    "editor.fontSize": 14,
    "terminal.integrated.defaultProfile.linux": "bash",
    "window.restoreWindows": "none",
    "workbench.startupEditor": "newUntitledFile",
    "remote.autoForwardPorts": true
}
EOF

# Create desktop shortcut for VS Code
RUN mkdir -p /config/Desktop && \
    cat > /config/Desktop/code.desktop << 'EOF'
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=/usr/bin/code --no-sandbox --unity-launch %F
Icon=vscode
Type=Application
StartupNotify=false
StartupWMClass=Code
Categories=Utility;TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;application/x-code-workspace;
Actions=new-empty-window;
Keywords=vscode;

[Desktop Entry Action new-empty-window]
Name=New Empty Window
Exec=/usr/bin/code --no-sandbox --new-window %F
Icon=vscode
EOF

RUN chmod +x /config/Desktop/code.desktop

# Cleanup - remove temp files to minimize image size
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /usr/share/man/*
