#!/usr/bin/env python3

import subprocess

def is_mount_available(mount_point):
    try:
        # Execute the "mount" command and capture the output
        output = subprocess.check_output(["mount"], universal_newlines=True)

        # Split the output by lines and check if the mount point is present
        for line in output.splitlines():
            if mount_point in line:
                return True

        return False

    except subprocess.CalledProcessError:
        # Handle any errors that occur during command execution
        return False

mount_point = '/data'  # Replace with the mount point you want to check

if is_mount_available(mount_point):
    print(f"The mount point {mount_point} is available.")
else:
    print(f"The mount point {mount_point} is not available.")
