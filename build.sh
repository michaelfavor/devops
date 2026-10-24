#!/bin/bash
# ssh file permissions must be 600
chmod 600 root_data/etc/ssh/ssh*
# rebuild docker container
docker stop docker-desk
docker rm docker-desk
docker compose down
docker compose up -d --build

