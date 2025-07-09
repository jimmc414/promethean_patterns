#!/bin/bash
# Production-Ready Claude JSON Patterns
# Tested and verified patterns you can use immediately

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Utility Functions

# Extract clean JSON from Claude response
claude_json() {
    local prompt="$1"
    local input="${2:-}"
    local timeout="${3:-15}"
    
    if [ -n "$input" ]; then
        result=$(timeout "$timeout" bash -c "echo '$input' | claude -p '$prompt' --output-format json 2>&1")
    else
        result=$(timeout "$timeout" bash -c "claude -p '$prompt' --output-format json 2>&1")
    fi
    
    if [ $? -eq 0 ]; then
        # Extract and clean the result
        echo "$result" | jq -r '.result' 2>/dev/null | sed '/^```json/d; /^```/d; /^$/d' | sed 's/^[[:space:]]*//'
    else
        echo '{"error":"timeout or failure"}'
    fi
}

# Cache Claude responses
CACHE_DIR="/tmp/claude_json_cache"
mkdir -p "$CACHE_DIR"

cached_claude_json() {
    local prompt="$1"
    local input="$2"
    local cache_key=$(echo "${prompt}:${input}" | md5sum | cut -d' ' -f1)
    local cache_file="$CACHE_DIR/$cache_key.json"
    
    # Check cache (1 hour expiry)
    if [ -f "$cache_file" ] && [ $(find "$cache_file" -mmin -60 2>/dev/null | wc -l) -gt 0 ]; then
        cat "$cache_file"
    else
        local result=$(claude_json "$prompt" "$input")
        echo "$result" > "$cache_file"
        echo "$result"
    fi
}

# Pipeline helper
json_pipeline() {
    local input="$1"
    shift
    local current="$input"
    
    for prompt in "$@"; do
        current=$(echo "$current" | claude_json "$prompt")
        if echo "$current" | jq -e '.error' >/dev/null 2>&1; then
            echo "Pipeline failed at: $prompt" >&2
            echo "$current"
            return 1
        fi
    done
    
    echo "$current"
}

echo -e "${BLUE}=== Production-Ready Claude JSON Patterns ===${NC}"
echo -e "${YELLOW}Utility functions loaded: claude_json, cached_claude_json, json_pipeline${NC}\n"

# Example 1: User Input Processing
echo -e "${GREEN}Example 1: User Input Processing${NC}"
demo1() {
    local username="$1"
    local age="$2"
    
    result=$(claude_json "Output JSON for user where name is '$username' and age is $age with appropriate user type based on age: {\"name\":\"$username\",\"age\":$age,\"type\":\"adult\" if age>=18 else \"minor\"}")
    echo "$result" | jq .
}
echo "Usage: demo1 \"John Doe\" 25"

# Example 2: Data Validation Pipeline
echo -e "\n${GREEN}Example 2: Data Validation Pipeline${NC}"
demo2() {
    local email="$1"
    
    # Stage 1: Validate format
    stage1=$(claude_json 'Output JSON validating email format: {"email":"'"$email"'","validFormat":true/false based on @ presence}' "$email")
    
    # Stage 2: Extract parts if valid
    if echo "$stage1" | jq -e '.validFormat' >/dev/null 2>&1; then
        stage2=$(echo "$stage1" | claude_json 'Parse the JSON input and extract email parts: {"email":"...","username":"before @","domain":"after @"}')
        echo "$stage2" | jq .
    else
        echo "$stage1" | jq .
    fi
}
echo "Usage: demo2 \"user@example.com\""

# Example 3: Configuration Generator
echo -e "\n${GREEN}Example 3: Configuration Generator${NC}"
demo3() {
    local env="$1"  # dev, staging, prod
    
    result=$(cached_claude_json "Output JSON configuration for $env environment with appropriate settings: {\"env\":\"$env\",\"debug\":true/false based on env,\"logLevel\":\"debug/info/error\",\"features\":{\"cache\":true/false,\"monitoring\":true/false}}" "$env")
    echo "$result" | jq .
}
echo "Usage: demo3 \"dev\" | demo3 \"prod\""

# Example 4: Error Handler
echo -e "\n${GREEN}Example 4: Error Response Generator${NC}"
demo4() {
    local error_type="$1"
    local details="$2"
    
    result=$(claude_json "Output JSON error response for $error_type error: {\"error\":\"$error_type\",\"message\":\"appropriate message\",\"code\":appropriate HTTP code,\"details\":\"$details\",\"timestamp\":\"2024-01-01T00:00:00Z\"}")
    echo "$result" | jq .
}
echo "Usage: demo4 \"not_found\" \"User ID 123 not found\""

# Example 5: Multi-Stage Pipeline
echo -e "\n${GREEN}Example 5: Multi-Stage Analysis Pipeline${NC}"
demo5() {
    local text="$1"
    
    result=$(json_pipeline "$text" \
        'Output JSON analyzing text sentiment: {"text":"input","sentiment":"positive/negative/neutral"}' \
        'Parse JSON and add word count: {"...existing","wordCount":approximate count}' \
        'Parse JSON and add summary: {"...existing","summary":"brief summary of text"}')
    
    echo "$result" | jq .
}
echo "Usage: demo5 \"This is a great product! I love it.\""

# Example 6: Batch Processor
echo -e "\n${GREEN}Example 6: Batch Processing${NC}"
demo6() {
    local items=("$@")
    echo '{"results":[]}'> /tmp/batch_results.json
    
    for item in "${items[@]}"; do
        result=$(claude_json "Output JSON processing item '$item': {\"item\":\"$item\",\"processed\":true,\"category\":\"appropriate category\",\"priority\":1-5}")
        
        # Append to results
        jq --argjson new "$result" '.results += [$new]' /tmp/batch_results.json > /tmp/batch_results_tmp.json
        mv /tmp/batch_results_tmp.json /tmp/batch_results.json
    done
    
    cat /tmp/batch_results.json | jq .
}
echo "Usage: demo6 \"task1\" \"task2\" \"task3\""

# Example 7: Schema Validator
echo -e "\n${GREEN}Example 7: Schema Validation${NC}"
demo7() {
    local json_input="$1"
    local expected_type="$2"  # user, product, order
    
    result=$(echo "$json_input" | claude_json "Validate if this JSON matches $expected_type schema and output: {\"valid\":true/false,\"type\":\"$expected_type\",\"missingFields\":[],\"extraFields\":[],\"issues\":[]}")
    echo "$result" | jq .
}
echo "Usage: demo7 '{\"name\":\"John\",\"email\":\"john@example.com\"}' \"user\""

# Example 8: State Machine
echo -e "\n${GREEN}Example 8: State Machine${NC}"
demo8() {
    local current_state="$1"
    local event="$2"
    
    result=$(claude_json "Output JSON for state machine transition where current state is '$current_state' and event is '$event': {\"currentState\":\"$current_state\",\"event\":\"$event\",\"nextState\":\"appropriate next state\",\"actions\":[],\"allowed\":true/false}")
    echo "$result" | jq .
}
echo "Usage: demo8 \"pending\" \"approve\""

# Example 9: Quick Testing Function
echo -e "\n${GREEN}Example 9: Quick Pattern Tester${NC}"
test_pattern() {
    local pattern="$1"
    local input="${2:-test}"
    
    echo -e "${YELLOW}Testing pattern:${NC} $pattern"
    echo -e "${YELLOW}Input:${NC} $input"
    echo -e "${YELLOW}Result:${NC}"
    
    result=$(claude_json "$pattern" "$input" 10)
    echo "$result" | jq . 2>/dev/null || echo "$result"
}
echo "Usage: test_pattern 'Output JSON: {\"test\":true}' \"input\""

# Interactive menu
echo -e "\n${BLUE}=== Interactive Demo Menu ===${NC}"
echo "Type the demo number (1-9) to run it, or 'q' to quit:"
echo "1. User Input Processing"
echo "2. Data Validation Pipeline"
echo "3. Configuration Generator"
echo "4. Error Response Generator"
echo "5. Multi-Stage Analysis Pipeline"
echo "6. Batch Processing"
echo "7. Schema Validation"
echo "8. State Machine"
echo "9. Quick Pattern Tester"

# Uncomment to enable interactive mode
# while true; do
#     read -p "> " choice
#     case $choice in
#         1) demo1 "Alice Smith" 30 ;;
#         2) demo2 "test@example.com" ;;
#         3) demo3 "dev" ;;
#         4) demo4 "unauthorized" "Invalid API key" ;;
#         5) demo5 "This is amazing! Best purchase ever." ;;
#         6) demo6 "bug" "feature" "documentation" ;;
#         7) demo7 '{"name":"Product","price":29.99}' "product" ;;
#         8) demo8 "pending" "approve" ;;
#         9) test_pattern 'Output JSON: {"working":true}' "test" ;;
#         q) break ;;
#         *) echo "Invalid choice" ;;
#     esac
#     echo
# done

echo -e "\n${GREEN}Ready to use! Source this file to load the functions:${NC}"
echo "source production_ready_patterns.sh"
echo "Then call any demo function or use the utility functions directly."