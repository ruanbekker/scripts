#!/usr/bin/env bash
set -e

timestamp="$(date +%F)"

# make a local backup
tar --exclude="/opt/docker/serverx/content/logs" -zcvf /opt/backups/serverx/serverx-backup-$timestamp.tar.gz \
	/opt/docker/* \
	/home/me/serverx/file.conf \
	/home/me/serverx/config.yml 

# backup to s3
aws --profile storage s3 sync /opt/backups/ s3://my-s3-bucket/serverx/

# delete local backups older than 14 days
find /opt/backups/serverx/ -type f -name "*.tar.gz" -mtime +14 -exec rm {} \;
