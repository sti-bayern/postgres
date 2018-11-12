#!/bin/sh

set -e

if [ -z "$(ls -A /data)" ]; then
    su-exec app initdb -E UTF8 -U app

    cat >> /data/postgresql.conf << EOF
listen_addresses='*'
log_directory = '/var/log/app'
standard_conforming_strings = 'off'
wal_level = logical
EOF

    cat > /data/pg_hba.conf << EOF
local   all             all                                     peer
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
host    all             all             172.16.0.0/12           md5
host    all             all             10.0.0.0/8              md5
host    all             all             192.168.0.0/16          md5
EOF

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
    # configs einlesen
    for file in postgresql pg_hba;
    do
        if [ -f "/import/${file}.conf" ]; then
            cp -va /import/${file}.conf /data/${file}.conf
        fi
    done 

else
    find /data -type d -exec chmod 700 {} \;
    find /data -type f -exec chmod 600 {} \;
fi
