#!/usr/bin/env bash

echo ":: DISTRO ::"
cat /etc/os-release | grep PRETTY | cut -d '=' -f2

echo ":: UPTIME ::"
uptime

