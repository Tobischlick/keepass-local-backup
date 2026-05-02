#!/bin/bash
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TEST_DIR/../src/lib_utils.sh"

echo "🧪 Testing: Integrity Logic..."

echo "original data" > "$TEST_DIR/source.kdbx"
echo "original data" > "$TEST_DIR/match.kdbx"
echo "corrupted data" > "$TEST_DIR/fail.kdbx"

# Test: Matching files
if verify_checksum "$TEST_DIR/source.kdbx" "$TEST_DIR/match.kdbx"; then
    echo "✅ Passed: Hashes matched correctly."
else
    echo "❌ Failed: Hashes should have matched!"
    exit 1
fi

# Test: Mismatched files
if ! verify_checksum "$TEST_DIR/source.kdbx" "$TEST_DIR/fail.kdbx"; then
    echo "✅ Passed: Correctly detected corruption."
else
    echo "❌ Failed: Accepted a corrupted hash!"
    exit 1
fi

rm "$TEST_DIR/source.kdbx" "$TEST_DIR/match.kdbx" "$TEST_DIR/fail.kdbx"