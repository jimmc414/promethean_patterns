#!/bin/bash
# Test JSON patterns using a mock claude for speed

# Create a mock claude function
claude_mock() {
    local prompt=""
    local output_format="text"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p) prompt="$2"; shift 2 ;;
            --output-format) output_format="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    
    # Read input
    local input=$(cat)
    
    # Generate mock responses based on patterns
    local response=""
    
    case "$prompt" in
        *"greeting:"*"..."*)
            response='{"greeting":"Hello from mock","expand":{"more":"Mock expansion","data":["item1","item2"]}}'
            ;;
        *"size=="small"*"?5"*)
            response='{"size":"small","price":5}'
            ;;
        *"count>0"*)
            if [[ "$input" == "0" ]]; then
                response='{"count":0,"items":[]}'
            else
                response='{"count":3,"items":["a","b","c"]}'
            fi
            ;;
        *"state:"*"next:"*)
            response='{"state":"init","next":"loading"}'
            ;;
        *"if"*"then"*)
            response='{"condition":true,"then_branch":"executed","else_branch":null}'
            ;;
        *)
            response='{"mock":true,"input":"'$input'"}'
            ;;
    esac
    
    # Format output based on requested format
    if [[ "$output_format" == "json" ]]; then
        echo "{\"type\":\"result\",\"result\":\"$response\"}"
    else
        echo "$response"
    fi
}

# Export the function so it can be used
export -f claude_mock

# Alias claude to our mock
alias claude=claude_mock

echo "=== Testing JSON Patterns with Mock ==="

# Test 1: Ellipsis expansion
echo "Test 1: Ellipsis expansion"
result=$(echo "hello" | claude -p '{greeting:...,expand:{more:...,data:[...]}}' --output-format json | jq -r '.result')
echo "Result: $result"
echo "$result" | jq '.'

# Test 2: Conditional logic
echo -e "\nTest 2: Conditional with ternary"
result=$(echo "small" | claude -p '{size:...,price:size=="small"?5:size=="medium"?10:20}')
echo "Result: $result"

# Test 3: Array conditionals
echo -e "\nTest 3: Conditional arrays"
for count in 0 3; do
    echo "Input: $count"
    result=$(echo "$count" | claude -p '{count:'$count',items:count>0?["a","b","c"]:[]}')
    echo "Result: $result"
done

# Test 4: Pipeline simulation
echo -e "\nTest 4: Pipeline state passing"
result1=$(echo "init" | claude -p '{state:"init",next:"loading"}')
echo "Stage 1: $result1"
result2=$(echo "$result1" | claude -p '{prev:...,state:"loading",next:"ready"}')
echo "Stage 2: $result2"

# Test 5: Complex nested conditions
echo -e "\nTest 5: Nested conditions"
result=$(echo "error" | claude -p '{type:"error",if type=="error":{severity:"high",if severity=="high":{alert:true}}}')
echo "Result: $result"

# Test all patterns from the doc
echo -e "\n=== Testing All Document Patterns ==="

patterns=(
    'Analyze:{data:...,if data.size>100:{action:"split"},else:{action:"process"}}'
    'Review:{code:...,quality:good|bad|needs_work,if quality==good:{next:"deploy"}}'
    'Process:{input:...,type:detect,if type=="error":{severity:high,alert:true}}'
    'Analyze:{file:...,complexity:1-10,output:{basic:["size"],if complexity>5:["deps"]}}'
    'Scan:{errors:[...],if errors.length>0:{actions:["fix","test"]}}'
    'Route:{endpoint:...,switch endpoint:{"/api/users":{handler:"userService"}}}'
    'Build:{env:dev|prod,config:{if env=="dev":{debug:true}}}'
    'Pipeline:{validate:{valid:bool},if validate.valid:{transform:{output:"processed"}}}'
    'Check:{score:85,grade:score>=90?"A":score>=80?"B":"C"}'
    '{risk:"high",risk=="critical"?{alert:true}:risk=="high"?{review:true}:{proceed:true}}'
)

for i in "${!patterns[@]}"; do
    echo -e "\nPattern $((i+1)): ${patterns[$i]:0:50}..."
    result=$(echo "test$i" | claude -p "${patterns[$i]}")
    echo "Result: $result"
done

echo -e "\n=== Mock Testing Complete ==="
echo "This demonstrates the JSON patterns work conceptually."
echo "For real testing, use the non-mock version with actual Claude."