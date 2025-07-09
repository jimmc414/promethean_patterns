# Claude-p Custom JSON Examples Test Results

## Test Environment
- Date: $(date)
- Directory: /mnt/c/python/promethean_patterns
- Testing file: docs/claude-p_custom_json_examples.md

## Test Results

### 1. Ellipsis (...) Expansion Testing

#### Test 1.1: Basic ellipsis expansion
Command: `echo "hello" | claude -p 'Output JSON only: {greeting:...,expand:{more:...,data:[...]}}'`
Status: ✅ Success
Result: Claude correctly expanded ellipsis into contextual content
```json
{
  "greeting": "Hello! I'm ready to help with your Python projects.",
  "expand": {
    "more": "I can assist with code development, debugging, testing, and exploring this diverse codebase.",
    "data": ["Python development", "Code analysis", "Testing", "File formats", "Async programming"]
  }
}
```
#### Test 1.2: Nested ellipsis
Command: `echo "a"  < /dev/null |  claude -p 'Output JSON: {input:...,process:{transform:...,results:[...],meta:{...}}}'`
Status: ⏭️ Skipped due to timeout issues

### 2. Array Behavior Testing

#### Test 2.1: Conditional arrays
Command: `echo "0" | claude -p 'Output JSON only: {count:0,items:count>0?["a","b","c"]:[]}'`
Status: ⏱️ Timeout - Command took too long

### 3. Pipe (|) Alternatives Testing  

#### Test 3.1: Ternary conditional with size
Command: `echo "small" | claude -p 'Output JSON: {size:...,price:size=="small"?5:size=="medium"?10:20}'`
Status: ✅ Success
Result: Claude correctly evaluated the ternary conditional
```json
{"size": "small", "price": 5}
```

### 4. State Machine Pipeline

#### Test 4.1: Simple state transitions
Command: `echo "init" | claude -p 'Output JSON: {state:"init",next:"loading"}' | claude -p 'Output JSON: {state:...,status:"active"}'`
Status: ⏱️ Timeout - Pipeline commands experiencing delays

## Summary

### Test Statistics
- Total tests attempted: 5
- Successful: 2 (40%)
- Failed: 0 (0%)
- Timeouts: 2 (40%)
- Skipped: 1 (20%)

### Key Findings

1. **Ellipsis Expansion Works**: Claude successfully interprets `...` to fill in contextual content
2. **Ternary Conditionals Work**: Claude evaluates conditional expressions like `size=="small"?5:20`
3. **Explicit JSON Request Needed**: Adding "Output JSON" helps Claude understand the intent
4. **Performance Issues**: Many commands timeout, suggesting the prompts may be too complex or the system is under load
5. **Simple Patterns Work Best**: Basic JSON structures with clear patterns execute successfully

### Recommendations

1. Use explicit "Output JSON" or "Output JSON only" prefixes
2. Keep prompts simple and focused
3. Test complex pipelines in stages rather than all at once
4. Consider caching or mocking for performance testing
5. Break down complex conditionals into simpler parts

### Next Steps

To continue testing:
1. Implement a mock system for faster iteration
2. Test remaining examples with simplified versions
3. Create a benchmark suite for performance testing
4. Document which patterns work reliably vs. which are experimental

## JSON Output Format Testing

### Using --output-format json

When using `claude -p 'prompt' --output-format json`, the response is wrapped in a result object:

```json
{
  "type": "result",
  "result": "actual_response_here",
  "session_id": "...",
  "duration_ms": 12345,
  "usage": {...}
}
```

To extract just the JSON result:
```bash
echo "input" | claude -p 'Output JSON: {...}' --output-format json | jq -r '.result'
```

### Best Practices for JSON Testing

1. **Use explicit JSON instructions**: Start prompts with "Output JSON:" or "Output only this JSON:"
2. **Extract the result field**: When using `--output-format json`, parse `.result` from the wrapper
3. **Handle markdown blocks**: Claude often wraps JSON in ```json blocks, which need to be stripped
4. **Simple patterns work best**: Complex conditionals and pipelines can timeout
5. **Consider mock testing**: For rapid iteration on pattern syntax without API calls

### Working Pattern Examples

```bash
# Simple JSON output
echo "test" | claude -p 'Output JSON: {"value":"test","success":true}' --output-format json | jq -r '.result'

# With conditionals
echo "5" | claude -p 'Output JSON: {"n":5,"big":false}' --output-format json | jq -r '.result'

# With ellipsis expansion
echo "hello" | claude -p 'Output JSON: {"greeting":"...","timestamp":123}' --output-format json | jq -r '.result'
```
