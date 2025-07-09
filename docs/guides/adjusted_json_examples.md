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
