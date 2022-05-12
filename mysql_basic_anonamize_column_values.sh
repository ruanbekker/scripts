#!/usr/bin/env bash
set -e

# variables
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASS=rootpassword

MAIN_DB=prod_db
MASKED_DB=staging_db
TABLE_NAME=customers

# functions
function generate_4_char_number() {
    echo $(seq 1000 9999 | sort -R | head -n 1)
}

function generate_fake_creditcard_num() {
    one="0000"
    two=$(generate_4_char_number)
    three=$(generate_4_char_number)
    four=$(generate_4_char_number)
    echo "${one}-${two}-${three}-${four}"
}

# dump the production database
# create the staging database
# import the production database dump into the staging database
# run a for loop and update every records creditcard_number value from our randomizer function
# make a database dump of the staging database to reuse

echo -e "\n:: dumping maindb ${MAIN_DB} to ${MAIN_DB}.sql\n"
sleep 2
mysqldump -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} ${MAIN_DB} > ${MAIN_DB}.sql

echo -e ":: creating stagingdb ${MASKED_DB} if not already exists\n"
sleep 2
mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} -e "CREATE DATABASE IF NOT EXISTS ${MASKED_DB};"

echo -e ":: importing dumped ${MAIN_DB}.sql into ${MASKED_DB}\n"
sleep 2
mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} ${MASKED_DB} < ${MAIN_DB}.sql

echo -e ":: looping through the table ${TABLE_NAME} on ${MASKED_DB} and updating the column values of creditcard_number to dummy data\n"
sleep 3
mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} -e "SELECT customer_id, creditcard_number FROM ${MASKED_DB}.${TABLE_NAME};" | while read customer_id creditcard_number
do
  fake_creditcard_num=$(generate_fake_creditcard_num)
  mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} ${MASKED_DB} -e "UPDATE ${MASKED_DB}.${TABLE_NAME} SET creditcard_number=\"$fake_creditcard_num\" WHERE customer_id=$customer_id ;"
done

echo -e ":: reading table data from ${MASKED_DB}.${TABLE_NAME}\n"
mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} -e "SELECT * from ${MASKED_DB}.${TABLE_NAME}"
sleep 1

echo -e "\n:: dumping maindb ${MASKED_DB} to ${MASKED_DB}.sql\n"
sleep 2
mysqldump -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} ${MASKED_DB} > ${MASKED_DB}.sql
