#!/usr/bin/env bash
while [ "$(mysql -h mysql-db -P 3306 -u root -prootpassword -e 'SELECT VERSION()' &> /dev/null; echo $?)" != 0 ]; do sleep 1; echo waiting; done; echo connected 
