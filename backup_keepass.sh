#!/bin/bash

# --- Functions ---

# Function to handle desktop notifications and terminal output
log_message() {
    local type="$1"    # "success", "error", or "info"
    local title="$2"
    local message="$3"
    local urgency="normal"
    local icon="info"

    echo "$message"

    if [[ "$type" == "error" ]]; then
        urgency="critical"
        icon="dialog-error"
    elif [[ "$type" == "success" ]]; then
        icon="security-high"
    fi

    notify-send "$title" "$message" -u "$urgency" -i "$icon" -t 5000
}

# Function to load and verify the .env file
load_config() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [[ -f "$script_dir/.env" ]]; then
        set -a
        source "$script_dir/.env"
        set +a

        # Terminal-only logging for properties
        echo "✔ Found .env file at $script_dir/.env"
        echo "------------------------------------------------"
        echo "  Properties Loaded:"
        echo "  SOURCE_DB:    $SOURCE_DB"
        echo "  BACKUP_DIR:   $BACKUP_DIR"
        echo "  RETENTION:    $RETENTION_DAYS days"
        echo "  STARTUP WAIT: ${SLEEP_DELAY:-30} seconds"
        echo "------------------------------------------------"
        return 0
    else
        return 1
    fi
}

# Function to handle the startup delay
handle_wait() {
    if [[ "$1" == "--now" ]] || [[ "$1" == "-n" ]]; then
        echo "🚀 Skipping wait (Manual Mode)..."
    else
        local delay=${SLEEP_DELAY:-30}
        log_message "info" "KeePass Backup" "⏳ System startup: Waiting ${delay}s for mount..."
        sleep "$delay"
    fi
}

# Function to perform the cleanup of old files
cleanup_old_backups() {
    find "$BACKUP_DIR" -name "*.kdbx" -type f -mtime +"$RETENTION_DAYS" -delete
    echo "🧹 Cleaned up backups older than $RETENTION_DAYS days."
}

# --- Main Execution Logic ---

# 1. Load Config
if ! load_config; then
    log_message "error" "KeePass Backup" "✘ Error: .env file not found!"
    exit 1
fi

# 2. Handle Timing
handle_wait "$1"

# 3. Verify Directory
if ! mkdir -p "$BACKUP_DIR"; then
    log_message "error" "KeePass Backup" "✘ Error: Backup directory inaccessible!"
    exit 1
fi

# 4. Execute Backup
if [[ -f "$SOURCE_DB" ]]; then
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
    FILENAME=$(basename "$SOURCE_DB")
    DESTINATION="$BACKUP_DIR/${FILENAME}_backup_$TIMESTAMP.kdbx"

    if cp "$SOURCE_DB" "$DESTINATION"; then
        cleanup_old_backups
        log_message "success" "KeePass Backup" "✅ Backup successful: $FILENAME"
        echo "📂 Saved to: $DESTINATION"
    else
        log_message "error" "KeePass Backup" "✘ Error: File copy failed!"
        exit 1
    fi
else
    log_message "error" "KeePass Backup" "✘ Error: Source database not found!"
    exit 1
fi