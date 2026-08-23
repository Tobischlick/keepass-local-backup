#!/bin/bash
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TEST_DIR/../src/lib_utils.sh"

echo "🧪 Testing: Config & Timing Logic..."

# Test: handle_wait with --now flag
start=$(date +%s)
handle_wait "--now"
end=$(date +%s)
runtime=$((end-start))

if [ $runtime -lt 2 ]; then
    echo "✅ Passed: --now flag skipped the wait successfully."
else
    echo "❌ Failed: --now flag did not skip the wait!"
    exit 1
fi

# Test: validate_config accepts a well-formed config
SOURCE_DB="/tmp/does-not-matter.kdbx"
BACKUP_DIR="/tmp/does-not-matter-backups"
RETENTION_DAYS=7
SLEEP_DELAY=30

if validate_config; then
    echo "✅ Passed: validate_config accepted a well-formed config."
else
    echo "❌ Failed: validate_config rejected a well-formed config!"
    exit 1
fi

# Test: validate_config rejects an empty SOURCE_DB
SOURCE_DB=""
if ! validate_config; then
    echo "✅ Passed: validate_config rejected an empty SOURCE_DB."
else
    echo "❌ Failed: validate_config accepted an empty SOURCE_DB!"
    exit 1
fi
SOURCE_DB="/tmp/does-not-matter.kdbx"

# Test: validate_config rejects a non-numeric RETENTION_DAYS
RETENTION_DAYS="seven"
if ! validate_config; then
    echo "✅ Passed: validate_config rejected a non-numeric RETENTION_DAYS."
else
    echo "❌ Failed: validate_config accepted a non-numeric RETENTION_DAYS!"
    exit 1
fi
RETENTION_DAYS=7

# Test: validate_config rejects a non-numeric SLEEP_DELAY
SLEEP_DELAY="thirty"
if ! validate_config; then
    echo "✅ Passed: validate_config rejected a non-numeric SLEEP_DELAY."
else
    echo "❌ Failed: validate_config accepted a non-numeric SLEEP_DELAY!"
    exit 1
fi

# Test: validate_config allows an unset SLEEP_DELAY (optional, defaults elsewhere)
unset SLEEP_DELAY
if validate_config; then
    echo "✅ Passed: validate_config allows an unset (optional) SLEEP_DELAY."
else
    echo "❌ Failed: validate_config rejected an unset SLEEP_DELAY!"
    exit 1
fi

# Test: log_message appends a timestamped entry to LOG_FILE when set
notify-send() { :; }  # stub: no desktop session in CI

LOG_FILE=$(mktemp)
log_message "info" "Test" "Hello from test"

if grep -q "Hello from test" "$LOG_FILE"; then
    echo "✅ Passed: log_message appended the message to LOG_FILE."
else
    echo "❌ Failed: log_message did not write to LOG_FILE!"
    exit 1
fi
rm -f "$LOG_FILE"

# Test: log_message succeeds with no file side effect when LOG_FILE is unset
unset LOG_FILE
if log_message "info" "Test" "No file logging" > /dev/null; then
    echo "✅ Passed: log_message succeeded with LOG_FILE unset."
else
    echo "❌ Failed: log_message failed when LOG_FILE was unset!"
    exit 1
fi