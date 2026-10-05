# =============================================================================
# Virtual Desktop and Development Environment with Remote Access by RDP and SSH 
# =============================================================================
# Based on LinuxServer Remote Ubuntu KDE
# 
# Port 3389: RDP Remote Desktop
# Port 2222: SSH Secure Shell
#
# IMPORTANT Login Credentials -- user: abc  password: abc (change with passwd)
#
# =============================================================================

FROM lscr.io/linuxserver/rdesktop:ubuntu-kde

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PUID=1000 \
    PGID=1000 \
    TZ=America/Los_Angeles

# Set Timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Switch to root for system installation
USER root

# Restores many standard packages needed by users who log in.  By default these
# packages are omitted from the rdesktop:ubuntu-kde to minimize container size
RUN yes | /usr/bin/unminimize

# =============================================================================
# Update and Install System Software
# =============================================================================

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    # System utilities
    curl \
    git \
    htop \
    lsof \
    less \
    members \
    neofetch \
    nano \
    rsync \
    ssh \
    sqlite3 \
    supervisor \
    tmux \
    unzip \
    vim \
    wget \
    zip \
    # Network essentials
    avahi-utils \
    avahi-daemon \
    ca-certificates \
    cifs-utils \
    dnsmasq \
    iproute2 \
    iputils-ping \
    net-tools \
    openssh-server \
    gpg \
    socat \
    strace \
    smbclient \
    # Build essentials
    build-essential \
    cmake \
    flake8 \
    git-lfs \
    golang-go \
    libnccl2 \
    libnccl-dev \
    libnss-mdns \
    # Python ecosystem
    python3 \
    python3-pip \
    python3-venv \
    python-is-python3 \
    pipx \
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
    # GUI apps
    chromium-browser \
    firefox \
    fonts-liberation \
    fonts-liberation-sans-narrow \
    gimp \
    libreoffice \
    vlc \
    xterm

RUN apt-get install -y nvidia-cuda-toolkit

#RUN apt-get install -y --no-install-recommends \
    # google-chrome-stable \

# =============================================================================
# Copy files: /usr/share/wallpapers, /etc/ssh, /etc/s6-overlay services (xrdp fixes, sshd), /etc/X11/xrdp (resolution)
# =============================================================================
COPY root_data/ /

# =============================================================================
# Setup SSH Server
# =============================================================================
RUN mkdir -p /run/sshd \
    && echo "Port 2222" >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config

# =============================================================================
# INSTALL DOCKER CLI (for Docker-in-Docker workflows)
# =============================================================================
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli

# =============================================================================
# INSTALL LATEST NODE.JS (via NodeSource - gets Node 22 LTS)
# =============================================================================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn pnpm

# =============================================================================
# INSTALL HUGGINGFACE TOOLS
# =============================================================================
RUN pipx install huggingface-hub
RUN pipx inject huggingface-hub hf_transfer

# =============================================================================
# INSTALL AI CODING AGENTS
# =============================================================================
# kilocode
RUN npm install -g kilocode
# opencode
#RUN go install github.com/opencode-ai/opencode@latest
RUN npm install -g opencode-ai
# qwencode
RUN npm install -g @qwen-code/qwen-code@latest
# pi.dev
# NOTE: pi packages are NOT installed here. Build runs as root (HOME=/root),
# so they would land in /root/.pi which the runtime user never sees, and
# /config is bind-mounted at runtime anyway. desk-doctor installs them on
# demand at startup (s6 one-shot task).
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent
# Chrome for use by pi-chrome-devtools
RUN wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \                                                                                                                                                                                                
    && apt-get install -y /tmp/chrome.deb \                                                                                                                                                                                                                                                               
    && rm /tmp/chrome.deb

# =============================================================================
# INSTALL VS Code - Visual Studio
# =============================================================================
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' && \
    rm -f packages.microsoft.gpg && \
    apt-get update && \
    apt-get install -y code

# Configure VS Code for remote development
# =============================================================================
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
# =============================================================================
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

RUN pip install --no-user --break-system-packages pexpect fastapi uvicorn zstandard

# =============================================================================
# BATTERIES: global playwright (system site, not user site) + chromium
# =============================================================================
# --no-user matters: pip defaults to user site (~/.local) which would land
# under /config and be shadowed by the runtime bind mount.
RUN python3 -m pip install --break-system-packages --no-user --no-cache-dir pexpect fastapi uvicorn zstandard
RUN python3 -m pip install --break-system-packages --no-user --no-cache-dir "playwright==1.61.0" \
 && python3 -m playwright install chromium

# =============================================================================
# SEED SNAPSHOT: copy /config defaults to an unshadowed path
# =============================================================================
# /config is bind-mounted at runtime, hiding the image's /config.
# Snapshot it here so desk-doctor can seed a fresh home_volume.
# Must run AFTER everything that writes to /config above.
RUN mkdir -p /usr/share/docker-desk/seed-config && cp -a /config/. /usr/share/docker-desk/seed-config/

# Convenience symlink — points to bind mount so edits are picked up live.
RUN ln -s /usr/local/share/docker-desk-doctor/desk-doctor.sh /usr/local/bin/desk-doctor

# =============================================================================
# Ensure hostname resolves in /etc/hosts (needed for host networking mode)
# In host mode, /etc/hosts is shared with the host — Docker does not inject
# the container's hostname automatically, so sudo/other tools that do
# hostname lookups will hang until they timeout.
# =============================================================================
#RUN echo "127.0.1.1 dock" >> /etc/hosts

# =============================================================================
# Cleanup - remove temp files to minimize image size
# =============================================================================
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
