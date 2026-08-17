# RDP Server Investigation — Status Report

**Date**: 2026-08-16
**Branch**: `main` at commit `cd33a5f cleanup`

## Problem

The RDP server (xrdp on port 3389) fails to start during container initialization. Only `xrdp-sesman` starts. Port 3389 never listens, so RDP connections are refused.

## Root Mechanism (Confirmed)

During s6-overlay initialization, the `svc-xrdp` service fails to start. s6-rc creates a `down` file at:
```
/run/s6-rc/servicedirs/svc-xrdp/down
```
This tells `s6-supervise` to keep the service permanently stopped. The `down` file is recreated on every container restart.

### Evidence
- `s6-supervise svc-xrdp` process exists (PID ~41) but no actual `xrdp` process
- `/run/s6-rc/servicedirs/svc-xrdp/down` file exists (empty file)
- xrdp log (`/var/log/xrdp.log`) has **no entry** for the initial startup attempt
- xrdp-sesman log shows: `Process 270 has exited` right after startup
- The `[ls.io-init] done.` message is missing from container logs (ci-service-check never completes)

### Workaround (Confirmed Working)
Inside the running container:
```bash
docker exec devops rm -f /run/s6-rc/servicedirs/svc-xrdp/down
docker exec devops kill -USR1 $(docker exec devops pgrep -f "s6-supervise svc-xrdp")
```
Or simply start xrdp manually:
```bash
docker exec devops bash -c 'DISPLAY=:1 /usr/sbin/xrdp --nodaemon &'
```
After either approach, xrdp starts and listens on port 3389 normally.

## What We Tested

### Commits Tested (Binary Search)

| Commit | Description | RDP Status |
|--------|-------------|------------|
| Base image `lscr.io/linuxserver/rdesktop:ubuntu-kde` | No custom Dockerfile | ✅ Works |
| `31f1b5a` | set timezone | ✅ Works |
| `b7caa98` | switch to network_mode:host | ✅ Works |
| `cd33a5f` | cleanup | ❌ Broken |

**Note**: When building `cd33a5f` immediately after `b7caa98`, Docker layer caching caused `cd33a5f` to reuse the same image hash as `b7caa98`, making it appear to work. After forcing a fresh rebuild (different image hash), `cd33a5f` is reliably broken.

### Things Ruled Out

- ~~`startwm.sh` deleted~~ — File still exists and is correct
- ~~`network_mode: host` broke RDP~~ — SSH and other ports work fine in host mode
- ~~Deleted scripts (`startkde.sh`, `supervisord.conf`, etc.)~~ — Were old VNC/supervisord remnants, not used by s6-overlay
- ~~`COPY root_data/ /` overwrites xrdp files~~ — Only adds sshd service + SSH keys + wallpapers
- ~~xrdp binary, SSL certs, or dependencies missing~~ — xrdp starts fine manually
- ~~`home_volume` mount interfering~~ — No xrdp-relevant files there

### The Breaking Change

The `cd33a5f cleanup` commit changed the Dockerfile. Meaningful changes (ignoring comments):

1. **`COPY root_data/ /` moved earlier** — from after SSH setup to before SSH setup
2. **VS Code install moved** — from before Docker CLI to after Chrome install
3. **Removed `rm -rf /var/lib/apt/lists/*`** from 3 RUN steps (Docker CLI, Node.js, VS Code)
4. **Cleanup changed** — removed `/usr/share/doc/* /usr/share/man/*` from final cleanup

### What We Haven't Isolated Yet

We tested moving `COPY root_data/ /` back to its original position (after SSH setup) — **still broken**. So it's not just the COPY position.

The next steps are to test each change individually:
- [ ] Test with only change #1 (COPY position)
- [ ] Test with only change #2 (VS Code position)
- [ ] Test with only change #3 (removed apt cleanup)
- [ ] Test with only change #4 (removed doc/man cleanup)
- [ ] Test combinations

### Hypotheses (Unconfirmed)

1. **Layer ordering matters**: Even though the final image content should be the same, the order of Docker layers might affect something at runtime (e.g., s6-overlay compilation order, file ownership/permissions)

2. **Missing apt cleanup causes conflict**: Not running `rm -rf /var/lib/apt/lists/*` after package installs might leave something that conflicts with xrdp

3. **Missing doc/man cleanup removes something xrdp needs**: Unlikely but possible

4. **VS Code install order**: Installing VS Code at a different point in the build might affect some system library or config that xrdp depends on

5. **s6-overlay service compilation**: The `user/contents.d/sshd` symlink (added by `COPY root_data/ /`) might affect how s6-rc compiles the service tree, and the timing of when it's added relative to other layers might matter

## Key Files

- Dockerfile: `/home/michael/docker/devops/Dockerfile`
- docker-compose.yml: `/home/michael/docker/devops/docker-compose.yml`
- root_data (copied into image): `/home/michael/docker/devops/root_data/`
  - `etc/s6-overlay/s6-rc.d/sshd/` — custom sshd service
  - `etc/s6-overlay/s6-rc.d/user/contents.d/sshd` — symlink (tracked by git)
  - `etc/ssh/` — SSH host keys
  - `usr/share/wallpapers/` — wallpaper images
- home_volume (mounted as /config): `/home/michael/docker/devops/home_volume/`

## Commands for Next Session

```bash
# Quick test if RDP is working:
ss -tlnp | grep 3389
docker exec devops ps aux | grep "[x]rdp --nodaemon"

# Quick fix (temporary):
docker exec devops rm -f /run/s6-rc/servicedirs/svc-xrdp/down
docker exec devops kill -USR1 $(docker exec devops pgrep -f "s6-supervise svc-xrdp")

# Rebuild and test:
cd /home/michael/docker/devops
docker-compose down && docker-compose up -d --build
sleep 15 && ss -tlnp | grep 3389

# Compare base image (should work):
docker run --rm lscr.io/linuxserver/rdesktop:ubuntu-kde ps aux | grep xrdp
```

## Docker Image Hashes

| Commit | Image Hash | RDP |
|--------|-----------|-----|
| `31f1b5a` | `98897d8b332a` | ✅ |
| `b7caa98` | `421a89c864f4` | ✅ |
| `cd33a5f` (cached from b7caa98) | `421a89c864f4` (same!) | ✅ (false positive) |
| `cd33a5f` (fresh rebuild) | `64f7b6b5fc92` | ❌ |
