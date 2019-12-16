#!/bin/sh

# Before PostgreSQL can function correctly, the database cluster must be initialized:
# mkdir -p /var/lib/postgres/data
initdb -D "/var/lib/postgresql/data" -E "UTF8" --locale="C" -U postgres
# internal start of server in order to allow set-up using psql-client
# does not listen on external TCP/IP and waits until start finishes
pg_ctl -D "/var/lib/postgresql/data" -o "-c listen_addresses=''" -w start

# data migrations
psql -f initdb.sql
psql -d main -f test_db.sql

# stop internal postgres server
pg_ctl -D "/var/lib/postgresql/data" -m fast -w stop

exec "$@"
