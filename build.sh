#!/bin/bash
docker stop devops
docker rm devops
docker-compose up -d --build

