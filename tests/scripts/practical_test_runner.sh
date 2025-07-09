#!/bin/bash
# Practical Test Runner - Actually runs and documents real results

REPORT="practical_test_results.md"

# Initialize report
cat > "$REPORT" << 'EOF'
# Practical JSON Pattern Test Results

Generated: $(date)

## Real Test Results

These are actual test results from running Claude with various JSON patterns.

EOF

# Simple test function
test_pattern() {
    local name="$1"
    local input="$2"
    local pattern="$3"
    
    echo "Testing: $name"
    echo "Input: $input"
    
    # Run test with short timeout
    result=$(timeout 10 bash -c "echo '$input' | claude -p '$pattern' --output-format json 2>&1" || echo '{"error":"TIMEOUT"}')
    
    # Try to extract JSON
    if echo "$result" | jq -e '.result' >/dev/null 2>&1; then
        json=$(echo "$result" | jq -r '.result' | sed 's/^```json//' | sed 's/```$//' | sed '/^$/d')
        echo "✓ Success"
        echo "$json"
    else
        echo "✗ Failed"
        echo "$result"
    fi
    
    # Write to report
    cat >> "$REPORT" << EOF

### Test: $name
**Input:** \`$input\`  
**Pattern:** \`$pattern\`  
**Result:**
\`\`\`
$(echo "$result" | jq -r '.result // .error' 2>/dev/null || echo "$result")
\`\`\`

EOF
}

echo "=== Running Practical Tests ==="

# Test 1: Most basic
test_pattern "Basic JSON" "test" 'Output JSON: {"status":"ok"}'

# Test 2: With input
test_pattern "Input reference" "hello" 'Output JSON where input is greeting: {"greeting":"hello"}'

# Test 3: Simple conditional description  
test_pattern "Conditional (natural language)" "5" 'Output JSON where n is 5 and big is "no" because 5 is less than 10'

# Test 4: Array
test_pattern "Array output" "3" 'Output JSON with array: {"count":3,"items":["a","b","c"]}'

# Test 5: What happens with original syntax?
test_pattern "Original syntax test" "5" '{n:5,big:n>10?"yes":"no"}'

echo -e "\nReport saved to: $REPORT"