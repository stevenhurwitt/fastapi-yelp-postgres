#!/bin/bash

# Use the most recent backup file
BACKUP_FILE="postgres_backup_20260112_021420.sql.gz"

# Decompress the backup file
gunzip -c ./database-backups/$BACKUP_FILE > /tmp/restore_backup.sql

# Copy to container
docker cp /tmp/restore_backup.sql postgres:/tmp/

# Restore the database
docker exec postgres psql -U steven -d postgres -f /tmp/restore_backup.sql

# Cleanup
rm /tmp/restore_backup.sql