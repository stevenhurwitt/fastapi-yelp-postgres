#!/bin/bash

docker cp ./database-backups/postgres_backup_20251031_004441.sql postgres:/tmp/

docker exec postgres psql -U steven -d postgres -f /tmp/postgres_backup_20251031_004441.sql