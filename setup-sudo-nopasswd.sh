#!/bin/bash
export USERNAME=""
echo "$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/dont-prompt-$USERNAME-for-password
