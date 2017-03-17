#!/bin/bash

# MySQL to S3
#
# This script performs the following task:
# - obtains a list of databases on the specified server
# - iterates through list to perform a database dump
# - uploads to s3
# - cleans up local database dumnps
#
# Note: The files will be uploaded to the following constructed path on S3
#   s3://bucket/database/mysql/2017/03/15/1489558714-database.sql.gz

# import config
source $(dirname "${BASH_SOURCE[0]}")/configs/mysql

# timestamp breakdown path
DATESTAMP=$(date +"%s")
TIMESTAMP=$(date +"%Y/%m/%d")/${DATESTAMP}

# fetch name of each database for individual backup
DATABASES=`${MYSQL_BIN} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASS} -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|mysql|performance_schema)"`

# process each database for backup
echo "Uploading Compressed Backups..."
for DATABASE in ${DATABASES}; do
  # dump database to disk
  ${MYSQL_DMP} --default-character-set=utf8mb4 --quick -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASS} --databases ${DATABASE} | gzip -9 > /tmp/${DATESTAMP}-${DATABASE}.sql.gz

  # upload database
  s3cmd put -f /tmp/${DATESTAMP}-${DATABASE}.sql.gz s3://${S3_BUCKET_NAME}/${S3_BACKUP_TYPE}/${TIMESTAMP}-${DATABASE}.sql.gz

  # remove local dump
  rm /tmp/${DATESTAMP}-${DATABASE}.sql.gz
done
echo "Done!"
