#!/bin/bash

# 1. Setup paths and load library
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SRC_DIR/lib_utils.sh"

# 2. Load Config
if ! load_config; then
    log_message "error" "KeePass Backup" "✘ Error: .env file not found!"
    exit 1
fi

# 3. Handle Timing (Calls the library function)
handle_wait "$1"

# 4. Verify Directory
if ! mkdir -p "$BACKUP_DIR"; then
    log_message "error" "KeePass Backup" "✘ Error: Backup directory inaccessible!"
    exit 1
fi

# 5. Execute Workflow
if [[ -f "$SOURCE_DB" ]]; then

    if ! verify_file_type "$SOURCE_DB"; then
        log_message "error" "KeePass Backup" "✘ Error: Source is not a valid KeePass file!"
        exit 1
    fi

    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
    FILENAME=$(basename "$SOURCE_DB")
    DESTINATION="$BACKUP_DIR/${FILENAME}_backup_$TIMESTAMP.kdbx"

    if cp "$SOURCE_DB" "$DESTINATION"; then
        if verify_checksum "$SOURCE_DB" "$DESTINATION"; then
            cleanup_old_backups
            log_message "success" "KeePass Backup" "✅ Backup successful: $FILENAME"
            echo "📂 Saved to: $DESTINATION"
        else
            rm "$DESTINATION"
            log_message "error" "KeePass Backup" "✘ Error: Integrity check failed!"
            exit 1
        fi
    else
        log_message "error" "KeePass Backup" "✘ Error: File copy failed!"
        exit 1
    fi
else
    log_message "error" "KeePass Backup" "✘ Error: Source database not found!"
    exit 1
fi