#!/usr/bin/env bash

# ensure ~/.my.cnf has
# [user]
# username=x
# password=x

MY_HOSTNAME="my-server"
MY_AWS_ENVIRONMENT="dev"
MY_S3_BUCKET="my-s3-bucket"
MY_DATESTAMP=$(date +%F)
MY_TIMESTAMP=$(date +%s)
MY_BACKUP_PATH=/tmp/stage/${MY_TIMESTAMP}
mkdir -p ${MY_BACKUP_PATH}

echo "getting a list of databases"
mysql -N -e 'show databases' | while read DBNAME
do
  echo "backing up ${DBNAME} to ${MY_BACKUP_PATH}/${DBNAME}-${MY_TIMESTAMP}.sql.gz"
  sleep 5
  mysqldump \
	  --complete-insert \
	  --routines \
	  --triggers \
	  --single-transaction ${DBNAME} | gzip > ${MY_BACKUP_PATH}/${MY_TIMESTAMP}-${DBNAME}.sql.gz
done

echo "uploading backups to s3"
pushd ${MY_BACKUP_PATH}
aws s3 cp --recursive . s3://${MY_S3_BUCKET}/${MY_HOSTNAME}/${MY_DATESTAMP}/mysql/
popd

echo "remove staging directory"
rm -rf /tmp/stage/${MY_TIMESTAMP}
