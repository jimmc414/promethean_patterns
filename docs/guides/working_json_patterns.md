# Working JSON Patterns for Claude

## Tested and Verified Patterns

These patterns have been tested and confirmed to work with Claude's `-p` flag.

### 1. Basic JSON Output

```bash
# Simple structure
echo "test" | claude -p 'Output JSON: {"message":"Hello","status":"ok"}'

# With input incorporation
echo "John" | claude -p 'Output JSON with name from input: {"name":"John","id":123}'
```

### 2. Nested Structures

```bash
# Deep nesting
echo "data" | claude -p 'Output JSON: {"level1":{"level2":{"level3":{"data":"deep"}}}}'

# Complex nested
echo "user123" | claude -p 'Output JSON: {"user":{"id":"user123","profile":{"settings":{"theme":"dark"}}}}'
```

### 3. Arrays

```bash
# Static arrays
echo "x" | claude -p 'Output JSON: {"items":["apple","banana","cherry"]}'

# Described arrays
echo "3" | claude -p 'Output JSON with 3 items in array: {"count":3,"items":["a","b","c"]}'
```

### 4. Conditional Logic (Natural Language)

```bash
# Size-based pricing
echo "small" | claude -p 'Output JSON where size is small so price is 5: {"size":"small","price":5}'
echo "large" | claude -p 'Output JSON where size is large so price is 15: {"size":"large","price":15}'

# Role-based fields
echo "admin" | claude -p 'Output JSON for admin role with all permissions: {"role":"admin","permissions":["read","write","delete"]}'
echo "user" | claude -p 'Output JSON for user role with limited permissions: {"role":"user","permissions":["read"]}'
```

### 5. Working Pipeline Patterns

```bash
# Two-stage pipeline with JSON parsing
stage1=$(echo "init" | claude -p 'Output JSON: {"stage":1,"status":"initialized"}' --output-format json | jq -r '.result' | tail -n +3 | head -n -1)
echo "Stage 1 result: $stage1"

stage2=$(echo "$stage1" | claude -p 'Parse the JSON and output: {"stage":2,"received":true,"previous_status":"initialized"}' --output-format json | jq -r '.result' | tail -n +3 | head -n -1)
echo "Stage 2 result: $stage2"
```

### 6. Data Transformation Descriptions

```bash
# String operations
echo "HELLO WORLD" | claude -p 'Output JSON with input converted to lowercase: {"original":"HELLO WORLD","lowercase":"hello world"}'

# Described calculations
echo "5" | claude -p 'Output JSON where number is 5 and doubled is 10: {"number":5,"doubled":10}'
```

### 7. Validation Patterns

```bash
# Email validation
echo "user@example.com" | claude -p 'Output JSON validating email has @ symbol: {"email":"user@example.com","valid":true}'

# Range checking
echo "7" | claude -p 'Output JSON checking if 7 is between 1-10: {"value":7,"inRange":true}'
```

### 8. Error Handling Patterns

```bash
# Error states
echo "error" | claude -p 'Output JSON for error state: {"status":"error","message":"An error occurred","code":500}'

# Success states
echo "ok" | claude -p 'Output JSON for success: {"status":"success","message":"Operation completed","code":200}'
```

### 9. Dynamic Schema Examples

```bash
# User schema
echo "user" | claude -p 'Output JSON schema for user type: {"type":"user","fields":{"name":"string","email":"string","age":"number"}}'

# Product schema  
echo "product" | claude -p 'Output JSON schema for product type: {"type":"product","fields":{"id":"number","name":"string","price":"number"}}'
```

### 10. State Machine Patterns

```bash
# State transitions
echo "pending" | claude -p 'Output JSON for pending state with next state: {"current":"pending","next":"processing","canCancel":true}'
echo "processing" | claude -p 'Output JSON for processing state: {"current":"processing","next":"complete","canCancel":false}'
```

## Utility Functions

### Extract Clean JSON from Claude Response

```bash
#!/bin/bash
claude_json() {
    local prompt="$1"
    local input="${2:-}"
    
    if [ -n "$input" ]; then
        echo "$input" | claude -p "$prompt" --output-format json 2>&1 | jq -r '.result' | tail -n +3 | head -n -1
    else
        claude -p "$prompt" --output-format json 2>&1 | jq -r '.result' | tail -n +3 | head -n -1
    fi
}

# Usage
result=$(claude_json 'Output JSON: {"test":true}' "input data")
```

### Pipeline Helper

```bash
#!/bin/bash
json_pipeline() {
    local stage1_prompt="$1"
    local stage2_prompt="$2"
    local input="$3"
    
    # Stage 1
    local result1=$(echo "$input" | claude -p "$stage1_prompt" --output-format json | jq -r '.result' | tail -n +3 | head -n -1)
    
    # Stage 2 with stage 1 result
    local result2=$(echo "$result1" | claude -p "$stage2_prompt" --output-format json | jq -r '.result' | tail -n +3 | head -n -1)
    
    echo "$result2"
}
```

## Tips for Success

1. **Always prefix with "Output JSON:"** or similar for clarity
2. **Describe conditions in natural language** instead of code syntax
3. **Use --output-format json** and extract with jq for reliability
4. **Keep structures simple** - complex patterns often timeout
5. **Test patterns individually** before combining in pipelines
6. **Handle the markdown wrapper** that Claude sometimes adds
7. **Set timeouts** to prevent hanging on complex patterns
8. **Cache results** when possible to avoid repeated API calls

## What Doesn't Work

Avoid these patterns as Claude won't evaluate them as code:

- ❌ Ternary operators: `condition ? true : false`
- ❌ Spread syntax: `[...array, newItem]`
- ❌ Method calls: `array.map()`, `string.split()`
- ❌ Conditionals: `if (x > y) { ... }`
- ❌ Computed properties: `{[key]: value}`
- ❌ Template literals: `` `${variable}` ``

Instead, describe what you want in plain English!