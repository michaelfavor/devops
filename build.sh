#!/bin/bash
docker stop kde-vm
docker rm kde-vm
docker-compose up -d --build

