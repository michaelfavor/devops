#!/bin/bash
ssh-keygen -y -f root_data/etc/ssh/ssh_host_rsa_key > root_data/etc/ssh/ssh_host_rsa_key.pub
ssh-keygen -y -f root_data/etc/ssh/ssh_host_ecdsa_key > root_data/etc/ssh/ssh_host_ecdsa_key.pub
ssh-keygen -y -f root_data/etc/ssh/ssh_host_ed25519_key > root_data/etc/ssh/ssh_host_ed25519_key.pub


