#!/bin/bash

#  maintenance utility: database backup (.csv)
#  -------
#  Change config in comment block to suite the environment.

#######################################################################
# config
#######################################################################

# logging practices
date_now="$(date +%F)"
server_ip=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)

# for authentication to the postgresql server using psql
db_user='xkef'
db_name='postgres'
db_host='0.0.0.0' #empty for local connection

# set env var $db_tables
# db_tables=(
#     'user'
#     'role'
#     'settings'
# )


#######################################################################

# prepare for moving to other machine for analysis / refactor
BACKUP_DIR=BACKUP_CSV_"$db_name"_"$server_ip"

cd /tmp && mkdir -p "$BACKUP_DIR" && cd "$_" || exit

# MAIN
#
# we did not yet define TABLE, as it will be used as a variable in the for-loop
# this is where we execute the sql query `copy <tablename> to stdout with csv`
for TABLE in "${db_tables[@]}"; do
    psql -c "copy \"$TABLE\" to stdout with csv" -U $db_user -d $db_name -h $db_host --quiet \
        >"$TABLE"_"$db_name"_"$db_user"_"$server_ip"__"$date_now".csv &&
        echo '[x]' "$TABLE" 'done'
done

# tar everything
cd .. && tar czf __CSV__"$BACKUP_DIR".tar.gz "$BACKUP_DIR" &>/dev/null

exit 0
