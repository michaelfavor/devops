# Docker Desktop Environment - Project Status

## Goal
Create a Docker container running a graphical desktop environment accessible via RDP (xRDP) and SSH.

## Current State (Updated with XFCE Test)

### Working
- SSH access on port 2222 ✓
- xRDP accepts connections and login completes ✓
- Container runs with supervisor managing services
- **XFCE components ARE running** (xfwm4, xfce4-panel, Thunar, etc. all executing)

### Not Working - Visual Display Issue
- Desktop appears as black screen with 1-pixel colored line at top
- The 1-pixel line may be garbled/corrupted panel rendering

### Key Finding from xfce4 log
```
X server already running on display :10.0
Another compositing manager is running on screen 0
```
XFCE is executing but something is conflicting with compositing/rendering.

## What's Been Tried

### Desktop Environments
1. **KDE Plasma** (kde-plasma-desktop) - FAILED
   - Session starts but kwin fails: "Could not find any platform plugin"
   - QStandardPaths errors about XDG_RUNTIME_DIR
   - Polkit authentication failures

2. **XFCE4** (current) - RUNNING but not displaying
   - Installed xfce4 xfce4-goodies
   - All components running (confirmed via process list)
   - Shows black screen with 1-pixel colored line at top
   - Compositing conflict warning

3. **IceWM** - NOT TESTED YET

### Configuration Changes
- XDG_RUNTIME_DIR moved from /run to /tmp (permission issue - FIXED)
- Qt platform settings adjusted
- dbus-daemon session launch before desktop
- startwm.sh script with proper environment variables

### Dockerfile Optimization
- Combined related RUN commands into single layers for caching ✓
- Base packages layer should now cache properly between builds

## Technical Analysis

### What's Running (confirmed)
```
/usr/lib/xorg/Xorg :10 -auth .Xauthority -config xrdp/xorg.conf
dbus-daemon --session
xfwm4 (window manager)
xfce4-panel
Thunar (file manager)
```

### Likely Issue
The compositing manager warning suggests xfwm4 is fighting with xRDP's internal rendering. The 1-pixel line is probably a corrupted/garbled display buffer being rendered.

### Possible Fixes to Try
1. Disable compositing in XFCE settings
2. Add `--vcompositor` off flag to xfwm4
3. Try icewm as simpler test case
4. Check xrdp sesman.ini session settings
5. Use different color depth (16 vs 24)

## Next Steps (Priority Order)

### 1. Test icewm (Immediate)
Quick test - simplest window manager:
```bash
# Edit startwm.sh to use:
exec /usr/bin/icewm
```

### 2. Disable XFCE Compositing (If icewm works)
Add to startwm.sh before starting XFCE:
```bash
xfconf-query -c xfwm4 -p /general/use_compositing -s false
```

### 3. Try lower color depth
Modify xrdp.ini: `max_bpp=16` instead of 24

### 4. Check xrdp sesman settings
Look at /etc/xrdp/sesman.ini for session configuration

## Files

- `Dockerfile` - container definition
- `supervisord.conf` - service management  
- `run.sh` - container startup
- `build.sh` - docker build wrapper
- `PROJECT_STATUS.md` - this file

## Quick Commands

```bash
# Build (should use cached layers)
./build.sh

# Run
./run.sh

# Debug - check session log
docker exec kde-vm cat /tmp/startwm.log

# Debug - check running processes  
docker exec kde-vm ps aux

# Debug - check display
docker exec kde-vm env | grep DISPLAY

# Shell access
docker exec -it kde-vm /bin/bash
```