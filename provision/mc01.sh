#!/bin/bash
set -e

dnf install memcached -y
systemctl enable --now memcached

sed -i 's/127.0.0.1/0.0.0.0/' /etc/sysconfig/memcached
systemctl restart memcached
