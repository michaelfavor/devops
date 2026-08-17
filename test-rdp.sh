#!/bin/bash
# Unit test: build Dockerfile and check if RDP (port 3389) starts
# Usage: ./test-rdp.sh [label]
set -e

LABEL="${1:-unnamed}"
TIMEOUT=60
PASS=0

echo "=== Testing: $LABEL ==="

# Build with --no-cache to avoid layer cache contamination
echo "Building (this may take 8-12 minutes)..."
if ! docker build --no-cache -t devops-test-rdp . > /tmp/build.log 2>&1; then
    echo "FAIL: Build failed (see /tmp/build.log)"
    exit 1
fi
echo "Build OK"

# Start container
docker rm -f devops-test 2>/dev/null || true
docker run -d --name devops-test --network host \
    -v "$(pwd)/home_volume:/config" \
    -e PUID=1000 -e PGID=1000 -e TZ=America/Los_Angeles \
    devops-test-rdp

echo "Waiting ${TIMEOUT}s for services..."
sleep $TIMEOUT

# Check RDP
if ss -tlnp | grep -q ':3389'; then
    echo "PASS: RDP (3389) is listening"
    PASS=1
else
    echo "FAIL: RDP (3389) is NOT listening"
    
    # Diagnostics
    echo "--- Diagnostics ---"
    docker exec devops-test ps aux | grep -E 'xrdp|s6-supervise' | grep -v grep || true
    docker exec devops-test ls /run/s6-rc/servicedirs/svc-xrdp/down 2>/dev/null && echo "(down file exists)" || echo "(no down file)"
    docker exec devops-test cat /var/log/xrdp.log 2>/dev/null | tail -5 || echo "(no xrdp log)"
    docker logs devops-test 2>&1 | grep -i "ls.io-init\|error\|fail" | tail -10 || true
fi

# Cleanup
docker rm -f devops-test > /dev/null 2>&1
docker rmi devops-test-rdp > /dev/null 2>&1

echo "=== $LABEL: $([ $PASS -eq 1 ] && echo PASS || echo FAIL) ==="
exit $((1 - PASS))
