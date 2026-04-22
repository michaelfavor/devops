#!/bin/bash
docker run -d --name kde-vm --privileged -p 3389:3389 -p 2222:22 --restart unless-stopped ubuntu2404-kde-rdp

