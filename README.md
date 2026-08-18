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
| `./docker-desk-doctor/` | `/usr/local/share/docker-desk-doctor/` | Self-heal script (live edits) |

## Included Software

### Development Tools
- **Editors/IDEs**: VS Code, vim, nano
- **Languages**: Node.js 22 (npm, yarn, pnpm), Python 3 (pip, pipx, venv), Go, Java (default-jdk)
- **AI Coding Agents**: [pi.dev](https://pi.dev), kilocode, opencode, qwen-code
- **Browser Automation**: Playwright 1.61.0 (global) + Chromium browsers
- **Version Control**: git, git-lfs
- **Docker CLI**: For Docker-in-Docker workflows

### GUI Applications
- Chromium, Firefox, GIMP, LibreOffice, VLC

### Self-Heal
- **desk-doctor**: 13-check idempotent health script. Runs automatically at startup via s6-overlay. Verifies required binaries, pi packages, playwright, and seeds fresh home volumes.

```bash
docker exec -it docker-desk desk-doctor        # check + repair
docker exec -it docker-desk desk-doctor --check # report only
```

## Configuration

### Seed Files

Default config files are placed in `root_data/config/` and seeded into new containers at build time. Existing volume files are never overwritten.

| File | Purpose |
|------|---------|
| `.tmux.conf` | Enables extended-keys support (`set -g extended-keys on`) |
| `.bashrc` | Adds `~/.local/bin` to PATH, sets `COLORTERM=truecolor` for 256-color support |

To modify, edit the file in `root_data/config/` and rebuild:
```bash
docker compose up -d --build
```

### Screen Resolution

RDP resolution matches your RDP client window size. Connect fullscreen for maximum resolution.

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
├── Dockerfile                    # Custom image build
├── docker-compose.yml            # Container configuration
├── build.sh                      # Convenience rebuild script
├── PROJECT_LOG.md                # Decision log and learnings
├── docker-desk-doctor/           # Self-heal script (bind-mounted live)
│   ├── desk-doctor.sh            # Main script
│   └── defaults/                 # Default config files
├── root_data/                    # Files copied into the image
│   ├── config/                   # Seed configs (.tmux.conf, .bashrc)
│   ├── etc/X11/xrdp/             # xorg.conf (screen resolution)
│   ├── etc/s6-overlay/           # Service overrides (xrdp, sshd, desk-doctor)
│   ├── etc/ssh/                  # SSH host keys
│   └── usr/share/wallpapers/
├── home_volume/                  # Persisted user home (/config)
└── projects/                     # Persisted workspace (/projects)
```

## Base Image

Built on [`lscr.io/linuxserver/rdesktop:ubuntu-kde`](https://hub.docker.com/r/linuxserver/rdesktop/tags?name=ubuntu-kde).
