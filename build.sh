#!/bin/bash
# permissions must be set to 600 on ssh files
cd root_data/etc/ssh                                                                                                                                                                                                                                                    
chmod 600 ssh_host_ecdsa_key ssh_host_ed25519_key ssh_host_rsa_key
cd ../../..
# build docker container
docker compose down
docker compose up -d --build

