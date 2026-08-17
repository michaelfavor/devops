# Docker KDE Desktop — DevOps Workstation

Full-featured virtual desktop and development environment with remote access via **RDP** and **SSH**, running in a Docker container based on [linuxserver/rdesktop](https://hub.docker.com/r/linuxserver/rdesktop).

## Quick Start

```bash
docker compose up -d --build
```

## Access

| Protocol | Port | Credentials |
|----------|------|-------------|
| **RDP**  | 3389 | `abc` / `abc` |
| **SSH**  | 2222 | `abc` / `abc` |

> **Change your password** after first login: `passwd`

## Volumes

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `./home_volume/` | `/config` | User home directory (persists across rebuilds) |
| `./projects/` | `/projects` | Project workspace |

## Included Software

### Development Tools
- **Editors/IDEs**: VS Code, vim, nano
- **Languages**: Node.js 22 (npm, yarn, pnpm), Python 3 (pip, pipx, venv), Go, Java (default-jdk)
- **AI Coding Agents**: [pi.dev](https://pi.dev), kilocode, opencode, qwen-code
- **Version Control**: git, git-lfs
- **Docker CLI**: For Docker-in-Docker workflows

### GUI Applications
- Chromium, Firefox, GIMP, LibreOffice, VLC

### System Utilities
- htop, tmux, strace, net-tools, iproute2, avahi, CIFS/SMB clients

## Configuration

### Screen Resolution

RDP defaults to **1920x1080**. To change, edit `root_data/etc/X11/xrdp/xorg.conf` and reorder the `Modes` line in the Screen section — the first mode is preferred. Rebuild to apply.

### Networking

The container uses `network_mode: host` so services listen directly on the host. No port mapping needed.

### Adding Packages

Edit the `apt-get install` section in `Dockerfile`, then rebuild:

```bash
docker compose up -d --build
```

## Troubleshooting

### Verify services are running

```bash
# Check ports
ss -tlnp | grep -E '3389|2222'

# Check s6 service states
docker exec devops bash -c 'for svc in /run/s6-rc/servicedirs/svc-*/; do name=$(basename "$svc"); [ -f "$svc/down" ] && echo "DOWN: $name" || echo "UP:   $name"; done'

# Check init completed
docker logs devops 2>&1 | grep "ls.io-init"
```

### RDP won't connect

If `[ls.io-init] done.` is missing from logs, the s6-overlay health checks may have failed. Rebuild with `--no-cache` to ensure the latest fixes are applied:

```bash
docker compose down
docker compose up -d --build --no-cache
```

## Project Structure

```
├── Dockerfile              # Custom image build
├── docker-compose.yml      # Container configuration
├── build.sh                # Convenience rebuild script
├── root_data/              # Files copied into the image
│   ├── etc/X11/xrdp/       # xorg.conf (screen resolution)
│   ├── etc/s6-overlay/     # Service overrides (xrdp, sshd)
│   ├── etc/ssh/            # SSH host keys
│   └── usr/share/wallpapers/
├── home_volume/            # Persisted user home (/config)
└── projects/               # Persisted workspace (/projects)
```

## Base Image

Built on [`lscr.io/linuxserver/rdesktop:ubuntu-kde`](https://hub.docker.com/r/linuxserver/rdesktop/tags?name=ubuntu-kde).
