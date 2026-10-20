#!/bin/sh
# Runs inside the backup container (see docker-compose.yml).
set -eu
stamp=$(date -u +%Y%m%d-%H%M%S)
pg_dump --format=custom --file="/backups/db-$stamp.dump"
tar -czf "/backups/files-$stamp.tar.gz" -C /files .
find /backups -name 'db-*.dump' -mtime +"${KEEP_DAYS:-14}" -delete
find /backups -name 'files-*.tar.gz' -mtime +"${KEEP_DAYS:-14}" -delete
echo "backup $stamp done"
