#!/bin/bash

# PostgreSQL to S3
#
# This script performs the following task:
# - obtains a list of databases on the specified server
# - iterates through list to perform a database dump
# - uploads to s3
# - cleans up local database dumnps
#
# Note: The files will be uploaded to the following constructed path on S3
#   s3://bucket/database/postgres/2017/03/15/1489558714-database.sqlc

# import config
source $(dirname "${BASH_SOURCE[0]}")/configs/postgres

# export password
export PGPASSWORD=${POSTGRES_PASS}

# timestamp breakdown path
TIMESTAMP=$(date +"%Y/%m/%d/%s")

# fetch name of each database for individual backup
DATABASES=`${PSQL_BIN} -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -c "SELECT datname FROM pg_database WHERE NOT datistemplate" -tA | grep -Ev "(postgres)"`

# process each database for backup
echo "Uploading Compressed Backups..."
for DATABASE in ${DATABASES}; do
  # dump database to disk
  ${PSQL_DMP} -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} --format=c -f /tmp/${TIMESTAMP}-${DATABASE}.sqlc ${DATABASE}

  # upload database
  s3cmd put -f /tmp/${TIMESTAMP}-${DATABASE}.sqlc s3://${S3_BUCKET_NAME}/${S3_BACKUP_TYPE}/${TIMESTAMP}-${DATABASE}.sqlc

  # remove local dump
  rm /tmp/${TIMESTAMP}-${DATABASE}.sqlc
done
echo "Done!"

# remove password
unset PGPASSWORD
