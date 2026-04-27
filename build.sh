#!/bin/bash
docker stop devops
docker rm devops
#mkdir -p root_data/etc/ssh && sudo cp /etc/ssh/ssh_host_*_key* root_data/etc/ssh/
docker-compose up -d --build

