#!/usr/bin/env python3

import os
import pwd
import grp

def is_directory_ownership(directory_path, user, group):
    stat_info = os.stat(directory_path)
    uid = stat_info.st_uid  # User ID of the directory owner
    gid = stat_info.st_gid  # Group ID of the directory owner

    # Retrieve the username and group name associated with the user and group IDs
    directory_user = pwd.getpwuid(uid).pw_name
    directory_group = grp.getgrgid(gid).gr_name

    return directory_user == user and directory_group == group

directory_path = '/data'  
user = 'ec2-user' 
group = 'ec2-user' 

if is_directory_ownership(directory_path, user, group):
    print("The directory has the expected ownership.")
else:
    print("The directory does not have the expected ownership.")
