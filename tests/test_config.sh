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