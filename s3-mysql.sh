#!/bin/sh

# MySQL to S3
#
# This script performs the following task:
# - obtains a list of databases on the specified server
# - iterates through list to perform a database dump
# - pipes the dump into gzip for compression
# - pipes the compressed file to s3
#
# Note: The files will be uploaded to the following constructed path on S3
#   s3://bucket/database/mysql/2017/03/15/1489558714-database.sql.gz

# configurable variables
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=****
MYSQL_PASS=****
S3_BUCKET_NAME=****
S3_BACKUP_TYPE=database/mysql

# binary file paths
MYSQL_BIN=/usr/bin/mysql
MYSQL_DMP=/usr/bin/mysqldump

# timestamp breakdown path
TIMESTAMP=$(date +"%Y/%m/%d/%s")

# fetch name of each database for individual backup
DATABASES=`${MYSQL_BIN} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASS} -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|mysql|performance_schema)"`

# process each database for backup
echo "Uploading Compressed Backups..."
for DATABASE in ${DATABASES}; do
  ${MYSQL_DMP} --default-character-set=utf8mb4 --quick -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASS} --databases ${DATABASE} | gzip -9 | s3cmd put - s3://${S3_BUCKET_NAME}/${S3_BACKUP_TYPE}/${TIMESTAMP}-${DATABASE}.sql.gz
done
echo "Done!"
