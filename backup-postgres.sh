#!/bin/bash

# PostgreSQL Database Backup Script
# Creates a one-time backup of the PostgreSQL database from Docker container

set -e  # Exit on any error

# Configuration from environment
DB_HOST="192.168.0.9"
DB_PORT="5433"
DB_USER="steven"
DB_NAME="steven"
DB_PASSWORD="Secret!1234"

# Backup configuration
BACKUP_DIR="./database-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/postgres_backup_${TIMESTAMP}.sql"
CONTAINER_NAME="postgres"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🗄️  PostgreSQL Database Backup Script${NC}"
echo -e "${BLUE}======================================${NC}"

# Create backup directory if it doesn't exist
echo -e "${YELLOW}📁 Creating backup directory...${NC}"
mkdir -p "$BACKUP_DIR"

# Check if PostgreSQL container is running
echo -e "${YELLOW}🔍 Checking PostgreSQL container status...${NC}"
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}❌ Error: PostgreSQL container '$CONTAINER_NAME' is not running${NC}"
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    exit 1
fi

echo -e "${GREEN}✅ PostgreSQL container is running${NC}"

# Test database connection
echo -e "${YELLOW}🔌 Testing database connection...${NC}"
if ! docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Cannot connect to PostgreSQL database${NC}"
    echo "Please check if the database is accessible"
    exit 1
fi

echo -e "${GREEN}✅ Database connection successful${NC}"

# Create the backup
echo -e "${YELLOW}💾 Creating database backup...${NC}"
echo "Backup file: $BACKUP_FILE"

# Use pg_dump inside the container to create a complete backup
docker exec "$CONTAINER_NAME" pg_dump \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    --verbose \
    --clean \
    --if-exists \
    --create \
    --format=plain \
    --no-owner \
    --no-privileges > "$BACKUP_FILE"

# Check if backup was successful
if [ $? -eq 0 ] && [ -s "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✅ Backup completed successfully!${NC}"
    echo -e "${GREEN}📊 Backup size: $BACKUP_SIZE${NC}"
    echo -e "${GREEN}📂 Backup location: $BACKUP_FILE${NC}"
    
    # Show backup file info
    echo -e "\n${BLUE}📋 Backup Information:${NC}"
    echo "Timestamp: $(date)"
    echo "Database: $DB_NAME"
    echo "Host: $DB_HOST:$DB_PORT"
    echo "File: $BACKUP_FILE"
    echo "Size: $BACKUP_SIZE"
    
    # Show first few lines of backup to verify content
    echo -e "\n${BLUE}🔍 Backup file preview (first 10 lines):${NC}"
    head -10 "$BACKUP_FILE"
    
else
    echo -e "${RED}❌ Backup failed!${NC}"
    if [ -f "$BACKUP_FILE" ]; then
        echo "Removing incomplete backup file..."
        rm -f "$BACKUP_FILE"
    fi
    exit 1
fi

# Optional: Compress the backup
echo -e "\n${YELLOW}🗜️  Would you like to compress the backup? [y/N]${NC}"
read -r -n 1 COMPRESS
echo
if [[ $COMPRESS =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}📦 Compressing backup...${NC}"
    gzip "$BACKUP_FILE"
    COMPRESSED_FILE="${BACKUP_FILE}.gz"
    COMPRESSED_SIZE=$(du -h "$COMPRESSED_FILE" | cut -f1)
    echo -e "${GREEN}✅ Backup compressed: $COMPRESSED_FILE${NC}"
    echo -e "${GREEN}📊 Compressed size: $COMPRESSED_SIZE${NC}"
fi

echo -e "\n${GREEN}🎉 Database backup process completed!${NC}"

# Show restore instructions
echo -e "\n${BLUE}📖 To restore this backup later:${NC}"
echo "1. Copy the SQL file to the container:"
echo "   docker cp $BACKUP_FILE $CONTAINER_NAME:/tmp/"
echo "2. Restore the database:"
echo "   docker exec $CONTAINER_NAME psql -h $DB_HOST -U $DB_USER -d postgres -f /tmp/$(basename $BACKUP_FILE)"

echo -e "\n${BLUE}📂 All backups are stored in: $BACKUP_DIR${NC}"
ls -lah "$BACKUP_DIR"