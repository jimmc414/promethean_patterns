#!/bin/bash
# Quick Pattern Testing - Lightweight tests

echo "=== Quick JSON Pattern Tests ==="

# Test 1: Most basic JSON
echo -e "\n1. Basic JSON:"
echo "test" | timeout 10 claude -p 'Reply: {"ok":true}' --output-format json 2>&1 | jq -r '.result' 2>/dev/null || echo "FAILED/TIMEOUT"

# Test 2: With input reference  
echo -e "\n2. Input reference:"
echo "hello" | timeout 10 claude -p 'Reply with JSON where input is the greeting: {"greeting":"hello"}' --output-format json 2>&1 | jq -r '.result' 2>/dev/null || echo "FAILED/TIMEOUT"

# Test 3: Nested structure
echo -e "\n3. Nested:"
echo "x" | timeout 10 claude -p 'JSON: {"a":{"b":{"c":"deep"}}}' --output-format json 2>&1 | jq -r '.result' 2>/dev/null || echo "FAILED/TIMEOUT"

echo -e "\n=== Key Findings ==="
cat << 'EOF'

Based on testing, here's what works with Claude:

1. **Explicit JSON requests**: Start with "Output JSON:", "Reply with JSON:", etc.
2. **Literal structures**: Claude outputs the exact JSON structure you specify
3. **Natural language conditions**: Describe conditions in words, not code syntax
4. **Simple is better**: Complex JavaScript-like syntax doesn't evaluate

## Working Examples:

```bash
# ✅ Works - Explicit structure
echo "5" | claude -p 'Output JSON: {"number":5,"isSmall":true}'

# ❌ Doesn't work - Conditional syntax  
echo "5" | claude -p '{n:5,big:n>10?"yes":"no"}'

# ✅ Works - Natural language
echo "5" | claude -p 'Output JSON where n is 5 and big is "no" since 5 < 10'
```

## For Testing Complex Patterns:

1. Break into smaller pieces
2. Use explicit values instead of conditionals
3. Chain commands with proper JSON parsing between stages
4. Consider mock testing for syntax validation
EOF