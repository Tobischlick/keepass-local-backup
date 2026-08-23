#!/bin/bash
# shellcheck disable=SC2153

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

    if [[ -n "$LOG_FILE" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") [$type] $message" >> "$LOG_FILE"
    fi
}

validate_config() {
    if [[ -z "$SOURCE_DB" ]]; then
        log_message "error" "KeePass Backup" "❌ Error: SOURCE_DB is not set in .env!"
        return 1
    fi

    if [[ -z "$BACKUP_DIR" ]]; then
        log_message "error" "KeePass Backup" "❌ Error: BACKUP_DIR is not set in .env!"
        return 1
    fi

    if [[ ! "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
        log_message "error" "KeePass Backup" "❌ Error: RETENTION_DAYS must be a whole number (got '$RETENTION_DAYS')!"
        return 1
    fi

    if [[ -n "$SLEEP_DELAY" && ! "$SLEEP_DELAY" =~ ^[0-9]+$ ]]; then
        log_message "error" "KeePass Backup" "❌ Error: SLEEP_DELAY must be a whole number (got '$SLEEP_DELAY')!"
        return 1
    fi

    return 0
}

load_config() {
    local root_dir
    root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    if [[ ! -f "$root_dir/.env" ]]; then
        log_message "error" "KeePass Backup" "❌ Error: .env file not found at $root_dir/.env!"
        return 1
    fi

    set -a
    # shellcheck source=/dev/null
    source "$root_dir/.env"
    set +a
    echo "✔ Found .env file at $root_dir/.env"
    echo "------------------------------------------------"
    echo "  Properties Loaded:"
    echo "  SOURCE_DB:    $SOURCE_DB"
    echo "  BACKUP_DIR:   $BACKUP_DIR"
    echo "  RETENTION:    $RETENTION_DAYS days"
    echo "  STARTUP WAIT: ${SLEEP_DELAY:-30} seconds"
    echo "  LOG FILE:     ${LOG_FILE:-Disabled}"
    echo "------------------------------------------------"

    validate_config
}

handle_wait() {
    if [[ "$1" == "--now" ]] || [[ "$1" == "-n" ]]; then
        echo "🚀 Skipping wait (Manual Mode)..."
    else
        local delay=${SLEEP_DELAY:-30}

        log_message "info" "KeePass Backup" "⏳ Initialization: Waiting ${delay}s..."

        echo "⏳ Waiting for system to settle..."

        while [ "$delay" -gt 0 ]; do
            printf "\r   [ %02ds remaining ]           " "$delay"
            sleep 1
            ((delay--))
        done

        printf "\r✅ Environment Ready!          \n"
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

    local source_hash
    local backup_hash

    source_hash=$(sha256sum "$source_file" | awk '{print $1}')
    backup_hash=$(sha256sum "$backup_file" | awk '{print $1}')

    if [[ "$source_hash" == "$backup_hash" ]]; then
        echo "🛡️  Integrity Check: MATCHED"
        return 0
    else
        echo "🚨 Integrity Check: FAILED"
        return 1
    fi
}

build_backup_basename() {
    local source_file="$1"
    local filename
    filename=$(basename "$source_file")
    echo "${filename%.*}"
}

cleanup_old_backups() {
    find "$BACKUP_DIR" -name "*.kdbx" -type f -mtime +"$RETENTION_DAYS" -delete
    echo "🧹 Cleaned up backups older than $RETENTION_DAYS days."
}

check_daily_duplicate() {
    local source_file="$1"
    local backup_dir="$2"

    local today
    today=$(date +"%Y-%m-%d")

    local file_base
    file_base=$(build_backup_basename "$source_file")

    local existing_backups
    existing_backups=$(find "$backup_dir" -name "${file_base}_backup_${today}_*.kdbx" -type f 2>/dev/null)

    if [[ -n "$existing_backups" ]]; then
        echo "🔍 Found existing backup(s) for today. Checking if file changed..."

        local source_hash
        source_hash=$(sha256sum "$source_file" | awk '{print $1}')

        local existing_backup
        local backup_hash
        while IFS= read -r existing_backup; do
            backup_hash=$(sha256sum "$existing_backup" | awk '{print $1}')
            if [[ "$source_hash" == "$backup_hash" ]]; then
                return 0 # Exact duplicate found among today's backups! (True)
            fi
        done <<< "$existing_backups"

        echo "🔄 Changes detected in the database since last daily backup. Creating a new snapshot..."
    fi

    return 1 # Safe to make a new backup
}