# Multi-Line Input and Session Management Patterns

## Overview

Session management patterns enable maintaining context across multiple Claude invocations, while multi-line input patterns handle complex inputs effectively.

## Session Management

### Basic Session Pattern

```bash
# Create session ID for context preservation
SESSION_ID=$(uuidgen)

# Use session ID in all related calls
claude -p "Session: $SESSION_ID. Remember previous context. Task: analyze codebase"
claude -p "Session: $SESSION_ID. Based on previous analysis, suggest improvements"
claude -p "Session: $SESSION_ID. Generate implementation for suggestion #2"
```

### Session-Based Workflows

```python
class ClaudeSession:
    def __init__(self):
        self.session_id = str(uuid.uuid4())
        self.context = []
        
    async def send(self, message):
        # Include session context
        prompt = f"""
        Session ID: {self.session_id}
        Previous context: {json.dumps(self.context[-3:])}  # Last 3 interactions
        
        Current request: {message}
        """
        
        result = await Claude(prompt).process(message)
        
        # Update context
        self.context.append({
            "timestamp": time.time(),
            "request": message,
            "response": result
        })
        
        return result

# Usage
session = ClaudeSession()
analysis = await session.send("Analyze this codebase for security issues")
details = await session.send("Elaborate on issue #3")
fix = await session.send("Generate a fix for that issue")
```

### Persistent Session Storage

```bash
# Session management with file storage
SESSION_DIR="/tmp/claude_sessions"
mkdir -p "$SESSION_DIR"

start_session() {
    local session_id=$(uuidgen)
    local session_file="$SESSION_DIR/$session_id.json"
    
    # Initialize session
    echo '{"id": "'$session_id'", "created": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'", "messages": []}' > "$session_file"
    
    echo "$session_id"
}

add_to_session() {
    local session_id=$1
    local role=$2
    local content=$3
    local session_file="$SESSION_DIR/$session_id.json"
    
    # Add message to session
    jq --arg role "$role" --arg content "$content" \
        '.messages += [{"role": $role, "content": $content, "timestamp": now}]' \
        "$session_file" > "$session_file.tmp" && mv "$session_file.tmp" "$session_file"
}

claude_with_session() {
    local session_id=$1
    local prompt=$2
    local session_file="$SESSION_DIR/$session_id.json"
    
    # Get session context
    context=$(jq -r '.messages[-5:] | map(.role + ": " + .content) | join("\n")' "$session_file")
    
    # Call Claude with context
    response=$(claude -p "Session context:
$context

Current request: $prompt")
    
    # Store interaction
    add_to_session "$session_id" "user" "$prompt"
    add_to_session "$session_id" "assistant" "$response"
    
    echo "$response"
}
```

## Multi-Line Input Patterns

### Here Documents

```bash
# Basic here document
claude -p "Analyze this code" << 'EOF'
def complex_function(data):
    # Multiple lines of code
    result = []
    for item in data:
        if validate(item):
            result.append(process(item))
    return result
EOF

# Here document with variable expansion
NAME="MyClass"
claude -p "Generate tests for class" << EOF
class $NAME:
    def __init__(self):
        self.value = 0
    
    def increment(self):
        self.value += 1
EOF

# Here document without variable expansion (note the quotes)
claude -p "Analyze this template" << 'EOF'
Template with $VARIABLE that should not expand
${ANOTHER_VAR} stays literal
EOF
```

### Command Substitution

```bash
# Using command substitution for multi-line
claude -p "Review this function" "$(cat << 'EOF'
function processData() {
    const results = [];
    for (const item of data) {
        if (isValid(item)) {
            results.push(transform(item));
        }
    }
    return results;
}
EOF
)"

# Reading from multiple files
claude -p "Compare these implementations" \
    "File 1: $(cat implementation1.py)" \
    "File 2: $(cat implementation2.py)"
```

### Handling Multiple Files

```bash
# Process multiple files with context
analyze_project() {
    local session_id=$(uuidgen)
    
    # First, get project overview
    find . -name "*.py" -type f | \
    claude -p "Session: $session_id. List files to analyze. Output JSON: {files: [], order: []}"
    
    # Then analyze each file with context
    for file in $(find . -name "*.py" -type f); do
        claude -p "Session: $session_id. Analyzing $file" < "$file"
    done
    
    # Finally, summarize findings
    claude -p "Session: $session_id. Summarize all findings"
}
```

## Windows/WSL Specific Patterns

### Handling Windows Line Endings

```bash
# Convert Windows line endings before processing
dos2unix input.txt | claude -p "Process this text"

# Or handle in-line
claude -p "Process this text" < <(tr -d '\r' < windows_file.txt)
```

### PowerShell Integration

```powershell
# PowerShell heredoc equivalent
$code = @"
function Get-ProcessInfo {
    param([string]$ProcessName)
    Get-Process $ProcessName | Select-Object Name, CPU, Memory
}
"@

# Send to Claude
$code | claude -p "Convert to Python"

# Multi-line with session
$sessionId = [System.Guid]::NewGuid().ToString()
$context = @()

function Invoke-ClaudeWithSession {
    param(
        [string]$Prompt,
        [string]$SessionId
    )
    
    $fullPrompt = "Session: $SessionId`nContext: $($global:context -join "`n")`n`nRequest: $Prompt"
    $response = $fullPrompt | claude -p
    $global:context += "User: $Prompt`nAssistant: $response"
    return $response
}
```

## Advanced Session Patterns

### Branching Sessions

```python
class BranchingSession:
    """Support for exploring multiple paths from a point"""
    
    def __init__(self):
        self.main_session = []
        self.branches = {}
        self.current_branch = "main"
    
    def branch(self, branch_name):
        """Create a new branch from current point"""
        if self.current_branch == "main":
            self.branches[branch_name] = self.main_session.copy()
        else:
            self.branches[branch_name] = self.branches[self.current_branch].copy()
        self.current_branch = branch_name
    
    def merge(self, branch_name, strategy="concat"):
        """Merge branch back to main"""
        if strategy == "concat":
            self.main_session.extend(self.branches[branch_name])
        elif strategy == "replace":
            self.main_session = self.branches[branch_name]
        elif strategy == "smart":
            # Use Claude to merge
            merger = Claude("Merge these conversation branches intelligently")
            self.main_session = merger.process({
                "main": self.main_session,
                "branch": self.branches[branch_name]
            })
```

### Windowed Context

```python
class WindowedSession:
    """Maintain sliding window of context"""
    
    def __init__(self, window_size=10):
        self.window_size = window_size
        self.full_history = []
        self.summary = ""
    
    async def send(self, message):
        # When window is full, summarize older content
        if len(self.full_history) >= self.window_size:
            # Get Claude to summarize what's being removed
            to_summarize = self.full_history[:-self.window_size//2]
            summarizer = Claude("Summarize this conversation segment concisely")
            self.summary = await summarizer.process(to_summarize)
            
            # Keep recent half
            self.full_history = self.full_history[-self.window_size//2:]
        
        # Build context with summary + recent
        context = f"Previous summary: {self.summary}\n"
        context += "Recent messages:\n"
        context += "\n".join(self.full_history)
        
        result = await Claude(f"{context}\n\nCurrent: {message}").process()
        
        self.full_history.append(f"User: {message}\nAssistant: {result}")
        return result
```

### Checkpoint and Restore

```bash
# Save session checkpoint
save_checkpoint() {
    local session_id=$1
    local checkpoint_name=$2
    local session_file="$SESSION_DIR/$session_id.json"
    local checkpoint_file="$SESSION_DIR/${session_id}_checkpoint_${checkpoint_name}.json"
    
    cp "$session_file" "$checkpoint_file"
    echo "Checkpoint '$checkpoint_name' saved"
}

# Restore from checkpoint
restore_checkpoint() {
    local session_id=$1
    local checkpoint_name=$2
    local session_file="$SESSION_DIR/$session_id.json"
    local checkpoint_file="$SESSION_DIR/${session_id}_checkpoint_${checkpoint_name}.json"
    
    if [ -f "$checkpoint_file" ]; then
        cp "$checkpoint_file" "$session_file"
        echo "Restored from checkpoint '$checkpoint_name'"
    else
        echo "Checkpoint not found"
        return 1
    fi
}

# Usage example
SESSION=$(start_session)
claude_with_session "$SESSION" "Start analyzing the codebase"
save_checkpoint "$SESSION" "after_analysis"
claude_with_session "$SESSION" "Try risky refactoring"
# If something goes wrong...
restore_checkpoint "$SESSION" "after_analysis"
```

## Multi-Line Input Best Practices

### 1. Quote Properly

```bash
# Single quotes prevent variable expansion
claude -p 'Analyze $VARIABLE as literal text' << 'EOF'
This $VARIABLE won't expand
EOF

# Double quotes allow expansion
USER="Alice"
claude -p "Generate message for $USER" << EOF
Hello $USER, welcome!
EOF
```

### 2. Handle Special Characters

```bash
# Escape special characters
claude -p "Parse this regex" << 'EOF'
^(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@
EOF

# Or use command substitution with printf
claude -p "Analyze" "$(printf '%s\n' 'Line with "quotes"' "Line with 'apostrophes'" 'Line with $special chars')"
```

### 3. Process Large Inputs

```bash
# For very large inputs, use temporary files
large_input_handler() {
    local temp_file=$(mktemp)
    
    # Write large content to temp file
    generate_large_content > "$temp_file"
    
    # Process in chunks if needed
    split -l 1000 "$temp_file" "$temp_file.chunk."
    
    for chunk in "$temp_file.chunk."*; do
        claude -p "Process chunk" < "$chunk"
    done
    
    # Cleanup
    rm -f "$temp_file" "$temp_file.chunk."*
}
```

### 4. Interactive Multi-Line Collection

```bash
# Collect multi-line input interactively
collect_multiline() {
    local prompt=$1
    local content=""
    
    echo "$prompt (end with '###' on its own line):"
    while IFS= read -r line; do
        if [ "$line" = "###" ]; then
            break
        fi
        content="${content}${line}\n"
    done
    
    echo -e "$content" | claude -p "Process this input"
}
```

## Session Pattern Examples

### Code Review Session

```bash
# Multi-stage code review with persistent context
review_session() {
    local pr_number=$1
    local session_id="review_pr_${pr_number}_$(date +%s)"
    
    # Stage 1: Overview
    gh pr view $pr_number | \
    claude_with_session "$session_id" "Summarize this PR's changes and intent"
    
    # Stage 2: File-by-file review
    for file in $(gh pr diff $pr_number --name-only); do
        gh pr diff $pr_number -- "$file" | \
        claude_with_session "$session_id" "Review changes in $file"
    done
    
    # Stage 3: Overall assessment
    claude_with_session "$session_id" "Provide overall PR assessment and recommendations"
}
```

### Learning Session

```python
class LearningSesssion:
    """Adaptive learning session that adjusts to user level"""
    
    def __init__(self, topic):
        self.topic = topic
        self.session_id = str(uuid.uuid4())
        self.skill_level = "unknown"
        self.covered_concepts = []
        
    async def interact(self, user_input):
        prompt = f"""
        Learning session: {self.session_id}
        Topic: {self.topic}
        User skill level: {self.skill_level}
        Covered concepts: {self.covered_concepts}
        
        User says: {user_input}
        
        Respond appropriately and output JSON:
        {{
            "response": "your teaching response",
            "skill_level_assessment": "beginner|intermediate|advanced",
            "new_concepts_introduced": [],
            "should_quiz": bool,
            "quiz_question": "question if should_quiz"
        }}
        """
        
        result = await Claude(prompt).process()
        
        # Update session state
        self.skill_level = result['skill_level_assessment']
        self.covered_concepts.extend(result['new_concepts_introduced'])
        
        return result
```

## Best Practices

1. **Session ID Format** - Use meaningful, unique IDs (UUIDs or timestamp-based)
2. **Context Limits** - Don't send entire history; use summaries for long sessions
3. **State Persistence** - Save session state for recovery and analysis
4. **Clean Up** - Remove old session files to prevent disk bloat
5. **Error Recovery** - Handle session corruption gracefully
6. **Privacy** - Be mindful of sensitive data in session storage
7. **Atomic Updates** - Use temporary files when updating session state
8. **Compression** - Compress old sessions if keeping for analysis
9. **Branching** - Support exploring multiple paths from a decision point
10. **Migration** - Plan for session format evolution