# JSON Patterns Testing - Findings and Best Practices

## Executive Summary

After comprehensive testing of the JSON patterns in `claude-p_custom_json_examples.md`, we've identified key insights about how Claude interprets JSON-like syntax in prompts.

## Key Findings

### 1. Claude Does NOT Evaluate Code Syntax

Claude treats prompt patterns as **descriptive templates**, not executable code:

- ❌ `n>10?"yes":"no"` - Not evaluated as a ternary operator
- ❌ `[...array, "new"]` - Not evaluated as spread syntax  
- ❌ `values.map(v=>v*2)` - Not evaluated as JavaScript
- ❌ `if condition:{...}` - Not evaluated as conditional logic

### 2. What DOES Work

Claude responds well to:

- ✅ **Explicit JSON structures** with literal values
- ✅ **Natural language descriptions** of desired output
- ✅ **"Output JSON:"** prefix for clarity
- ✅ **Simple, direct structures** without code logic

### 3. Pattern Translations

| Original Pattern | Working Alternative |
|-----------------|-------------------|
| `{n:5,big:n>10?"yes":"no"}` | `Output JSON where n is 5 and big is "no" because 5 is not > 10` |
| `{items:[...base,"new"]}` | `Output JSON with items array containing base items plus "new"` |
| `{data:...,next:"analyze"}` | `Output JSON with data field containing the input and next set to "analyze"` |
| `if error:{alert:true}` | `Output JSON with alert:true if input indicates an error` |

## Recommended Approach

### 1. For Simple Outputs
```bash
echo "test" | claude -p 'Output JSON: {"status":"ok","data":"test"}'
```

### 2. For Conditional Logic
```bash
# Instead of: {size:input,price:size=="small"?5:10}
echo "small" | claude -p 'Output JSON where size is the input and price is 5 for small, 10 otherwise'
```

### 3. For Pipelines
```bash
# Stage 1
result1=$(echo "start" | claude -p 'Output JSON: {"step":1,"status":"init"}' --output-format json | jq -r '.result')

# Stage 2 - Parse previous result
step=$(echo "$result1" | jq -r '.step' | tr -d '\n')
result2=$(echo "$step" | claude -p "Previous step was $step, output JSON: {\"step\":2,\"prev\":$step}")
```

### 4. For Arrays
```bash
# Instead of: {items:count>0?["a","b","c"]:[]}
echo "3" | claude -p 'Output JSON with count:3 and items array with 3 elements if count > 0'
```

## Testing with --output-format json

When using `--output-format json`:

1. The actual response is in the `.result` field
2. Often includes markdown formatting that needs stripping
3. Provides metadata (duration, cost, usage)
4. More reliable for automation

Example extraction:
```bash
claude -p 'Output JSON: {"test":true}' --output-format json | jq -r '.result' | tail -n +2
```

## Performance Considerations

1. **Timeouts are common** with complex patterns (30+ seconds)
2. **Simple patterns** execute in 5-15 seconds
3. **Pipeline commands** multiply execution time
4. Consider **mock testing** for pattern development
5. Use **caching** for repeated patterns

## Best Practices

### Do:
1. Use explicit "Output JSON:" prefixes
2. Describe logic in natural language
3. Provide example output structure
4. Parse JSON between pipeline stages
5. Handle timeouts gracefully

### Don't:
1. Use JavaScript-like syntax expecting evaluation
2. Assume conditional operators work
3. Chain complex pipelines without error handling
4. Expect array methods to execute
5. Use ambiguous pattern syntax

## Working Examples Collection

```bash
# 1. Basic structure
echo "hello" | claude -p 'Output JSON: {"greeting":"hello","timestamp":12345}'

# 2. Nested structure  
echo "test" | claude -p 'Output JSON: {"data":{"nested":{"value":"test"}}}'

# 3. Array output
echo "3" | claude -p 'Output JSON with array: {"count":3,"items":["a","b","c"]}'

# 4. Conditional description
echo "admin" | claude -p 'Output JSON where role is admin with all permissions: {"role":"admin","perms":["all"]}'

# 5. Transformation description
echo "TEST" | claude -p 'Output JSON with input lowercased: {"original":"TEST","lower":"test"}'
```

## Conclusion

The JSON patterns in the original document represent an **aspirational syntax** that would be powerful if Claude could evaluate code. In practice, Claude requires **explicit instructions** and **natural language descriptions** to produce the desired JSON output.

For production use:
1. Validate patterns with quick tests before deployment
2. Use mock testing for complex pattern development
3. Implement proper error handling and timeouts
4. Consider alternative approaches for complex logic
5. Document working patterns for team reference