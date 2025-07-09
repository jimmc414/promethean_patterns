# JSON Output Instruction Pattern

## Overview

The JSON Output Pattern is a fundamental technique for getting structured, machine-readable responses from Claude. By including explicit JSON structure in prompts, Claude understands to format its responses accordingly.

## Basic Concept

When you include explicit JSON structure in Claude's prompt, it understands to format its responses that way:

```bash
claude -p "You are a code analyzer. Output JSON: {analysis: ..., next_file: ...}"
```

This prompt does three things:
1. Sets Claude's role ("code analyzer")
2. Tells Claude to output JSON format
3. Shows the expected structure with example fields

## How Claude Interprets This

Claude sees the JSON pattern and understands it should respond like:

```json
{"analysis": "This function has high cyclomatic complexity", "next_file": "main.py"}
{"analysis": "Found potential SQL injection vulnerability", "next_file": "database.py"}
{"analysis": "No issues found", "next_file": null}
```

## Examples

### Simple Analyzer
```bash
claude -p "Analyze Python functions. Output JSON: {function_name: str, complexity: int, issues: []}"
```

Claude would output:
```json
{"function_name": "process_user_data", "complexity": 15, "issues": ["No input validation", "Missing error handling"]}
{"function_name": "calculate_total", "complexity": 3, "issues": []}
```

### Task Coordinator
```bash
claude -p "You coordinate builds. Output JSON: {action: 'analyze'|'test'|'build', target: str, reason: str}"
```

Claude outputs:
```json
{"action": "analyze", "target": "src/auth.py", "reason": "Changed file detected"}
{"action": "test", "target": "test_auth.py", "reason": "Related to analyzed file"}
{"action": "build", "target": "app", "reason": "All tests passed"}
```

### Multi-Stage Pipeline
```bash
# First Claude
claude -p "Extract functions from code. Output JSON: {type: 'function', name: str, code: str}"

# Second Claude  
claude -p "Generate tests. Input: function JSON. Output JSON: {test_name: str, test_code: str}"
```

First outputs:
```json
{"type": "function", "name": "add", "code": "def add(a, b): return a + b"}
```

Second receives that and outputs:
```json
{"test_name": "test_add", "test_code": "def test_add():\n    assert add(2, 3) == 5"}
```

## The "next_file" Pattern

The `next_file` field creates a self-directing workflow:

```python
prompt = """You are a code reviewer. 
For each file you review, output JSON: 
{
  file_reviewed: "current filename",
  issues_found: ["list", "of", "issues"],  
  next_file: "next file to review or null if done"
}
"""

# Claude might output:
{"file_reviewed": "app.py", "issues_found": ["Missing docstring"], "next_file": "models.py"}
{"file_reviewed": "models.py", "issues_found": [], "next_file": "views.py"}
{"file_reviewed": "views.py", "issues_found": ["Hardcoded URL"], "next_file": null}
```

This creates a self-contained workflow where Claude decides what to process next.

## Advanced Schema Patterns

### Nested Objects
```bash
claude -p 'Analyze code structure. Output JSON: {
  module: {name: str, imports: []}, 
  classes: [{name: str, methods: []}],
  issues: {critical: [], warnings: []}
}'
```

### Streaming Progress
```bash
claude -p 'Process large file. Output JSON lines:
First: {status: "starting", total_lines: int}
Then: {status: "progress", current_line: int, found: str}
Finally: {status: "complete", summary: str}'
```

### Decision Trees
```bash
claude -p 'Make decisions. Output JSON: {
  decision: "approve" | "reject" | "need_info",
  reason: str,
  if need_info: {questions: [str]},
  if approve: {next_step: str},
  if reject: {suggestions: [str]}
}'
```

## Why This Works So Well

1. **No Parsing Ambiguity** - Claude outputs valid JSON, not prose
2. **Type Safety** - You know exactly what fields to expect
3. **Machine Readable** - Direct `json.loads()` without regex
4. **Composable** - Output of one Claude feeds into another
5. **Self-Documenting** - The prompt shows the schema

## Real Example: Python Migration Assistant

```python
# Prompt that creates a code migration assistant
prompt = """You are a Python 2 to 3 migration assistant.
For each code snippet provided, output JSON:
{
  "original_line": "the Python 2 code",
  "migrated_line": "the Python 3 equivalent", 
  "changes": ["list of what changed"],
  "risk": "low" | "medium" | "high",
  "needs_manual_review": boolean,
  "explanation": "why this change is needed"
}
"""

# Feed it code
claude_proc = subprocess.Popen(['claude', '-p', prompt], ...)
claude_proc.stdin.write("print 'Hello World'\n")

# Claude outputs
{
  "original_line": "print 'Hello World'",
  "migrated_line": "print('Hello World')",
  "changes": ["print is now a function, requires parentheses"],
  "risk": "low",
  "needs_manual_review": false,
  "explanation": "Python 3 changed print from a statement to a function"
}
```

## Understanding Claude's Pattern Recognition

Claude understands type hints and placeholder patterns through contextual learning:
- `str` indicates a string value
- `int` indicates a numeric value  
- `[]` indicates an array
- `{}` indicates an object
- `'option1'|'option2'` indicates enum choices
- `...` indicates variable content

The beauty is that Claude understands the intent from the JSON structure in the prompt and maintains that format throughout its responses.