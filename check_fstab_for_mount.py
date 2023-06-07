#!/usr/bin/env python3

def is_fstab_entry_present(mount_point, device):
    with open('/etc/fstab', 'r') as f:
        lines = f.readlines()

    # Check if the entry exists in the lines
    for line in lines:
        # Skip commented lines and empty lines
        if line.startswith('#') or line.strip() == '':
            continue

        # Split the line by whitespace and extract the mount point and device
        parts = line.split()
        if len(parts) >= 2:
            if parts[1] == mount_point and parts[0] == device:
                return True

    return False

mount_point = '/data'
device = '/dev/xvdf'

if is_fstab_entry_present(mount_point, device):
    print("The entry is present in /etc/fstab.")
else:
    print("The entry is not present in /etc/fstab.")
