# Stream Processing Patterns

## Overview

Stream processing patterns enable continuous data flow through Claude instances, allowing for real-time analysis and transformation of data streams.

## Basic Stream Processing

### Piping Data to Claude

```bash
# Process each line independently
cat data.txt | claude -p "Process each line independently"

# Reading from standard input
claude -p "Count occurrences" < input.log

# Reading from a file directly
claude -p "Analyze this code" input.py

# Multiple files
claude -p "Compare these files" file1.py file2.py
```

### Interactive/REPL Modes

```bash
# Interactive mode (if supported)
claude -i -p "Act as Python REPL. >>> prompt"

# Using a while loop to maintain state
while true; do
    read input
    echo "$input" | claude -p "Maintain state. Counter mode"
done
```

## Continuous Processing Patterns

### Named Pipes for Ongoing Streams

```bash
# Create a named pipe
mkfifo /tmp/claude_pipe

# Claude reads from pipe continuously
claude -p "Monitor for errors" < /tmp/claude_pipe &

# Feed data to the pipe
tail -f app.log > /tmp/claude_pipe
```

### Process Substitution

```bash
# Compare outputs from two different sources
claude -p "Compare these outputs" <(git log --oneline) <(git log --oneline origin/main)

# Real-time diff analysis
claude -p "Explain differences" <(ps aux) <(sleep 5; ps aux)
```

### Handling Multiple Streams

```bash
# Create multiple named pipes
mkfifo /tmp/errors /tmp/warnings /tmp/info

# Multiple Claudes monitoring different severity levels
claude -p "Analyze errors. Output JSON: {error: str, fix: str}" < /tmp/errors &
claude -p "Summarize warnings" < /tmp/warnings &
claude -p "Extract metrics from info" < /tmp/info &

# Router script that splits log by severity
tail -f app.log | while read line; do
    if [[ "$line" =~ ERROR ]]; then
        echo "$line" > /tmp/errors
    elif [[ "$line" =~ WARN ]]; then
        echo "$line" > /tmp/warnings
    else
        echo "$line" > /tmp/info
    fi
done
```

## Real-Time Monitoring Patterns

### Log Analysis Pipeline

```bash
# Continuous log monitoring with structured output
tail -f system.log | \
claude -p "Extract events. Output JSON: {timestamp: str, event: str, severity: str}" | \
jq -r 'select(.severity == "critical")' | \
claude -p "Generate alert. Output JSON: {message: str, action: str}"
```

### Performance Monitoring

```bash
# Monitor system metrics continuously
while true; do
    echo "$(date),$(uptime),$(free -m | grep Mem)" | \
    claude -p "Analyze metrics. Output JSON: {cpu_state: str, memory_pressure: str, alert: bool}"
    sleep 60
done | tee metrics.jsonl
```

## Advanced Stream Patterns

### Stream Splitting and Joining

```bash
# Split stream to multiple Claude instances
cat large_file.txt | tee \
    >(claude -p "Extract functions" > functions.json) \
    >(claude -p "Find security issues" > security.json) \
    >(claude -p "Generate documentation" > docs.md) \
    > /dev/null

# Wait for all to complete
wait

# Merge results
claude -p "Merge analysis results" functions.json security.json docs.md
```

### Buffered Processing

```bash
# Process in batches of 100 lines
cat huge_log.txt | \
while IFS= read -r line; do
    echo "$line"
    ((count++))
    if ((count % 100 == 0)); then
        echo "---BATCH---"
    fi
done | \
claude -p "Process log batches. On '---BATCH---', output summary JSON"
```

### Stateful Stream Processing

```bash
# Claude maintains state across stream
export SESSION_ID=$(uuidgen)

cat events.stream | while IFS= read -r event; do
    echo "$event" | claude -p "
        Session: $SESSION_ID
        Maintain event count and patterns.
        Output JSON: {event_count: int, patterns_detected: [], anomaly: bool}
    "
done
```

## Stream Control Patterns

### Conditional Processing

```bash
# Only process lines that match criteria
tail -f app.log | \
grep -E "(ERROR|CRITICAL)" | \
claude -p "Analyze errors. Output JSON: {error: str, root_cause: str, fix: str}"
```

### Rate-Limited Processing

```bash
# Process max 10 lines per second
tail -f high_volume.log | \
while IFS= read -r line; do
    echo "$line"
    sleep 0.1
done | \
claude -p "Analyze at sustainable rate"
```

### Circuit Breaker Pattern

```bash
# Stop processing if too many errors
error_count=0
max_errors=5

tail -f app.log | while IFS= read -r line; do
    result=$(echo "$line" | claude -p "Detect issues. Output JSON: {has_error: bool}")
    
    if [[ $(echo "$result" | jq -r '.has_error') == "true" ]]; then
        ((error_count++))
        if ((error_count >= max_errors)); then
            echo "Circuit breaker triggered!"
            break
        fi
    else
        error_count=0  # Reset on success
    fi
    
    echo "$result"
done
```

## Multi-Line Stream Handling

### Using Here Documents

```bash
# Send multi-line content
claude -p "Analyze this configuration" << 'EOF'
server {
    listen 80;
    server_name example.com;
    location / {
        proxy_pass http://localhost:3000;
    }
}
EOF
```

### Command Substitution for Multi-Line

```bash
# Analyze entire function
claude -p "Review this function" "$(cat << 'EOF'
def process_data(input_list):
    result = []
    for item in input_list:
        if validate(item):
            result.append(transform(item))
    return result
EOF
)"
```

## Stream Transformation Patterns

### Format Conversion Pipeline

```bash
# CSV to JSON pipeline
cat data.csv | \
claude -p "Convert CSV to JSON. Output JSON array" | \
jq '.[] | select(.value > 100)' | \
claude -p "Generate SQL inserts"
```

### Progressive Enhancement

```bash
# Each Claude adds information
echo "function.py:calculate_total" | \
claude -p "Extract function code" | \
claude -p "Add type hints. Output JSON: {code: str, types: []}" | \
claude -p "Generate unit tests based on types" | \
claude -p "Create documentation from code and tests"
```

## Best Practices

1. **Use JSON for structured data flow** - Makes parsing between stages reliable
2. **Include session IDs for stateful processing** - Maintains context across invocations
3. **Handle errors gracefully** - Streams can fail; plan for recovery
4. **Monitor resource usage** - Long-running streams can accumulate memory
5. **Use named pipes for complex flows** - More control than simple pipes
6. **Buffer when needed** - Batch processing can be more efficient
7. **Rate limit high-volume streams** - Prevent overwhelming Claude or system

## Common Pitfalls

1. **Buffering issues** - Large outputs may buffer unexpectedly
2. **Broken pipes** - Handle SIGPIPE when consumers terminate
3. **State loss** - Without session IDs, each invocation is independent
4. **Resource leaks** - Clean up named pipes and background processes
5. **Order dependencies** - Parallel processing may complete out of order