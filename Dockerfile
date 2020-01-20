FROM adbv/base

LABEL maintainer="Günther Morhart"

#
# Environment variables dd
#


ENV PGDATA=/data \
    PGPASS=app

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/main' > /etc/apk/repositories
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/community' >> /etc/apk/repositories
#
# Setup
#
RUN apk add --no-cache \
        postgresql \
        postgresql-contrib && \
    rm -rf \
        /var/lib/postgresql \
        /var/log/postgresql && \
    mkdir /run/postgresql && \
    chown -R app:app /run/postgresql

#
# Ports
#
EXPOSE 5432

#
# Command
#
COPY app-init.sh /usr/local/bin/app-init

CMD ["su-exec", "app", "postgres"]
