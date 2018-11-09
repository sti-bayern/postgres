#!/bin/sh

set -e

# ggf. DB starten
if [ "$(ls -lA /data | wc -l)" -le 3 ]; then
    mkdir /tmp/pg_data
    ls -la /data/
    mv /data/* /tmp/pg_data/
    ls -la /data/
    su-exec app initdb -E UTF8 -U app
    mv /tmp/pg_data/*  /data/
fi

# Standard-postgresql.conf
if [ ! -f /data/postgresql.conf ]; then
cat >> /data/postgresql.conf << EOF
listen_addresses='*'
log_directory = '/var/log/app'
standard_conforming_strings = 'off'
wal_level = logical
EOF
fi

# Standard-pg_hba.conf
if [ ! -f /data/pg_hba.conf ]; then
cat > /data/pg_hba.conf << EOF
local   all             all                                     peer
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
host    all             all             172.16.0.0/12           md5
host    all             all             10.0.0.0/8              md5
EOF
fi

# ggf. DB anlegen und Daten einlesen
if [ "$(ls -lA /data | wc -l)" -le 3 ]; then

    # Datenbank anlegen
    cat << EOF | su-exec app postgres --single postgres
CREATE DATABASE app ENCODING 'UTF8';
ALTER USER app WITH PASSWORD '$PGPASS';
EOF

    # Dumps  einlesen
    if [ $(find /import \( -iname "*.sql" -o -iname "*.dump" \) | wc -l | wc -l) -gt 0 ]; then
        su-exec app pg_ctl -o "-c listen_addresses='localhost'" -w start
        find /import \( -iname "*.sql" -o -iname "*.dump" \) -exec su-exec app psql -f {} app \;
        su-exec app pg_ctl -m fast -w stop
    fi

else
    find /data -type d -exec chmod 700 {} \;
    find /data -type f -exec chmod 600 {} \;
fi
