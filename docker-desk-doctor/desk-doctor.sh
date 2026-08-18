#!/bin/sh
# desk-doctor — verify the docker-desk environment is healthy, and repair
# what it can.
#
# Usage:
#   desk-doctor           check and repair
#   desk-doctor --check   report only, change nothing
#
# Designed to be safe to run any number of times. It only ADDS missing
# pieces; it never deletes or overwrites existing user data. Files that
# already exist are left exactly as they are.

set -u

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

PASS=0; FIXED=0; WARN=0; FAIL=0
ok()   { printf '  OK      %s\n' "$1"; PASS=$((PASS+1)); }
fixed(){ printf '  FIXED   %s\n' "$1"; FIXED=$((FIXED+1)); }
warn() { printf '  WARN    %s\n' "$1"; WARN=$((WARN+1)); }
fail() { printf '  FAILED  %s\n' "$1" >&2; FAIL=$((FAIL+1)); }

DEFAULTS_DIR=/usr/local/share/docker-desk/defaults
SEED_DIR=/usr/share/docker-desk/seed-config
AGENT_DIR="${HOME:-/root}/.pi/agent"

echo "[1/5] required binaries"
for b in pi node npm git python3 google-chrome-stable; do
  if command -v "$b" >/dev/null 2>&1; then
    ok "$b"
  else
    fail "$b not found in PATH"
  fi
done

echo "[2/5] pi packages"
if ! command -v pi >/dev/null 2>&1; then
  fail "pi missing; cannot manage pi packages"
else
  ensure_pi_package() {
    # pi list prints package names as "  <spec>" with no trailing space
    if pi list 2>/dev/null | grep -q "^  $1$"; then
      ok "installed: $1"
    elif [ "$CHECK_ONLY" -eq 1 ]; then
      fail "missing: $1"
    elif pi install "$1" >/dev/null 2>&1; then
      fixed "installed: $1"
    else
      fail "pi install failed: $1"
    fi
  }
  ensure_pi_package npm:pi-web-access
  ensure_pi_package npm:@narumitw/pi-chrome-devtools
fi

echo "[3/5] seed home from image defaults"
# The image keeps a snapshot of its /config skeleton (VS Code settings,
# desktop shortcuts, ...) at an unshadowed path, because the runtime bind
# mount hides the image's /config. Seed any missing files; never overwrite
# files the user already has.
if [ -d "$SEED_DIR" ]; then
  if [ "$CHECK_ONLY" -eq 1 ]; then
    warn "seed config present but not applied (run without --check to seed)"
  elif cp -an "$SEED_DIR/." "$HOME/" 2>/dev/null; then
    ok "home seeded (missing files only, existing files untouched)"
  else
    fail "could not seed $HOME from $SEED_DIR"
  fi
else
  ok "no seed config in image (nothing to do)"
fi

echo "[4/5] pi agent state ($AGENT_DIR)"
if [ -d "$AGENT_DIR" ]; then
  ok "agent dir present"
elif [ "$CHECK_ONLY" -eq 1 ]; then
  fail "agent dir missing: $AGENT_DIR"
else
  if mkdir -p "$AGENT_DIR"; then fixed "created $AGENT_DIR"; else fail "could not create $AGENT_DIR"; fi
fi

# Restore missing key files from the image defaults. Never overwrites
# an existing file — user edits always win.
for f in settings.json; do
  if [ -f "$AGENT_DIR/$f" ]; then
    ok "present: $f"
    continue
  fi
  if [ -f "$DEFAULTS_DIR/$f" ]; then
    if [ "$CHECK_ONLY" -eq 1 ]; then
      fail "missing (default available): $f"
    elif cp "$DEFAULTS_DIR/$f" "$AGENT_DIR/$f"; then
      fixed "restored $f from image defaults"
    else
      fail "could not restore $f"
    fi
  else
    fail "missing and no default available: $f"
  fi
done

if [ ! -f "$AGENT_DIR/models.json" ]; then
  warn "models.json missing — run: pi update --models"
fi

echo "[5/5] playwright (global)"
if python3 -c "import playwright" >/dev/null 2>&1; then
  ok "playwright importable"
  # `playwright install --dry-run` lists every component with its install
  # location; flag any whose directory is missing.
  MISSING_BROWSERS="$(python3 -m playwright install --dry-run chromium 2>/dev/null \
    | awk '/Install location:/{print $3}' \
    | while IFS= read -r loc; do [ -n "$loc" ] && [ ! -d "$loc" ] && echo "$loc"; done)"
  if [ -z "$MISSING_BROWSERS" ]; then
    ok "chromium browsers present"
  elif [ "$CHECK_ONLY" -eq 1 ]; then
    fail "missing browser components:$MISSING_BROWSERS"
  elif python3 -m playwright install chromium >/dev/null 2>&1; then
    fixed "installed chromium browsers"
  else
    fail "playwright install chromium failed"
  fi
else
  if [ "$CHECK_ONLY" -eq 1 ]; then
    fail "playwright not importable"
  elif python3 -m pip install --break-system-packages playwright >/dev/null 2>&1; then
    fixed "installed playwright"
    python3 -m playwright install chromium >/dev/null 2>&1 \
      && fixed "installed chromium browsers" \
      || fail "playwright install chromium failed"
  else
    fail "pip install playwright failed"
  fi
fi

echo
echo "desk-doctor done: $PASS ok, $FIXED fixed, $WARN warning(s), $FAIL failed"
[ "$FAIL" -gt 0 ] && exit 1
exit 0
