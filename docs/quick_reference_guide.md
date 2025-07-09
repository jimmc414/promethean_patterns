# Claude JSON Patterns - Quick Reference Guide

## 🚨 The Golden Rule
**Claude does NOT execute code. Use natural language descriptions.**

## ✅ Working Patterns

### Basic JSON
```bash
# Simple structure
claude -p 'Output JSON: {"status":"ok","value":true}'

# With input
echo "hello" | claude -p 'Output JSON with input as message: {"message":"INPUT"}'
```

### Conditionals (Natural Language)
```bash
# Size check
echo "hi" | claude -p 'Output JSON where text is input and size is "small" if < 5 chars else "large"'

# Number comparison  
echo "15" | claude -p 'Output JSON where n is 15 and level is "high" because 15 > 10'

# Role-based
echo "admin" | claude -p 'Output JSON for admin role with all permissions'
```

### Arrays
```bash
# Fixed array
claude -p 'Output JSON: {"items":["a","b","c"]}'

# Dynamic count
echo "3" | claude -p 'Output JSON with count 3 and array of 3 items'

# Filtered
claude -p 'Output JSON with numbers [1,2,3,4,5] and only those > 3'
```

### Transformations
```bash
# Case conversion
echo "HELLO" | claude -p 'Output JSON with input lowercase: {"original":"HELLO","lower":"hello"}'

# Length check
echo "test" | claude -p 'Output JSON with text and its length: {"text":"test","length":4}'
```

## ❌ Failing Patterns

### JavaScript Syntax (ALL FAIL)
```javascript
// Ternary operators
{n:5,big:n>10?"yes":"no"}

// Method calls  
array.map(x=>x*2)
str.toUpperCase()

// Spread operator
[...items,"new"]

// Template literals
`Hello ${name}`
```

## 🔧 Essential Functions

```bash
# Extract JSON properly
claude_json() {
    echo "$1" | timeout 15 claude -p "$2" --output-format json | jq -r '.result' | sed '/^```/d'
}

# Test a pattern
test_pattern() {
    result=$(claude_json "$2" "$1")
    echo "$result" | jq . && echo "✅ Success" || echo "❌ Failed"
}
```

## 📊 Performance Guide

| Pattern Type | Duration | Success Rate |
|-------------|----------|--------------|
| Simple | 10-15s | 95% |
| Conditional | 12-15s | 90% |
| Arrays | 13-15s | 85% |
| Complex | 15-20s | 70% |

## 🎯 Pattern Conversion

| ❌ Old (Fails) | ✅ New (Works) |
|----------------|----------------|
| `n>10?"yes":"no"` | `"yes" if n > 10 else "no"` |
| `[...arr,"new"]` | `array with items plus "new"` |
| `str.toUpperCase()` | `str converted to uppercase` |
| `arr.filter(x=>x>5)` | `only values greater than 5` |

## 💡 Pro Tips

1. **Always test first** - Patterns can be unpredictable
2. **Keep it simple** - Complex patterns often timeout
3. **Cache results** - Same input = same output
4. **Use timeouts** - 15 seconds is reasonable
5. **Extract cleanly** - Handle markdown blocks

## 🚀 Quick Start

```bash
# Load production utilities
source PRODUCTION_PATTERNS_V2.sh

# Test a pattern
validate_pattern 'Output JSON: {"test":true}'

# Use cached execution
cached_claude_json 'Output JSON: {"status":"ready"}'

# Migrate old pattern
migrate_pattern '{n:5,big:n>10?"yes":"no"}'
```

---

*Remember: Natural language wins. Always.*