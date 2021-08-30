#!/usr/bin/env bash
TCP_EXIT_CODE=1
while [ "$TCP_EXIT_CODE" != 0 ] ; do nc -vz -w 1 localhost 1001 &> /dev/null && TCP_EXIT_CODE=${?} || TCP_EXIT_CODE=${?} ; echo "failing"; sleep 1; done; echo "ok"
