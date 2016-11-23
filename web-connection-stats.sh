#!/bin/bash
curl -o /dev/null -s -w 'time_connect:\t\t%{time_connect}\ntime_starttransfer:\t%{time_starttransfer}\ntime_total:\t\t%{time_total}\n' $1
