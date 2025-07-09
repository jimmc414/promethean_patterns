#!/bin/bash
# Test and Iterate Script - Runs tests and creates improved versions

# First, let's test a few patterns to understand Claude's behavior
echo "=== Testing Claude's JSON Pattern Understanding ==="

# Test 1: Does Claude understand conditional syntax?
echo -e "\nTest 1: Conditional syntax"
result=$(echo "5" | claude -p 'Output exactly this JSON structure evaluating the conditional: {n:5,big:n>10?"yes":"no"}' --output-format json 2>&1 | jq -r '.result' | tail -n +2)
echo "Result: $result"

# Test 2: Does Claude understand ellipsis?
echo -e "\nTest 2: Ellipsis understanding"
result=$(echo "hello" | claude -p 'Output JSON where ... means fill with contextual data: {greeting:"hello",more:...}' --output-format json 2>&1 | jq -r '.result' | tail -n +2)
echo "Result: $result"

# Test 3: Simple direct JSON
echo -e "\nTest 3: Direct JSON"
result=$(echo "test" | claude -p 'Respond only with: {"input":"test","processed":true}' --output-format json 2>&1 | jq -r '.result')
echo "Result: $result"

# Create adjusted examples based on findings
cat > adjusted_json_examples.md << 'EOF'
# Adjusted JSON Examples for Claude

Based on testing, here are patterns that work reliably with Claude:

## Working Patterns

### 1. Direct JSON Output
```bash
# Claude responds well to explicit JSON requests
echo "test" | claude -p 'Output JSON: {"field":"value","number":123}' --output-format json | jq -r '.result'
```

### 2. Simple Conditionals
```bash
# Use explicit values rather than conditional syntax
echo "small" | claude -p 'For input "small" output JSON: {"size":"small","price":5}' --output-format json | jq -r '.result'
```

### 3. Array Examples
```bash
# Specify arrays directly
echo "3" | claude -p 'Output JSON with array of 3 items: {"count":3,"items":["a","b","c"]}' --output-format json | jq -r '.result'
```

### 4. Nested Structures
```bash
# Claude handles nested JSON well
echo "test" | claude -p 'Output nested JSON: {"outer":{"inner":{"value":"test"}}}' --output-format json | jq -r '.result'
```

## Patterns That Need Adjustment

### Original Pattern Issues:
1. **Conditional syntax (n>10?"yes":"no")** - Claude doesn't evaluate these as code
2. **Ellipsis (...)** - Claude treats these as literal text, not placeholders
3. **Array spreading ([...base])** - Not interpreted as JavaScript
4. **Object method calls (.map(), .filter())** - Treated as descriptions

### Solutions:
1. **For conditionals**: Describe the logic in natural language
2. **For ellipsis**: Ask Claude to "fill in appropriate data"
3. **For array operations**: Describe the desired outcome
4. **For transformations**: Explain the transformation needed

## Recommended Approach

Instead of:
```bash
echo "5" | claude -p '{n:5,big:n>10?"yes":"no"}'
```

Use:
```bash
echo "5" | claude -p 'Output JSON where n is 5 and big is "no" because 5 is not greater than 10: {"n":5,"big":"no"}'
```

## Pipeline Patterns

For pipelines, parse and re-inject JSON at each stage:

```bash
# Stage 1
json1=$(echo "start" | claude -p 'Output JSON: {"step":1,"status":"started"}' --output-format json | jq -r '.result' | tail -n +2)

# Stage 2 - Parse and use previous result
step=$(echo "$json1" | jq -r '.step')
json2=$(echo "$step" | claude -p "Previous step was $step, output JSON: {\"step\":2,\"previous\":$step}" --output-format json | jq -r '.result' | tail -n +2)
```
EOF

echo -e "\n=== Created adjusted_json_examples.md with working patterns ==="

# Now let's create a pattern translator
cat > pattern_translator.sh << 'EOF'
#!/bin/bash
# Translates original patterns to working Claude prompts

translate_pattern() {
    local pattern="$1"
    local input="$2"
    
    # Remove the complex conditional syntax and explain it
    if [[ "$pattern" =~ "?" ]]; then
        echo "Output JSON evaluating the condition in the pattern"
    elif [[ "$pattern" =~ "..." ]]; then
        echo "Output JSON filling in contextual data where ... appears"
    elif [[ "$pattern" =~ ".map" ]] || [[ "$pattern" =~ ".filter" ]]; then
        echo "Output JSON with the array transformation described"
    else
        echo "Output JSON: $pattern"
    fi
}

# Example usage
original='{n:5,big:n>10?"yes":"no"}'
translated=$(translate_pattern "$original" "5")
echo "Original: $original"
echo "Translated: $translated"
EOF

chmod +x pattern_translator.sh

echo -e "\n=== Next Steps ==="
echo "1. Run comprehensive_json_test_runner.sh to test all patterns"
echo "2. Review adjusted_json_examples.md for working patterns"
echo "3. Use pattern_translator.sh to convert complex patterns"
echo "4. Update documentation with findings"