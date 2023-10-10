#!/bin/bash

yum clean all
rm -rf /var/cache/yum/*

rm -f /etc/resolv.conf

# Disable cloud-init
touch /etc/cloud/cloud-init.disabled

# Disable password auth on sshd
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
