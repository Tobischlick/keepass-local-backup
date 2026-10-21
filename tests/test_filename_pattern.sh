#!/bin/bash
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TEST_DIR/../src/lib_utils.sh"

echo "🧪 Testing: Backup Filename Pattern..."

FIXTURE_SRC="$TEST_DIR/pattern_source.kdbx"
FIXTURE_BACKUP_DIR="$TEST_DIR/pattern_backup_dir"

# KeePass 2 magic header + random bytes: the magic pins `file --mime-type`
# to a type verify_file_type accepts (pure random bytes are occasionally
# sniffed as e.g. application/x-dosexec); plain text via `echo` reports
# text/plain and would be rejected before a destination filename is built.
{ printf '\x03\xd9\xa2\x9a\x67\xfb\x4b\xb5'; head -c 248 /dev/urandom; } > "$FIXTURE_SRC"
rm -rf "$FIXTURE_BACKUP_DIR"

# Drive the real script end-to-end. SOURCE_DB/BACKUP_DIR/RETENTION_DAYS
# are injected as env vars, which backup_keepass.sh honors instead of
# requiring a .env file (see its step 3).
SOURCE_DB="$FIXTURE_SRC" BACKUP_DIR="$FIXTURE_BACKUP_DIR" RETENTION_DAYS=30 \
    "$TEST_DIR/../src/backup_keepass.sh" --now

RESULT_FILE=$(find "$FIXTURE_BACKUP_DIR" -maxdepth 1 -name "*.kdbx" -type f -print -quit 2>/dev/null)
RESULT_NAME=$(basename "$RESULT_FILE" 2>/dev/null)

# Test: filename matches BASENAME_backup_YYYY-MM-DD_HH:MM:SS.kdbx exactly
if [[ -n "$RESULT_NAME" && "$RESULT_NAME" =~ ^pattern_source_backup_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}:[0-9]{2}\.kdbx$ ]]; then
    echo "✅ Passed: Filename matches expected pattern ($RESULT_NAME)."
else
    echo "❌ Failed: Filename '$RESULT_NAME' did not match expected pattern!"
    exit 1
fi

# Test: source extension was stripped, not left dangling before "_backup_"
# (regression fixed in ISSUE-20: 'pattern_source.kdbx_backup_...kdbx')
if [[ "$RESULT_NAME" != *".kdbx_backup_"* ]]; then
    echo "✅ Passed: No double .kdbx extension in filename."
else
    echo "❌ Failed: Double extension detected in filename!"
    exit 1
fi

# Test: check_daily_duplicate's glob stays in sync with the real filename format
if check_daily_duplicate "$FIXTURE_SRC" "$FIXTURE_BACKUP_DIR"; then
    echo "✅ Passed: check_daily_duplicate recognizes the generated filename pattern."
else
    echo "❌ Failed: check_daily_duplicate did not match the generated filename (glob out of sync)!"
    exit 1
fi

rm -f "$FIXTURE_SRC"
rm -rf "$FIXTURE_BACKUP_DIR"
