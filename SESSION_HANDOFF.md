# Session Handoff — RDP Investigation (Final)

**Date**: 2026-08-17
**Branch**: `main` at commit `cd33a5f cleanup`
**Status**: ✅ FIXED

---

## Root Cause

The `s6-notifyoncheck` health checks in the xrdp/xrdp-sesman run scripts use `nc -z localhost PORT`. Under `network_mode: host`, the host's `systemd-resolved` (127.0.0.53) causes `nc` to resolve `localhost` → `127.0.0.1` (IPv4). But xrdp-sesman binds to `::1` (IPv6) only, so the health check fails.

Under port mapping, Docker's DNS resolves `localhost` → `::1` (IPv6), so the check passes.

### Chain of failure:
1. `s6-notifyoncheck -w 500 -c "nc -z localhost 3350"` fails (IPv4 → IPv6 mismatch)
2. s6-rc never receives the "ready" notification for svc-xrdp-sesman
3. s6-rc marks svc-xrdp-sesman as DOWN (creates `down` file)
4. svc-xrdp depends on svc-xrdp-sesman, so it's also marked DOWN
5. `legacy-services` never completes (waits for all longrun services)
6. `ci-service-check` never runs → `[ls.io-init] done.` never printed

### Evidence:
```bash
# Host mode: nc resolves localhost → 127.0.0.1 (IPv4) → FAILS
$ nc -z localhost 3350  # FAILED
$ nc -z 127.0.0.1 3350  # FAILED
$ nc -z ::1 3350        # SUCCESS ✅

# Port mapping: nc resolves localhost → ::1 (IPv6) → succeeds
$ nc -z localhost 3350  # Connection to localhost (::1) 3350 port succeeded ✅
```

---

## Fix

Override the xrdp run scripts in `root_data/etc/s6-overlay/s6-rc.d/` to use `::1` instead of `localhost`:

**`root_data/etc/s6-overlay/s6-rc.d/svc-xrdp-sesman/run`**:
```execline
s6-notifyoncheck -w 500 -c "nc -z ::1 3350"
```

**`root_data/etc/s6-overlay/s6-rc.d/svc-xrdp/run`**:
```execline
s6-notifyoncheck -w 500 -c "nc -z ::1 3389"
```

---

## Verification

After fix, with `network_mode: host`:
- ✅ Port 3389 (RDP) listening
- ✅ Port 2222 (SSH) listening
- ✅ All services UP: svc-xrdp, svc-xrdp-sesman, svc-cron, sshd
- ✅ `[ls.io-init] done.` in container logs
- ✅ RDP connections work

---

## Artifacts

| File | Purpose |
|------|---------|
| `root_data/etc/s6-overlay/s6-rc.d/svc-xrdp/run` | Fixed xrdp run script |
| `root_data/etc/s6-overlay/s6-rc.d/svc-xrdp-sesman/run` | Fixed xrdp-sesman run script |

---

## Commands for Quick Reference

```bash
# Check RDP status
ss -tlnp | grep 3389

# Check s6-rc service states
docker exec devops bash -c 'for svc in /run/s6-rc/servicedirs/svc-*/; do name=$(basename "$svc"); [ -f "$svc/down" ] && echo "DOWN: $name" || echo "UP:   $name"; done'

# Check init completion
docker logs devops 2>&1 | grep "ls.io-init"

# Test nc resolution
docker exec devops bash -c 'nc -z ::1 3350 && echo "sesman OK" || echo "sesman FAIL"'
docker exec devops bash -c 'nc -z ::1 3389 && echo "xrdp OK" || echo "xrdp FAIL"'
```
