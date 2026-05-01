#!/bin/bash

# Check for the --now or -n flag to skip the wait
WAIT_ENABLED=true
if [[ "$1" == "--now" ]] || [[ "$1" == "-n" ]]; then
    WAIT_ENABLED=false
fi

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
    echo "  SOURCE_DB:    $SOURCE_DB"
    echo "  BACKUP_DIR:   $BACKUP_DIR"
    echo "  RETENTION:    $RETENTION_DAYS days"
    echo "  STARTUP WAIT: ${SLEEP_DELAY:-30} seconds"
    echo "------------------------------------------------"
else
    echo "✘ Error: .env file not found at $SCRIPT_DIR/.env"
    notify-send "KeePass Backup" "✘ Error: .env file not found!" -u critical
    exit 1
fi

# 2. Conditional Wait using SLEEP_DELAY (defaults to 30 if not defined in .env)
if [ "$WAIT_ENABLED" = true ]; then
    DELAY=${SLEEP_DELAY:-30}
    echo "⏳ Waiting $DELAY seconds for OneDrive to mount (System Startup Mode)..."
    notify-send "KeePass Backup" "⏳ System startup: Waiting $DELAY\s for mount..." -t 3000
    sleep "$DELAY"
else
    echo "🚀 Skipping wait (Manual Mode)..."
fi

# 3. Proceed with the backup
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")

# Ensure the backup directory exists
if mkdir -p "$BACKUP_DIR"; then
    echo "✔ Backup directory verified."
else
    echo "✘ Error: Could not create or access backup directory: $BACKUP_DIR"
    notify-send "KeePass Backup" "✘ Error: Backup directory inaccessible!" -u critical
    exit 1
fi

if [ -f "$SOURCE_DB" ]; then
    # Perform the copy
    FILENAME=$(basename "$SOURCE_DB")
    DESTINATION="$BACKUP_DIR/${FILENAME}_backup_$TIMESTAMP.kdbx"

    if cp "$SOURCE_DB" "$DESTINATION"; then
        # Cleanup old backups
        find "$BACKUP_DIR" -name "*.kdbx" -type f -mtime +"$RETENTION_DAYS" -delete

        echo "✅ Success: Backup of $FILENAME completed."
        echo "   Saved to: $DESTINATION"
        notify-send "KeePass Backup" "✅ Backup successful: $FILENAME" -i security-high -t 5000
    else
        echo "✘ Error: Copy failed."
        notify-send "KeePass Backup" "✘ Error: File copy failed!" -u critical
        exit 1
    fi
else
    echo "✘ Error: Source database not found at: $SOURCE_DB"
    echo "   (Ensure OneDrive is mounted and the path is correct.)"
    notify-send "KeePass Backup" "✘ Error: Source database not found!" -u critical
    exit 1
fi