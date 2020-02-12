# database migration

# SCHEMA="STI-PROD-1"
# DB="mydb"

# psql -Atc "select tablename from pg_tables where schemaname='$SCHEMA'" $DB |\
# while read TBL; do
#     psql -c "COPY $SCHEMA.$TBL TO STDOUT WITH CSV" $DB > $TBL.csv
# done

COPY colleague(first_name,last_name,email)
TO 'C:\tmp\persons_partial_db.csv' DELIMITER ',' CSV HEADER;

COPY (SELECT * FROM persons) to 'C:\tmp\persons_client.csv' with csv
