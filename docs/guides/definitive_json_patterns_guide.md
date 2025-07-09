# The Definitive Guide to Claude JSON Patterns

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [How Claude Actually Works](#how-claude-actually-works)
3. [Pattern Translation Guide](#pattern-translation-guide)
4. [Working Examples by Category](#working-examples-by-category)
5. [Pipeline Patterns](#pipeline-patterns)
6. [Performance Optimization](#performance-optimization)
7. [Troubleshooting Guide](#troubleshooting-guide)
8. [Best Practices Checklist](#best-practices-checklist)

## Executive Summary

After extensive testing, we've discovered that Claude's `-p` flag with JSON patterns works fundamentally differently than the original examples suggest:

- ❌ **Claude does NOT evaluate code** - No JavaScript expressions, conditionals, or method calls
- ✅ **Claude DOES understand natural language** - Describe what you want in words
- ✅ **Claude DOES output literal JSON** - Specify exact structure you want
- ⚠️ **Performance varies widely** - Simple patterns: 5-10s, Complex: 15-30s, Very complex: timeout

## How Claude Actually Works

### What Claude Sees

When you write:
```bash
claude -p '{n:5,big:n>10?"yes":"no"}'
```

Claude sees this as a **template description**, not executable code. It will try to output something JSON-like, but won't evaluate `n>10`.

### What Works Instead

```bash
claude -p 'Output JSON where n is 5 and big is "no" because 5 is not greater than 10: {"n":5,"big":"no"}'
```

## Pattern Translation Guide

### 1. Conditionals

| Original | Working Alternative |
|----------|-------------------|
| `{value:x>10?"big":"small"}` | `Output JSON where value is "big" if x>10, else "small"` |
| `{status:error?"failed":"ok"}` | `Output JSON with status based on whether error exists` |
| `condition?valueA:valueB` | `"valueA if condition is true, otherwise valueB"` |

### 2. Ellipsis (...)

| Original | Working Alternative |
|----------|-------------------|
| `{data:...}` | `Output JSON with data containing the input` |
| `{items:[...]}` | `Output JSON with items array containing relevant elements` |
| `{meta:{...}}` | `Output JSON with meta object containing metadata` |

### 3. Array Operations

| Original | Working Alternative |
|----------|-------------------|
| `[...base,"new"]` | `array containing base elements plus "new"` |
| `values.map(v=>v*2)` | `array with each value doubled` |
| `items.filter(x=>x>5)` | `array containing only items greater than 5` |

### 4. Object Methods

| Original | Working Alternative |
|----------|-------------------|
| `str.toLowerCase()` | `string converted to lowercase` |
| `arr.length` | `number of elements in array` |
| `obj.hasOwnProperty(key)` | `whether object has the key` |

### 5. Dynamic Properties

| Original | Working Alternative |
|----------|-------------------|
| `{[key]:value}` | `object with dynamic key set to value` |
| `type=="user"?userSchema:productSchema` | `schema appropriate for the type` |

## Working Examples by Category

### Basic Structures

```bash
# Simple object
echo "test" | claude -p 'Output JSON: {"message":"Hello","status":"ok"}'

# Nested object
echo "data" | claude -p 'Output JSON: {"outer":{"middle":{"inner":"data"}}}'

# Array
echo "list" | claude -p 'Output JSON: {"items":["apple","banana","cherry"]}'

# Mixed structure
echo "complex" | claude -p 'Output JSON: {"name":"complex","tags":["important","urgent"],"meta":{"created":"today"}}'
```

### Input Incorporation

```bash
# Direct input
echo "John" | claude -p 'Output JSON with name from input: {"name":"John"}'

# Transformed input
echo "HELLO" | claude -p 'Output JSON with input lowercase: {"original":"HELLO","lower":"hello"}'

# Parsed input
echo "user@example.com" | claude -p 'Output JSON parsing email: {"email":"user@example.com","domain":"example.com"}'
```

### Conditional Logic (Natural Language)

```bash
# Value-based conditions
echo "15" | claude -p 'Output JSON where value is 15 and category is "high" since 15>10: {"value":15,"category":"high"}'

# State-based output
echo "error" | claude -p 'Output JSON for error state with appropriate status code: {"state":"error","code":500,"message":"An error occurred"}'

# Role-based fields
echo "admin" | claude -p 'Output JSON for admin with all permissions: {"role":"admin","permissions":["read","write","delete","admin"]}'
```

### Arrays and Collections

```bash
# Static arrays
echo "x" | claude -p 'Output JSON: {"colors":["red","green","blue"]}'

# Conditional arrays
echo "3" | claude -p 'Output JSON with 3 items in array: {"count":3,"items":["item1","item2","item3"]}'

# Nested arrays
echo "matrix" | claude -p 'Output JSON with 2D array: {"matrix":[[1,2],[3,4],[5,6]]}'
```

### Validation Patterns

```bash
# Email validation
echo "test@example.com" | claude -p 'Output JSON validating email format: {"email":"test@example.com","valid":true,"domain":"example.com"}'

# Range validation
echo "7" | claude -p 'Output JSON checking if 7 is between 1-10: {"value":7,"inRange":true,"min":1,"max":10}'

# Type validation
echo "123" | claude -p 'Output JSON with type checks: {"input":"123","isNumber":true,"isString":false,"parsed":123}'
```

### Dynamic Schemas

```bash
# Type-based schema
echo "user" | claude -p 'Output JSON schema for user type: {"type":"user","fields":{"id":"number","name":"string","email":"string","role":"string"}}'

# Nested schema
echo "api" | claude -p 'Output JSON API schema: {"endpoints":{"/users":{"methods":["GET","POST"]},"/auth":{"methods":["POST"]}}}'
```

## Pipeline Patterns

### Basic Pipeline (2 stages)

```bash
# Stage 1: Extract
result1=$(echo "Process this text" | claude -p 'Output JSON: {"text":"Process this text","step":1}' --output-format json | jq -r '.result' | tail -n +3 | head -n -1)

# Stage 2: Transform
result2=$(echo "$result1" | claude -p 'Parse JSON input and add step 2: {"previous":1,"step":2,"transformed":true}' --output-format json | jq -r '.result' | tail -n +3 | head -n -1)
```

### Pipeline Helper Function

```bash
#!/bin/bash
claude_pipeline() {
    local input="$1"
    shift
    local current="$input"
    
    for prompt in "$@"; do
        current=$(echo "$current" | claude -p "$prompt" --output-format json 2>/dev/null | jq -r '.result' | sed '/^```/d' | sed '/^$/d')
        if [ $? -ne 0 ]; then
            echo "Pipeline failed at: $prompt" >&2
            return 1
        fi
    done
    
    echo "$current"
}

# Usage
result=$(claude_pipeline "start" \
    'Output JSON: {"step":1,"data":"start"}' \
    'Parse JSON and advance: {"step":2,"previous":1}' \
    'Parse JSON and finalize: {"step":3,"complete":true}')
```

## Performance Optimization

### Caching Strategy

```bash
#!/bin/bash
# Cache Claude responses
CACHE_DIR="/tmp/claude_cache"
mkdir -p "$CACHE_DIR"

cached_claude() {
    local prompt="$1"
    local input="$2"
    local cache_key=$(echo "${prompt}:${input}" | md5sum | cut -d' ' -f1)
    local cache_file="$CACHE_DIR/$cache_key.json"
    
    if [ -f "$cache_file" ] && [ $(find "$cache_file" -mmin -60 | wc -l) -gt 0 ]; then
        cat "$cache_file"
    else
        result=$(echo "$input" | claude -p "$prompt" --output-format json)
        echo "$result" > "$cache_file"
        echo "$result"
    fi
}
```

### Timeout Handling

```bash
#!/bin/bash
claude_with_timeout() {
    local timeout_sec="${3:-15}"
    local prompt="$1"
    local input="$2"
    
    timeout "$timeout_sec" bash -c "echo '$input' | claude -p '$prompt' --output-format json" || {
        echo '{"error":"timeout","message":"Request exceeded '"$timeout_sec"'s"}'
    }
}
```

### Batch Processing

```bash
#!/bin/bash
# Process multiple inputs efficiently
batch_process() {
    local prompt="$1"
    shift
    
    for input in "$@"; do
        echo "Processing: $input"
        result=$(echo "$input" | claude -p "$prompt" --output-format json | jq -r '.result')
        echo "$input -> $result"
        sleep 1  # Rate limiting
    done
}
```

## Troubleshooting Guide

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Timeout | Complex pattern | Simplify prompt, increase timeout |
| Invalid JSON | Markdown wrapper | Strip with `sed '/^```/d'` |
| Unexpected output | Code syntax in prompt | Use natural language |
| Empty result | Failed extraction | Check `.result` field exists |
| Rate limiting | Too many requests | Add delays between calls |

### Debug Helper

```bash
#!/bin/bash
debug_claude() {
    local prompt="$1"
    local input="$2"
    
    echo "=== Debug Info ==="
    echo "Input: $input"
    echo "Prompt: $prompt"
    echo "Command: echo '$input' | claude -p '$prompt' --output-format json"
    echo ""
    echo "=== Raw Output ==="
    result=$(echo "$input" | claude -p "$prompt" --output-format json 2>&1)
    echo "$result"
    echo ""
    echo "=== Extracted Result ==="
    echo "$result" | jq -r '.result' 2>/dev/null || echo "Failed to extract"
    echo ""
    echo "=== Parsed JSON ==="
    echo "$result" | jq -r '.result' 2>/dev/null | sed '/^```/d' | jq . 2>/dev/null || echo "Invalid JSON"
}
```

## Best Practices Checklist

### ✅ DO:
- [ ] Start prompts with "Output JSON:" or similar
- [ ] Describe logic in natural language
- [ ] Use `--output-format json` for reliability
- [ ] Extract with `jq -r '.result'`
- [ ] Handle markdown wrappers (`sed '/^```/d'`)
- [ ] Set reasonable timeouts (10-20s)
- [ ] Cache frequently used patterns
- [ ] Test patterns individually first
- [ ] Document working patterns
- [ ] Use simple, explicit structures

### ❌ DON'T:
- [ ] Use JavaScript syntax expecting evaluation
- [ ] Include conditional operators (`?:`)
- [ ] Use spread syntax (`...array`)
- [ ] Call methods (`.map()`, `.filter()`)
- [ ] Use computed properties
- [ ] Expect variable references to work
- [ ] Chain complex pipelines without error handling
- [ ] Assume Claude understands code context
- [ ] Use template literals
- [ ] Expect mathematical operations

## Quick Reference Card

```bash
# Working JSON Patterns Cheat Sheet

# Basic
echo "input" | claude -p 'Output JSON: {"field":"value"}'

# With input
echo "data" | claude -p 'Output JSON with input as data: {"data":"data"}'

# Conditional (describe it)
echo "5" | claude -p 'Output JSON where n is 5 and size is "small" since 5<10'

# Array
echo "x" | claude -p 'Output JSON with 3-element array: {"items":["a","b","c"]}'

# Nested
echo "x" | claude -p 'Output JSON: {"a":{"b":{"c":"x"}}}'

# Extract result
... | claude -p '...' --output-format json | jq -r '.result' | sed '/^```/d'

# Pipeline
json1=$(echo "x" | claude -p 'Output JSON: {"step":1}' --output-format json | jq -r '.result')
json2=$(echo "$json1" | claude -p 'Parse and advance to step 2' --output-format json | jq -r '.result')
```

## Conclusion

The key insight is that Claude's JSON patterns are **descriptive, not executable**. Success comes from:

1. Using natural language to describe desired output
2. Providing explicit JSON structures
3. Handling responses properly with `jq` and `sed`
4. Setting appropriate timeouts
5. Testing and documenting what works

The original vision of JavaScript-like syntax evaluation doesn't match Claude's current capabilities, but powerful JSON workflows are still achievable with the right approach.