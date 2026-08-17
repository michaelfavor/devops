# Docker KDE Desktop - Project Status

## Working Solution

Custom image based on `linuxserver/rdesktop:ubuntu-kde` with additional software.

## Build & Run

```bash
docker compose up -d --build
```

## Access

- **RDP:** Connect via RDP client to `localhost:3389`
- **Credentials:** abc / abc

## Files

- `Dockerfile` - Custom build with additional packages
- `docker-compose.yml` - Container configuration
- `run-kde.sh` - Quick start script

## Adding Software

Edit `Dockerfile` and add packages to the apt install line. Rebuild to apply.