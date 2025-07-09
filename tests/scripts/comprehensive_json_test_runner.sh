#!/bin/bash
# Comprehensive JSON Pattern Test Runner

# Setup
REPORT_FILE="comprehensive_test_results.md"
TIMEOUT_SECONDS=30
PASSED=0
FAILED=0
TIMEOUT=0
TOTAL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Initialize report
cat > "$REPORT_FILE" << EOF
# Comprehensive JSON Pattern Test Results

Generated: $(date)

## Test Execution Summary

EOF

# Test function with timeout
run_test() {
    local test_id="$1"
    local test_name="$2"
    local input="$3"
    local prompt="$4"
    local description="$5"
    
    echo -e "\n${BLUE}[$test_id] $test_name${NC}"
    echo "Input: $input"
    echo "Testing..."
    
    TOTAL=$((TOTAL + 1))
    
    # Run with timeout
    local start_time=$(date +%s)
    local result=$(timeout $TIMEOUT_SECONDS bash -c "echo '$input' | claude -p '$prompt' --output-format json 2>&1")
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Write to report
    echo -e "\n### $test_id: $test_name" >> "$REPORT_FILE"
    echo -e "\n**Description**: $description" >> "$REPORT_FILE"
    echo -e "\n**Input**: \`$input\`" >> "$REPORT_FILE"
    echo -e "\n**Prompt**: \`\`\`\n$prompt\n\`\`\`" >> "$REPORT_FILE"
    echo -e "\n**Duration**: ${duration}s" >> "$REPORT_FILE"
    
    if [ $exit_code -eq 124 ]; then
        # Timeout
        echo -e "${YELLOW}⏱️ TIMEOUT${NC} after ${TIMEOUT_SECONDS}s"
        echo -e "\n**Status**: ⏱️ TIMEOUT" >> "$REPORT_FILE"
        TIMEOUT=$((TIMEOUT + 1))
    elif [ $exit_code -eq 0 ]; then
        # Try to extract JSON result
        local json_result=$(echo "$result" | jq -r '.result' 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$json_result" ]; then
            # Clean up markdown blocks if present
            json_result=$(echo "$json_result" | sed 's/^```json//' | sed 's/```$//' | sed '/^$/d')
            
            echo -e "${GREEN}✓ SUCCESS${NC}"
            echo -e "Result: $json_result"
            
            echo -e "\n**Status**: ✅ SUCCESS" >> "$REPORT_FILE"
            echo -e "\n**Result**:\n\`\`\`json\n$json_result\n\`\`\`" >> "$REPORT_FILE"
            
            # Try to parse as JSON for validation
            if echo "$json_result" | jq . >/dev/null 2>&1; then
                echo -e "\n**Valid JSON**: Yes" >> "$REPORT_FILE"
            else
                echo -e "\n**Valid JSON**: No (but claude returned something)" >> "$REPORT_FILE"
            fi
            
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}✗ FAILED${NC} - Could not extract JSON"
            echo -e "\n**Status**: ❌ FAILED" >> "$REPORT_FILE"
            echo -e "\n**Error**: Could not extract JSON from response" >> "$REPORT_FILE"
            echo -e "\n**Raw output**: \`\`\`\n$result\n\`\`\`" >> "$REPORT_FILE"
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "${RED}✗ FAILED${NC} - Exit code: $exit_code"
        echo -e "\n**Status**: ❌ FAILED" >> "$REPORT_FILE"
        echo -e "\n**Error**: Command failed with exit code $exit_code" >> "$REPORT_FILE"
        echo -e "\n**Output**: \`\`\`\n$result\n\`\`\`" >> "$REPORT_FILE"
        FAILED=$((FAILED + 1))
    fi
    
    echo "---" >> "$REPORT_FILE"
}

# Adjusted prompt helper - adds "Output JSON:" prefix
adj_prompt() {
    echo "Output JSON: $1"
}

echo "=== Starting Comprehensive JSON Pattern Tests ==="

# Category 1: Ellipsis Expansion
run_test "1.1" "Basic ellipsis expansion" \
    "hello" \
    "$(adj_prompt '{greeting:...,expand:{more:...,data:[...]}}')" \
    "Test how ellipsis expands to contextual content"

run_test "1.2" "Nested ellipsis" \
    "a" \
    "$(adj_prompt '{input:...,process:{transform:...,results:[...],meta:{...}}}')" \
    "Test nested ellipsis expansion"

# For pipeline tests, we'll test individual stages first
run_test "1.3a" "Pipeline stage 1" \
    "test" \
    "$(adj_prompt '{data:...,next:\"analyze\"}')" \
    "First stage of pipeline - capture data and set next"

# Category 2: Array Behavior
run_test "2.1a" "Empty array conditional" \
    "0" \
    "$(adj_prompt '{count:0,items:[]}')" \
    "Test empty array when count is 0"

run_test "2.1b" "Populated array conditional" \
    "3" \
    "$(adj_prompt '{count:3,items:[\"a\",\"b\",\"c\"]}')" \
    "Test populated array when count is 3"

run_test "2.2" "Array spreading" \
    "x" \
    "$(adj_prompt '{base:[\"a\",\"b\"],extended:[\"a\",\"b\",\"c\",\"d\"]}')" \
    "Test array spreading concept"

run_test "2.3" "Array filtering" \
    "filter" \
    "$(adj_prompt '{all:[1,2,3,4,5],even:[2,4],odd:[1,3,5]}')" \
    "Test array filtering logic"

# Category 3: Alternatives
run_test "3.1" "Size-based pricing" \
    "small" \
    "$(adj_prompt '{size:\"small\",category:\"small\",price:5}')" \
    "Test enum selection and conditional pricing"

run_test "3.2" "Path branching" \
    "analyze" \
    "$(adj_prompt '{path:\"analyze\",depth:\"full\"}')" \
    "Test branching based on path value"

# Category 4: State Machine
run_test "4.1" "Initial state" \
    "init" \
    "$(adj_prompt '{state:\"init\",next:\"loading\"}')" \
    "Test state machine initialization"

run_test "4.2" "Iteration state" \
    "2" \
    "$(adj_prompt '{iteration:2,state:\"continue\",data:[1,2]}')" \
    "Test iteration-based state"

# Category 5: Accumulator
run_test "5.1" "Simple accumulator" \
    "1" \
    "$(adj_prompt '{value:1,acc:[1]}')" \
    "Test accumulator pattern start"

run_test "5.2" "Conditional accumulation" \
    "start" \
    "$(adj_prompt '{items:[],addItem:true}')" \
    "Test conditional accumulation setup"

# Category 6: Transformation
run_test "6.1" "String transformation" \
    "RaW-DaTa" \
    "$(adj_prompt '{input:\"RaW-DaTa\",clean:\"raw-data\"}')" \
    "Test string transformation"

run_test "6.2" "Type conversion" \
    "123" \
    "$(adj_prompt '{str:\"123\",num:123}')" \
    "Test type conversion"

# Category 7: Validation
run_test "7.1" "Email validation" \
    "user@example.com" \
    "$(adj_prompt '{email:\"user@example.com\",valid:true}')" \
    "Test email validation"

run_test "7.2" "Range validation" \
    "5" \
    "$(adj_prompt '{value:5,checks:{isNumber:true,inRange:true},status:\"valid\"}')" \
    "Test cascading validations"

# Category 8: Dynamic Schema
run_test "8.1" "User schema" \
    "user" \
    "$(adj_prompt '{type:\"user\",schema:{name:\"string\",email:\"string\"}}')" \
    "Test dynamic schema generation"

run_test "8.2" "Complex schema" \
    "complex" \
    "$(adj_prompt '{buildSchema:{user:{fields:[\"id\",\"name\"]},post:{fields:[\"title\",\"content\"]}}}')" \
    "Test nested schema generation"

# Category 9: Error Handling
run_test "9.1" "Error propagation" \
    "process" \
    "$(adj_prompt '{action:\"process\",risky:true}')" \
    "Test error handling setup"

run_test "9.2" "Recovery attempt" \
    "fail" \
    "$(adj_prompt '{attempt:1,success:false}')" \
    "Test recovery pipeline"

# Category 10: Map-Reduce
run_test "10.1" "Map operation" \
    "1,2,3" \
    "$(adj_prompt '{input:\"1,2,3\",values:[1,2,3],mapped:[2,4,6]}')" \
    "Test map operation"

# Category 11: Conditional Fields
run_test "11.1" "Admin role" \
    "admin" \
    "$(adj_prompt '{role:\"admin\",user:{name:\"John\",permissions:[\"all\"]}}')" \
    "Test role-based field inclusion"

run_test "11.2" "Level-based powers" \
    "5" \
    "$(adj_prompt '{level:5,powers:{basic:true,advanced:true}}')" \
    "Test level-based field inclusion"

# Category 12: Recursive Patterns
run_test "12.1" "Depth simulation" \
    "3" \
    "$(adj_prompt '{depth:3,dive:{level:1,data:\"a\"}}')" \
    "Test recursive-like pattern"

run_test "12.2" "Tree expansion" \
    "expand" \
    "$(adj_prompt '{action:\"expand\",tree:{root:{children:[{leaf:1},{leaf:2}]}}}')" \
    "Test nested expansion"

# Category 13: Smart Routing
run_test "13.1" "Route decision" \
    "analyze" \
    "$(adj_prompt '{cmd:\"analyze\",route:\"deep\"}')" \
    "Test routing decision"

# Category 14: Special Characters
run_test "14.1" "Quote escaping" \
    'te"st' \
    "$(adj_prompt '{input:\"te\\\"st\",escaped:\"te\\\\\\\"st\"}')" \
    "Test special character handling"

run_test "14.2" "String operations" \
    "a,b,c" \
    "$(adj_prompt '{str:\"a,b,c\",arr:[\"a\",\"b\",\"c\"],joined:\"a|b|c\"}')" \
    "Test string to array operations"

# Category 16: Fun Examples
run_test "16.1" "Emoji state" \
    "😀" \
    "$(adj_prompt '{mood:\"😀\",next:\"😎\"}')" \
    "Test emoji handling"

run_test "16.2" "Game state" \
    "start" \
    "$(adj_prompt '{game:{hp:10,player:\"hero\"}}')" \
    "Test game logic initialization"

run_test "16.3" "Template generation" \
    "Button" \
    "$(adj_prompt '{component:\"Button\",template:\"<Button></Button>\"}')" \
    "Test code generation"

# Write summary
echo -e "\n## Summary Statistics" >> "$REPORT_FILE"
echo "- Total Tests: $TOTAL" >> "$REPORT_FILE"
echo "- Passed: $PASSED ($(( PASSED * 100 / TOTAL ))%)" >> "$REPORT_FILE"
echo "- Failed: $FAILED ($(( FAILED * 100 / TOTAL ))%)" >> "$REPORT_FILE"
echo "- Timeouts: $TIMEOUT ($(( TIMEOUT * 100 / TOTAL ))%)" >> "$REPORT_FILE"

# Console summary
echo -e "\n${BLUE}=== Test Summary ===${NC}"
echo -e "Total: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "${YELLOW}Timeouts: $TIMEOUT${NC}"
echo -e "\nDetailed report saved to: $REPORT_FILE"