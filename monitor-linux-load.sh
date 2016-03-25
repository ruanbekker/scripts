#!/bin/bash

# Ruan Bekker <ruan@ruanbekker.com>
# Usage: 
# chmod +x script.sh
# add to crontab
# */10 * * * * /path/to/this/script.sh

load=`uptime | awk '{print $11}' | cut -d'.' -f1`
topcpu=`ps -Ao user,uid,comm,pid,pcpu,tty --sort=-pcpu | head -n 6`
topmem=`ps -eo pid,pmem,rss,comm --sort rss | tail -5 | sort -r`

if [[ $load -gt "2" ]];
 then 
 echo "Top CPU" > /tmp/report.txt; echo "======" >> /tmp/report.txt
 $topcpu >>  /tmp/report.txt;
 echo " " >>  /tmp/report.txt;
 echo "Top MEM" >> /tmp/report.txt; echo "======" >> /tmp/report.txt
 $topmem  >>  /tmp/report.txt;
 echo " " >>  /tmp/report.txt;
 echo "ALERT - HIGH LOAD - $load "| mail -s "ALERT - HIGH LOAD" ruan@bekkersolutions.com < /tmp/report.txt ;
 else exit 0;

fi

