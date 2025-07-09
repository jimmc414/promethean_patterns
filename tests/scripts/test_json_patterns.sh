#!/bin/bash
# Test JSON patterns with claude using --output-format json

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counter
PASSED=0
FAILED=0
TOTAL=0

# Test function
test_json_pattern() {
    local name="$1"
    local input="$2"
    local prompt="$3"
    local expected_check="$4"
    
    echo -e "\n${YELLOW}Test: $name${NC}"
    echo "Input: $input"
    echo "Prompt: $prompt"
    
    TOTAL=$((TOTAL + 1))
    
    # Run claude with JSON output
    result=$(echo "$input" | claude -p "$prompt" --output-format json 2>&1)
    
    # Check if we got a valid JSON response
    if echo "$result" | jq -e '.result' >/dev/null 2>&1; then
        # Extract the actual result
        json_result=$(echo "$result" | jq -r '.result' | sed 's/^```json//' | sed 's/```$//')
        
        echo "Result: $json_result"
        
        # Run the expected check
        if eval "$expected_check"; then
            echo -e "${GREEN}✓ PASSED${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}✗ FAILED${NC}"
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "${RED}✗ FAILED - Invalid JSON response${NC}"
        echo "Raw output: $result"
        FAILED=$((FAILED + 1))
    fi
}

echo "=== Testing Claude JSON Patterns ==="

# Test 1: Simple JSON output
test_json_pattern \
    "Simple JSON" \
    "test" \
    'Output only this JSON: {"value":"test","success":true}' \
    'echo "$json_result" | jq -e ".success == true"'

# Test 2: Ellipsis expansion
test_json_pattern \
    "Ellipsis expansion" \
    "hello" \
    'Output JSON: {"greeting":"...","expanded":true}' \
    'echo "$json_result" | jq -e ".expanded == true"'

# Test 3: Ternary conditional
test_json_pattern \
    "Ternary conditional" \
    "small" \
    'Output JSON where size is the input: {"size":"small","price":5}' \
    'echo "$json_result" | jq -e ".price == 5"'

# Test 4: Array conditional
test_json_pattern \
    "Conditional array" \
    "3" \
    'Output JSON: {"count":3,"hasItems":true,"items":["a","b","c"]}' \
    'echo "$json_result" | jq -e ".items | length == 3"'

# Test 5: Nested structure
test_json_pattern \
    "Nested structure" \
    "test" \
    'Output JSON: {"data":{"nested":{"value":"test","level":3}}}' \
    'echo "$json_result" | jq -e ".data.nested.level == 3"'

# Test 6: Pipeline state (single command test)
test_json_pattern \
    "State object" \
    "init" \
    'Output JSON: {"state":"init","next":"loading","timestamp":123}' \
    'echo "$json_result" | jq -e ".next == \"loading\""'

# Summary
echo -e "\n=== Test Summary ==="
echo -e "Total tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "Success rate: $(( PASSED * 100 / TOTAL ))%"

# Test pipeline separately (since it's more complex)
echo -e "\n=== Pipeline Test ==="
echo "Testing: echo 'start' | claude -p 'Output JSON: {\"step\":1}' | jq -r '.result' | claude -p 'Previous: INPUT, output JSON: {\"step\":2,\"prev\":1}'"

# First stage
stage1=$(echo "start" | claude -p 'Output JSON: {"step":1,"status":"started"}' --output-format json 2>&1 | jq -r '.result' | sed 's/^```json//' | sed 's/```$//')
echo "Stage 1: $stage1"

# Second stage using first result
if [ -n "$stage1" ]; then
    stage2=$(echo "$stage1" | claude -p 'Parse the JSON input and output: {"step":2,"received":true}' --output-format json 2>&1 | jq -r '.result' | sed 's/^```json//' | sed 's/```$//')
    echo "Stage 2: $stage2"
fi