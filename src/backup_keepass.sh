#!/bin/bash

# 1. Setup paths and load library
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SRC_DIR/lib_utils.sh"

# 2. Parse arguments (Supports flags: -n/--now and -f/--force)
FORCE_BACKUP=false
NOW_FLAG=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--now)   NOW_FLAG="--now" ;;
        -f|--force) FORCE_BACKUP=true ;;
        *) echo "❌ Error: Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# 3. Load Config (Only if variables are not already injected by integration tests)
if [[ -z "$SOURCE_DB" || -z "$BACKUP_DIR" ]]; then
    if ! load_config; then
        log_message "error" "KeePass Backup" "❌ Error: .env file not found!"
        exit 1
    fi
fi

# 4. Handle Timing
handle_wait "$NOW_FLAG"

# 5. Verify Directory
if ! mkdir -p "$BACKUP_DIR"; then
    log_message "error" "KeePass Backup" "✘ Error: Backup directory inaccessible!"
    exit 1
fi

# 6. Execute Workflow
if [[ -f "$SOURCE_DB" ]]; then

    if ! verify_file_type "$SOURCE_DB"; then
        log_message "error" "KeePass Backup" "✘ Error: Source is not a valid KeePass file!"
        exit 1
    fi

    # Check for duplicate file for today unless --force is used
    if [[ "$FORCE_BACKUP" == false ]]; then
        if check_daily_duplicate "$SOURCE_DB" "$BACKUP_DIR"; then
            log_message "success" "KeePass Backup" "✅ Skip: A matching backup already exists for today."
            echo "💡 Tip: Use -f or --force if you want to overwrite or create a secondary copy."
            exit 0
        fi
    fi

    # Fix the timestamp formatting to include seconds properly (Fixes v2.2.0 tracking)
    TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
    FILENAME=$(basename "$SOURCE_DB")

    BASE_NAME="${FILENAME%.*}"
    DESTINATION="$BACKUP_DIR/${BASE_NAME}_backup_$TIMESTAMP.kdbx"

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