#!/bin/bash
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TEST_DIR/../src/lib_utils.sh"

echo "🧪 Testing: Daily Duplicate Detection Across Multiple Backups..."

SOURCE_FILE="$TEST_DIR/dupe_source.kdbx"
BACKUP_DIR="$TEST_DIR/dupe_backup_dir"
TODAY=$(date +"%Y-%m-%d")

rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

echo "current content" > "$SOURCE_FILE"

# Several earlier backups today with DIFFERENT content, plus one that
# matches the current source exactly. A correct implementation must
# check ALL of today's backups, not just the first one `find` happens
# to return, or it can miss the match (ISSUE-27).
echo "older content A" > "$BACKUP_DIR/dupe_source_backup_${TODAY}_08:01:00.kdbx"
echo "older content B" > "$BACKUP_DIR/dupe_source_backup_${TODAY}_09:22:00.kdbx"
echo "older content C" > "$BACKUP_DIR/dupe_source_backup_${TODAY}_10:33:00.kdbx"
cp "$SOURCE_FILE" "$BACKUP_DIR/dupe_source_backup_${TODAY}_11:44:00.kdbx"
echo "older content D" > "$BACKUP_DIR/dupe_source_backup_${TODAY}_12:55:00.kdbx"

# Test: an exact match exists among today's backups (not necessarily
# the first one found) -> must be detected as a duplicate.
if check_daily_duplicate "$SOURCE_FILE" "$BACKUP_DIR"; then
    echo "✅ Passed: Exact match among multiple daily backups was detected."
else
    echo "❌ Failed: Existing matching backup was missed among multiple daily backups!"
    exit 1
fi

# Test: no backup content matches source -> must NOT be flagged as duplicate.
echo "brand new content" > "$SOURCE_FILE"
if ! check_daily_duplicate "$SOURCE_FILE" "$BACKUP_DIR"; then
    echo "✅ Passed: Genuinely changed source correctly triggers a new backup."
else
    echo "❌ Failed: Changed source was incorrectly treated as a duplicate!"
    exit 1
fi

rm -f "$SOURCE_FILE"
rm -rf "$BACKUP_DIR"
