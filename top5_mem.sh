#!/usr/bin/env bash
ps aux |head -1; ps aux | sort -nrk 4,4 | head -n 5
