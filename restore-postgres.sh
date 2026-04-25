#!/bin/bash

set -e

# Configuration
BACKUP_DIR="./database-backups"
CONTAINER_NAME="postgres"
DB_USER="steven"
DB_NAME="steven"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🗄️  PostgreSQL Database Restore Script${NC}"
echo -e "${BLUE}=======================================\n${NC}"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}❌ Error: Container '$CONTAINER_NAME' is not running${NC}"
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}"
    exit 1
fi

# Select backup file: use argument if provided, otherwise pick the most recent
if [ -n "$1" ]; then
    BACKUP_FILE="$1"
    # If just a filename (no path), prepend backup dir
    if [[ "$BACKUP_FILE" != */* ]]; then
        BACKUP_FILE="${BACKUP_DIR}/${BACKUP_FILE}"
    fi
else
    BACKUP_FILE=$(ls -t "${BACKUP_DIR}"/postgres_backup_*.sql* 2>/dev/null | head -1)
    if [ -z "$BACKUP_FILE" ]; then
        echo -e "${RED}❌ No backup files found in ${BACKUP_DIR}${NC}"
        exit 1
    fi
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Backup file not found: $BACKUP_FILE${NC}"
    echo -e "\n${YELLOW}Available backups:${NC}"
    ls -lah "${BACKUP_DIR}"/postgres_backup_*.sql* 2>/dev/null || echo "  (none)"
    exit 1
fi

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo -e "${BLUE}📂 Backup file:${NC} $BACKUP_FILE (${BACKUP_SIZE})"

# Confirm before proceeding
echo -e "\n${YELLOW}⚠️  This will overwrite the current '$DB_NAME' database.${NC}"
read -r -p "Continue? [y/N] " CONFIRM
echo
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

# Test DB connection
echo -e "${YELLOW}🔌 Testing database connection...${NC}"
if ! docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${RED}❌ Cannot connect to PostgreSQL inside container${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Connection OK${NC}\n"

# Restore — pipe directly into psql to avoid writing to /tmp
echo -e "${YELLOW}♻️  Restoring database...${NC}"

if [[ "$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" | docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME"
else
    docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" < "$BACKUP_FILE"
fi

echo -e "\n${GREEN}✅ Restore completed successfully!${NC}"
echo -e "${BLUE}📋 Database '${DB_NAME}' restored from: $(basename "$BACKUP_FILE")${NC}"

# Quick sanity check
echo -e "\n${YELLOW}🔍 Verifying restore (table count)...${NC}"
TABLE_COUNT=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -t -c \
    "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')
echo -e "${GREEN}✅ Public tables found: ${TABLE_COUNT}${NC}"