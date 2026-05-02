#!/bin/bash

# --- Library Functions ---

log_message() {
    local type="$1"
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

load_config() {
    local script_dir
    local root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    if [[ -f "$root_dir/.env" ]]; then
        set -a
        source "$root_dir/.env"
        set +a
        echo "✔ Found .env file at $root_dir/.env"
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

# Added back to the library
handle_wait() {
    if [[ "$1" == "--now" ]] || [[ "$1" == "-n" ]]; then
        echo "🚀 Skipping wait (Manual Mode)..."
    else
        local delay=${SLEEP_DELAY:-30}
        log_message "info" "KeePass Backup" "⏳ System startup: Waiting ${delay}s for mount..."
        sleep "$delay"
    fi
}

verify_file_type() {
    local file_path="$1"
    local mime_type
    mime_type=$(file -b --mime-type "$file_path")

    if [[ "$mime_type" == "application/x-keepass2" ]] || [[ "$mime_type" == "application/octet-stream" ]]; then
        echo "🔒 File type verified ($mime_type)."
        return 0
    else
        echo "⚠️  Validation Error: File is $mime_type, not a KeePass database."
        return 1
    fi
}

verify_checksum() {
    local source_file="$1"
    local backup_file="$2"
    echo "🔍 Verifying integrity (SHA-256)..."
    local source_hash=$(sha256sum "$source_file" | awk '{print $1}')
    local backup_hash=$(sha256sum "$backup_file" | awk '{print $1}')

    if [[ "$source_hash" == "$backup_hash" ]]; then
        echo "🛡️  Integrity Check: MATCHED"
        return 0
    else
        echo "🚨 Integrity Check: FAILED"
        return 1
    fi
}

cleanup_old_backups() {
    find "$BACKUP_DIR" -name "*.kdbx" -type f -mtime +"$RETENTION_DAYS" -delete
    echo "🧹 Cleaned up backups older than $RETENTION_DAYS days."
}