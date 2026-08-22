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