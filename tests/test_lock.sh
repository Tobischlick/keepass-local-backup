#!/bin/bash
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧪 Testing: Concurrency Lock..."

FIXTURE_SRC="$TEST_DIR/lock_source.kdbx"
FIXTURE_BACKUP_DIR="$TEST_DIR/lock_backup_dir"
LOCK_FILE="$FIXTURE_BACKUP_DIR/.backup.lock"

head -c 256 /dev/urandom > "$FIXTURE_SRC"
rm -rf "$FIXTURE_BACKUP_DIR"
mkdir -p "$FIXTURE_BACKUP_DIR"

# Hold the lock ourselves, simulating a backup already in progress.
exec 200>"$LOCK_FILE"
flock -n 200

OUTPUT=$(SOURCE_DB="$FIXTURE_SRC" BACKUP_DIR="$FIXTURE_BACKUP_DIR" RETENTION_DAYS=30 \
    "$TEST_DIR/../src/backup_keepass.sh" --now 2>&1)
EXIT_CODE=$?

# Test: script exits successfully (skip, not a failure)
if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "✅ Passed: Locked run exited successfully (skip)."
else
    echo "❌ Failed: Locked run exited with code $EXIT_CODE!"
    exit 1
fi

# Test: skip message was logged
if [[ "$OUTPUT" == *"already running"* ]]; then
    echo "✅ Passed: Skip message mentioned the lock was held."
else
    echo "❌ Failed: Expected a skip message, got: $OUTPUT"
    exit 1
fi

# Test: no backup file was written while the lock was held
BACKUP_COUNT=$(find "$FIXTURE_BACKUP_DIR" -maxdepth 1 -name "*.kdbx" -type f | wc -l)
if [[ "$BACKUP_COUNT" -eq 0 ]]; then
    echo "✅ Passed: No backup was written while the lock was held."
else
    echo "❌ Failed: Expected no backup files, found $BACKUP_COUNT!"
    exit 1
fi

# Release the lock and confirm a subsequent run proceeds normally.
flock -u 200
exec 200>&-

SOURCE_DB="$FIXTURE_SRC" BACKUP_DIR="$FIXTURE_BACKUP_DIR" RETENTION_DAYS=30 \
    "$TEST_DIR/../src/backup_keepass.sh" --now > /dev/null
EXIT_CODE=$?

BACKUP_COUNT=$(find "$FIXTURE_BACKUP_DIR" -maxdepth 1 -name "*.kdbx" -type f | wc -l)
if [[ "$EXIT_CODE" -eq 0 && "$BACKUP_COUNT" -eq 1 ]]; then
    echo "✅ Passed: Backup proceeded normally once the lock was released."
else
    echo "❌ Failed: Expected a successful backup after releasing the lock (exit $EXIT_CODE, $BACKUP_COUNT file(s))!"
    exit 1
fi

rm -f "$FIXTURE_SRC"
rm -rf "$FIXTURE_BACKUP_DIR"
