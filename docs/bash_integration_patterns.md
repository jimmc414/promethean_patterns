# Bash Integration Patterns

## Overview

Bash integration patterns show advanced techniques for combining Claude with shell scripting, creating powerful automation workflows.

## Bash Operators Quick Reference

### Pipe and Redirect Operators

```bash
# | - Pipe output to next command
cat file.txt | claude -p "Summarize"

# > - Redirect output (overwrite)
claude -p "Generate code" > output.py

# >> - Redirect output (append)
claude -p "Add comments" >> output.py

# < - Redirect input
claude -p "Analyze" < input.txt

# << - Here document
claude -p "Process" << EOF
Multi-line
input
EOF

# <<< - Here string
claude -p "Process" <<< "Single line input"

# 2>&1 - Redirect stderr to stdout
claude -p "Debug" 2>&1 | tee debug.log

# &> - Redirect both stdout and stderr
claude -p "Full output" &> complete.log
```

### Process Substitution

```bash
# <() - Process substitution (input)
claude -p "Compare files" <(ls -la) <(ls -la /tmp)

# >() - Process substitution (output)
claude -p "Generate two outputs" | tee >(grep ERROR > errors.log) >(grep WARN > warnings.log)

# Command substitution
claude -p "Analyze: $(git status)"
claude -p "Process: `date`"  # Backticks (older style)
```

### Conditional Execution

```bash
# && - Execute if previous succeeded
claude -p "Test code" && echo "Tests passed"

# || - Execute if previous failed
claude -p "Validate" || exit 1

# ; - Execute regardless
claude -p "Try this"; echo "Done"

# & - Run in background
claude -p "Long analysis" & pid=$!

# | - Pipeline continues even if command fails
set -o pipefail  # Make pipeline fail if any command fails
```

## Advanced Pipeline Patterns

### Stream Splitting

```bash
# Split stream to multiple processes
cat large_file.txt | tee \
    >(claude -p "Extract functions" > functions.txt) \
    >(claude -p "Find bugs" > bugs.txt) \
    >(claude -p "Generate docs" > docs.txt) \
    >/dev/null

# Process different parts of stream differently
tail -f app.log | while read line; do
    echo "$line" | grep ERROR && echo "$line" | claude -p "Analyze error"
    echo "$line" | grep METRIC && echo "$line" | claude -p "Process metric"
done
```

### Parallel Processing

```bash
# GNU Parallel with Claude
find . -name "*.py" | parallel -j 4 'claude -p "Analyze file" < {}'

# Xargs parallel execution
find . -name "*.js" -print0 | xargs -0 -P 4 -I {} bash -c 'claude -p "Review" < "{}"'

# Background jobs with job control
for file in *.txt; do
    claude -p "Process $file" < "$file" > "${file%.txt}.json" &
    # Limit concurrent jobs
    while [ $(jobs -r | wc -l) -ge 4 ]; do
        sleep 0.1
    done
done
wait  # Wait for all background jobs
```

### Error Handling in Pipelines

```bash
# Capture exit codes in pipeline
set -o pipefail

# Error handling function
handle_pipeline_error() {
    local exit_codes=("${PIPESTATUS[@]}")
    local cmd_index=0
    
    for exit_code in "${exit_codes[@]}"; do
        if [ $exit_code -ne 0 ]; then
            echo "Command $cmd_index failed with exit code $exit_code" | \
            claude -p "Diagnose pipeline failure"
        fi
        ((cmd_index++))
    done
}

# Use it
cat file.txt | grep pattern | claude -p "Process" | jq '.result'
handle_pipeline_error
```

## Parameter Expansion Patterns

### Advanced Variable Manipulation

```bash
# Default values
claude -p "Analyze ${FILE:-default.txt}"

# Substring extraction
filename="/path/to/file.txt"
claude -p "Process ${filename##*/}"  # file.txt (basename)
claude -p "Check ${filename%/*}"     # /path/to (dirname)

# Pattern replacement
text="foo_bar_baz"
claude -p "Convert ${text//_/ }"     # foo bar baz

# Length
claude -p "Text of length ${#text}"

# Arrays
files=(*.py)
claude -p "Analyze ${files[@]}"      # All files
claude -p "First file: ${files[0]}"  # First file
claude -p "Count: ${#files[@]}"      # Number of files
```

### Safe Variable Handling

```bash
# Quote array expansions
files=("file with spaces.txt" "another file.txt")
for file in "${files[@]}"; do
    claude -p "Process file" < "$file"
done

# Handle filenames with special characters
find . -name "*.txt" -print0 | while IFS= read -r -d '' file; do
    claude -p "Safe processing" < "$file"
done

# Escape for use in prompts
user_input="$1"
escaped_input=${user_input//\"/\\\"}
claude -p "User said: \"$escaped_input\""
```

## Shell Function Patterns

### Claude Wrapper Functions

```bash
# Intelligent file analyzer
analyze_file() {
    local file="$1"
    local file_type=$(file -b "$file")
    
    case "$file_type" in
        *"Python script"*)
            claude -p "Analyze Python code for bugs and style" < "$file"
            ;;
        *"Bourne-Again shell"*)
            claude -p "Review bash script for best practices" < "$file"
            ;;
        *"JSON"*)
            claude -p "Validate and summarize JSON structure" < "$file"
            ;;
        *)
            claude -p "Analyze file content and structure" < "$file"
            ;;
    esac
}

# Recursive directory analyzer
analyze_directory() {
    local dir="${1:-.}"
    local max_depth="${2:-3}"
    
    find "$dir" -maxdepth "$max_depth" -type f | while read -r file; do
        echo "Analyzing: $file"
        analyze_file "$file"
    done | claude -p "Summarize all analyses"
}
```

### Conversation Functions

```bash
# Contextual conversation function
claude_chat() {
    local context_file="/tmp/claude_context_$$"
    touch "$context_file"
    
    while true; do
        read -p "You: " user_input
        [ "$user_input" = "exit" ] && break
        
        # Build context
        {
            tail -n 20 "$context_file"  # Last 10 exchanges
            echo "User: $user_input"
        } | claude -p "Continue conversation naturally" | tee -a "$context_file"
        
        echo  # New line for readability
    done
    
    rm -f "$context_file"
}

# Topic-focused assistant
claude_expert() {
    local expertise="$1"
    shift  # Remove first argument
    
    local system_prompt="You are an expert in $expertise. Answer concisely and accurately."
    echo "$*" | claude -p "$system_prompt"
}

# Usage
claude_expert "Python optimization" "How do I improve this loop performance?"
claude_expert "SQL" "Convert this query to use window functions"
```

## Integration with Unix Tools

### Combining with Standard Tools

```bash
# With grep and sed
git log --oneline | 
    grep -E "fix|bug" | 
    sed 's/^[a-f0-9]\+ //' |
    claude -p "Categorize these bug fixes"

# With awk and sort
ps aux | 
    awk '{print $2, $3, $11}' | 
    sort -k2 -n -r | 
    head -20 |
    claude -p "Analyze top CPU consuming processes"

# With find and stat
find . -name "*.py" -exec stat -c "%Y %n" {} \; |
    sort -n -r |
    head -10 |
    claude -p "Why might these Python files have been recently modified?"
```

### Git Integration

```bash
# Pre-commit hook with Claude
#!/bin/bash
# .git/hooks/pre-commit

# Check for common issues
git diff --cached --name-only | while read -r file; do
    if [[ "$file" =~ \.py$ ]]; then
        git diff --cached "$file" | 
        claude -p "Check for bugs, security issues, or bad practices. Output JSON: {issues: [], severity: 'low|medium|high'}" |
        jq -e '.severity == "high"' && {
            echo "High severity issues found in $file"
            exit 1
        }
    fi
done

# Generate commit message suggestion
git diff --cached | 
claude -p "Suggest a conventional commit message for these changes" |
tee /tmp/commit_message_suggestion.txt
```

### System Monitoring

```bash
# Intelligent log monitor
monitor_logs() {
    local log_file="$1"
    local analysis_interval=60
    local last_analysis=$(date +%s)
    
    tail -f "$log_file" | while read -r line; do
        echo "$line" >> /tmp/log_buffer_$$
        
        current_time=$(date +%s)
        if (( current_time - last_analysis >= analysis_interval )); then
            # Analyze accumulated logs
            claude -p "Analyze these logs for anomalies, patterns, or issues" < /tmp/log_buffer_$$ |
            while read -r alert; do
                notify-send "Log Alert" "$alert"
            done
            
            > /tmp/log_buffer_$$  # Clear buffer
            last_analysis=$current_time
        fi
    done
}

# Resource usage analyzer
analyze_resources() {
    {
        echo "=== CPU ==="
        mpstat 1 1
        echo "=== Memory ==="
        free -h
        echo "=== Disk ==="
        df -h
        echo "=== Network ==="
        ss -s
    } | claude -p "Analyze system resources and suggest optimizations"
}
```

## Advanced Patterns

### Dynamic Script Generation

```bash
# Claude generates and executes scripts
claude_execute() {
    local task="$1"
    local script_file="/tmp/claude_script_$$.sh"
    
    # Generate script
    claude -p "Generate a bash script to: $task. Output only the script, no explanation." > "$script_file"
    
    # Review script (optional)
    echo "Generated script:"
    cat "$script_file"
    read -p "Execute? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chmod +x "$script_file"
        bash "$script_file"
        local exit_code=$?
        
        if [ $exit_code -ne 0 ]; then
            # Debug failed script
            claude -p "Debug why this script failed with exit code $exit_code" < "$script_file"
        fi
    fi
    
    rm -f "$script_file"
}
```

### Pipeline Debugging

```bash
# Debug complex pipelines
debug_pipeline() {
    set -o pipefail
    
    # Create named pipes for debugging
    mkfifo /tmp/pipe_debug_{1,2,3}
    
    # Run pipeline with tee to debug pipes
    cat input.txt |
        tee /tmp/pipe_debug_1 |
        grep "pattern" |
        tee /tmp/pipe_debug_2 |
        claude -p "Process" |
        tee /tmp/pipe_debug_3 |
        jq '.result'
    
    # Analyze each stage
    for i in 1 2 3; do
        echo "=== Stage $i ===" | claude -p "What happened at this pipeline stage?" < /tmp/pipe_debug_$i
    done
    
    # Cleanup
    rm -f /tmp/pipe_debug_{1,2,3}
}
```

### Adaptive Automation

```bash
# Self-improving automation
adaptive_automation() {
    local task="$1"
    local performance_log="/tmp/automation_performance.log"
    
    while true; do
        # Get current approach
        approach=$(claude -p "Based on this performance history, how should we approach: $task" < "$performance_log")
        
        # Execute approach
        start_time=$(date +%s)
        eval "$approach"
        exit_code=$?
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        # Log performance
        echo "$(date -Iseconds) | Duration: ${duration}s | Exit: $exit_code | Approach: $approach" >> "$performance_log"
        
        # Learn from results
        if [ $exit_code -ne 0 ] || [ $duration -gt 60 ]; then
            claude -p "This approach failed or was slow. Suggest improvements." \
                <<< "Task: $task | Approach: $approach | Duration: ${duration}s | Exit: $exit_code"
        fi
        
        sleep 3600  # Run hourly
    done
}
```

## Best Practices

1. **Use `set -euo pipefail`** - Fail fast on errors
2. **Quote variables** - Always quote to handle spaces: `"$var"`
3. **Check exit codes** - Don't assume commands succeed
4. **Use mktemp for temp files** - Avoid collisions: `$(mktemp)`
5. **Trap for cleanup** - Clean up resources on exit
6. **Prefer `[[ ]]` over `[ ]`** - More features, fewer surprises
7. **Use process substitution** - Avoid temporary files when possible
8. **Handle signals** - Graceful shutdown with trap
9. **Log actions** - Debugging is easier with good logs
10. **Test with shellcheck** - Catch common mistakes

## Common Pitfalls

### Word Splitting
```bash
# Bad: Unquoted variable
files=$(ls *.txt)
for file in $files; do  # Breaks on spaces

# Good: Use array or quote
files=(*.txt)
for file in "${files[@]}"; do
```

### Exit Code Masking
```bash
# Bad: Exit code lost
result=$(command_that_might_fail)

# Good: Check exit code
if result=$(command_that_might_fail); then
    echo "Success: $result"
else
    echo "Failed"
fi
```

### Pipe Buffering
```bash
# Bad: Buffering delays output
tail -f log | grep ERROR | claude -p "Analyze"

# Good: Disable buffering
tail -f log | grep --line-buffered ERROR | claude -p "Analyze"
```