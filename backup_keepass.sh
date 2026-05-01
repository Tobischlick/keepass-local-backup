#!/bin/bash

# Give the system 30 seconds to mount OneDrive on boot
sleep 30

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    export "$(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)"
else
    echo "Error: .env file not found!"
    exit 1
fi

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
mkdir -p "$BACKUP_DIR"

if [ -f "$SOURCE_DB" ]; then
    cp "$SOURCE_DB" "$BACKUP_DIR/$(basename "$SOURCE_DB")_$TIMESTAMP.kdbx"
    # Cleanup old backups
    find "$BACKUP_DIR" -name "*.kdbx" -type f -mtime +"$RETENTION_DAYS" -delete
    echo "Backup completed successfully."
else
    echo "Source file not found. Check your .env paths."
fi