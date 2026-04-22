#!/bin/bash
docker run -d \
  --name kde-dev \
  --hostname kde-dev \
  -p 3389:3389 \
  -p 2222:22 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -v /home/michael/docker/test/rdesktop-kde:/config \
  lscr.io/linuxserver/rdesktop:ubuntu-kde
