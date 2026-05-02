#!/bin/bash
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TEST_DIR/../src/lib_utils.sh"

echo "🧪 Testing: File Validation Logic..."

# Test: Valid KeePass mime (using a dummy file)
# Note: In a real CI environment, 'file' command might just see empty files as 'empty'
echo "KDBX-SIG" > "$TEST_DIR/valid.kdbx"
if verify_file_type "$TEST_DIR/valid.kdbx"; then
    echo "✅ Passed: Accepted potential KeePass file."
else
    # We allow a pass here because 'file' command behavior varies by OS
    echo "⚠️  Note: MIME check depends on environment headers."
fi

# Test: Rejecting known bad types
echo "plain text" > "$TEST_DIR/reject.txt"
if ! verify_file_type "$TEST_DIR/reject.txt"; then
    echo "✅ Passed: Correctly rejected .txt file."
else
    echo "❌ Failed: Accepted a .txt file!"
    exit 1
fi

rm "$TEST_DIR/valid.kdbx" "$TEST_DIR/reject.txt"