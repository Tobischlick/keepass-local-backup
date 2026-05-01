#!/bin/bash

# 1. Immediate check for .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "✔ Found .env file at $SCRIPT_DIR/.env"

    # Load configuration
    set -a
    source "$SCRIPT_DIR/.env"
    set +a

    # Print properties for verification
    echo "------------------------------------------------"
    echo "  Properties Loaded:"
    echo "  SOURCE_DB:  $SOURCE_DB"
    echo "  BACKUP_DIR: $BACKUP_DIR"
    echo "  RETENTION:  $RETENTION_DAYS days"
    echo "------------------------------------------------"
else
    echo "✘ Error: .env file not found at $SCRIPT_DIR/.env"
    exit 1
fi

# 2. Inform the user about the wait
echo "⏳ Waiting 30 seconds for OneDrive to mount before starting backup..."
sleep 30

# 3. Proceed with the backup
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")

# Ensure the backup directory exists
if mkdir -p "$BACKUP_DIR"; then
    echo "✔ Backup directory verified."
else
    echo "✘ Error: Could not create or access backup directory: $BACKUP_DIR"
    exit 1
fi

if [ -f "$SOURCE_DB" ]; then
    # Perform the copy
    FILENAME=$(basename "$SOURCE_DB")
    DESTINATION="$BACKUP_DIR/${FILENAME}_backup_$TIMESTAMP.kdbx"

    cp "$SOURCE_DB" "$DESTINATION"

    # Cleanup old backups
    find "$BACKUP_DIR" -name "*.kdbx" -type f -mtime +"$RETENTION_DAYS" -delete

    echo "✅ Success: Backup of $FILENAME completed."
    echo "   Saved to: $DESTINATION"
else
    echo "✘ Error: Source database not found at: $SOURCE_DB"
    echo "   (Ensure OneDrive is mounted and the path is correct.)"
    exit 1
fi