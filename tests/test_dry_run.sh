#!/bin/bash
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧪 Testing: Dry Run Mode..."

FIXTURE_SRC="$TEST_DIR/dryrun_source.kdbx"
FIXTURE_BACKUP_DIR="$TEST_DIR/dryrun_backup_dir"
OLD_BACKUP="$FIXTURE_BACKUP_DIR/dryrun_source_backup_2000-01-01_00:00:00.kdbx"

head -c 256 /dev/urandom > "$FIXTURE_SRC"
rm -rf "$FIXTURE_BACKUP_DIR"
mkdir -p "$FIXTURE_BACKUP_DIR"

# Seed an old backup, well past any reasonable retention window, so we can
# confirm dry-run cleanup previews the delete without actually doing it.
echo "old data" > "$OLD_BACKUP"
touch -d "365 days ago" "$OLD_BACKUP" 2>/dev/null || touch -t 200001010000 "$OLD_BACKUP"

# Drive the real script end-to-end in dry-run mode. SOURCE_DB/BACKUP_DIR/
# RETENTION_DAYS are injected as env vars, same as test_filename_pattern.sh.
SOURCE_DB="$FIXTURE_SRC" BACKUP_DIR="$FIXTURE_BACKUP_DIR" RETENTION_DAYS=30 \
    "$TEST_DIR/../src/backup_keepass.sh" --now --dry-run
EXIT_CODE=$?

# Test: script exits successfully
if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "✅ Passed: --dry-run exited successfully."
else
    echo "❌ Failed: --dry-run exited with code $EXIT_CODE!"
    exit 1
fi

# Test: no new backup file was created
NEW_BACKUP_COUNT=$(find "$FIXTURE_BACKUP_DIR" -maxdepth 1 -name "*.kdbx" -type f | wc -l)
if [[ "$NEW_BACKUP_COUNT" -eq 1 ]]; then
    echo "✅ Passed: No new backup file was written to BACKUP_DIR."
else
    echo "❌ Failed: Expected only the pre-seeded backup, found $NEW_BACKUP_COUNT .kdbx file(s)!"
    exit 1
fi

# Test: the pre-seeded old backup was not deleted
if [[ -f "$OLD_BACKUP" ]]; then
    echo "✅ Passed: Old backup was not deleted by dry-run cleanup."
else
    echo "❌ Failed: Old backup was deleted despite --dry-run!"
    exit 1
fi

rm -f "$FIXTURE_SRC"
rm -rf "$FIXTURE_BACKUP_DIR"
