#!/bin/bash

# Script to run lazysql connected to the Yelp database
# Reads database credentials from environment variables or uses defaults

set -a
source .env 2>/dev/null || true
set +a

# Use environment variables or defaults from config
DATABASE_HOST="${DATABASE_HOST:-localhost}"
DATABASE_PORT="${DATABASE_PORT:-5433}"
DATABASE_USER="${DATABASE_USER:-postgres}"
DATABASE_PASSWORD="${DATABASE_PASSWORD:-}"
DATABASE_NAME="${DATABASE_NAME:-postgres}"

# Construct the database URL
if [ -z "$DATABASE_PASSWORD" ]; then
    DATABASE_URL="postgresql://${DATABASE_USER}@${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE_NAME}?sslmode=disable"
else
    DATABASE_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE_NAME}?sslmode=disable"
fi

# Run lazysql with the database URL
lazysql "$DATABASE_URL"
