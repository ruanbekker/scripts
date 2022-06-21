#!/usr/bin/env bash
ps aux |head -1; ps aux | sort -nrk 3,3 | head -n 5
