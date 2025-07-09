# PATTERN: The Fan-Out/Fan-In

> **Intent:** To process multiple pieces of data or a single piece of data from multiple perspectives concurrently, and then aggregate the individual results into a final, synthesized response.

---

## 1. Context & Motivation

Some problems are "embarrassingly parallel." For example, when analyzing a code change, one might want to assess its impact on security, performance, and documentation simultaneously. Running these analyses sequentially in an `Assembly Line` would be slow and inefficient, as they do not depend on each other.

Similarly, when processing a large volume of independent data (like summarizing 100 different articles), there is no reason to process them one by one.

**The Fan-Out/Fan-In** pattern addresses this by splitting a task into multiple independent sub-tasks that can be executed in parallel (**Fan-Out**), and then combines their outputs using a final "reducer" or "aggregator" agent (**Fan-In**). This mirrors the MapReduce paradigm from big data, adapted for LLM-based analysis and synthesis.

## 2. Applicability & Use Cases

This pattern is the premier solution for tasks that are either divisible into independent chunks or require multi-faceted analysis.

Use this pattern when:
-   You need to perform the same operation on many independent items (e.g., summarizing a list of articles).
-   You need to perform *different* analyses on the *same* item, and these analyses are not dependent on each other (e.g., security, performance, and style checks on a piece of code).
-   Throughput and reduced latency are critical, and the task can be parallelized.
-   You need a comprehensive, synthesized view derived from multiple, diverse perspectives.

**Examples:**
-   **Multi-Perspective Code Review (as described):** `Fan-Out:` A single code file is sent to three parallel LLM agents: `Security Specialist`, `Performance Specialist`, and `Style Linter`. `Fan-In:` Their individual reports (JSON) are passed to a final `Lead Reviewer` agent that synthesizes them into a single, prioritized review summary.
-   **Batch Data Processing:** `Fan-Out:` An array of 100 customer reviews is distributed among 10 parallel `Sentiment Analyzer` agents (10 reviews each). `Fan-In:` The 10 sets of sentiment scores are passed to a `Report Generator` agent that calculates aggregate statistics (e.g., overall satisfaction, common themes).
-   **Hypothesis Generation:** `Fan-Out:` A single problem statement is sent to multiple "persona" agents: `The Optimist`, `The Pessimist`, `The Pragmatist`, `The Innovator`. Each generates solutions from its unique perspective. `Fan-In:` Their diverse ideas are sent to a `Strategist` agent that identifies the most promising and robust options from the collected viewpoints.

## 3. Structure & Participants

**Diagram:**
```mermaid
graph TD
    subgraph Orchestrator
        InputData -- "1. Distribute Task" --> FanOut{Fan-Out Logic};
        
        subgraph Parallel Execution
            FanOut --> Worker1[Worker A: Specialist];
            FanOut --> Worker2[Worker B: Specialist];
            FanOut --> Worker3[Worker C: Specialist];
        end

        Worker1 -- "Result A" --> FanIn{Fan-In Logic / Reducer};
        Worker2 -- "Result B" --> FanIn;
        Worker3 -- "Result C" --> FanIn;
        
        FanIn -- "5. Synthesized Result" --> FinalResult;
    end
    
    LLM_Primitive
    Orchestrator -- "Calls LLM for all agents" --> LLM_Primitive

    classDef worker fill:#f9f,stroke:#333,stroke-width:2px;
    class Worker1, Worker2, Worker3 worker;
    classDef reducer fill:#9cf,stroke:#333,stroke-width:2px;
    class FanIn reducer;
```

**Participants:**
-   **The Orchestrator:** The main script or application. It is responsible for the `Fan-Out` logic (distributing the work) and the `Fan-In` logic (waiting for all parallel tasks to complete before calling the final reducer). This typically requires asynchronous programming (`async/await`, goroutines, or parallel shell execution).
-   **The Distributor (Fan-Out Logic):** Part of the Orchestrator that splits the initial data or task into chunks for the parallel workers.
-   **The Parallel Workers:** A set of independent LLM agents that run concurrently. They can be homogeneous (all using the same prompt on different data) or heterogeneous (using different specialist prompts on the same data).
-   **The Aggregator (Fan-In Logic / Reducer):** The final LLM agent in the pattern. Its role is to take the collected outputs from all parallel workers and synthesize them into a single, coherent result. Its prompt is designed specifically for summarization, aggregation, or prioritization.

## 4. Collaboration & Dynamics

The pattern operates in three distinct phases managed by the Orchestrator.

1.  **Phase 1: Fan-Out (Distribution)**
    -   The Orchestrator receives the initial data and task.
    -   The Distributor logic prepares the inputs for each parallel worker. This might involve splitting an array into sub-arrays or creating multiple copies of a single input file.
    -   The Orchestrator launches the LLM calls for all Parallel Workers *concurrently*, without waiting for any single one to finish.

2.  **Phase 2: Parallel Processing (Map)**
    -   Each Parallel Worker executes its specialized task on its given piece of data.
    -   The Orchestrator waits asynchronously for all workers to complete, collecting their individual results. Robust implementations will include timeouts to handle unresponsive workers.

3.  **Phase 3: Fan-In (Reduce)**
    -   Once all workers have returned their results, the Orchestrator assembles them into a single data structure (e.g., an array of JSON objects).
    -   The Orchestrator invokes the final **Aggregator** agent, passing it the complete collection of results. The Aggregator's prompt will be something like, "Given this array of expert analyses, produce a single, prioritized action plan."
    -   The output of the Aggregator is the final result of the entire pattern.

## 5. Consequences & Trade-offs

-   **Benefits:**
    -   `Massive Performance Gain:` For divisible or multi-faceted tasks, this pattern drastically reduces end-to-end latency compared to sequential processing.
    -   `Enhanced Quality through Diversity:` Using multiple specialist "personas" (like in the hypothesis generation example) can produce more creative, robust, and well-rounded insights than a single model could.
    -   `Scalability:` The pattern scales naturally. To process more data, one can simply add more parallel workers (up to the limits of the underlying LLM API rate limits and orchestrator hardware).

-   **Trade-offs / Risks:**
    -   `Implementation Complexity:` Requires asynchronous programming and state management for concurrent processes, which is significantly more complex than a simple sequential script.
    -   `Cost:` This pattern can be expensive, as it involves multiple simultaneous LLM calls. The cost scales linearly with the number of parallel workers.
    -   `Aggregator Bottleneck:` The entire process is only as good as the final `Aggregator` agent. If the Aggregator's prompt is not well-designed, it may fail to properly synthesize the rich inputs from the parallel workers, wasting the effort of the Fan-Out phase.
    -   `Rate Limiting:` Making many concurrent calls can easily hit API rate limits, requiring the orchestrator to include logic for throttling, backoff, and retries.

## 6. Reference Implementation

A shell-based implementation showcases the concept, using background processes for concurrency.

### Example Implementation

**`run_fanout.sh` (Orchestrator):**
```bash
#!/bin/bash
# Fan-Out/Fan-In Pattern - Multi-Perspective Code Review

# Validate input
if [ -z "$1" ] || [ ! -f "$1" ]; then
  echo "Usage: $0 <code_file>"
  exit 1
fi

CODE_FILE="$1"
PROMPT_DIR="prompts/code_review"
TEMP_DIR="$(mktemp -d)"

# Configuration
declare -A WORKERS=(
  ["security"]="Security vulnerabilities and best practices"
  ["performance"]="Performance optimization opportunities"
  ["style"]="Code style and readability"
  ["testing"]="Test coverage and quality"
)

echo "🚀 Starting Fan-Out/Fan-In code review for: $CODE_FILE"

# Phase 1: Fan-Out - Launch parallel workers
echo "📤 Fan-Out Phase: Launching ${#WORKERS[@]} specialist reviewers..."
PIDS=()

for worker in "${!WORKERS[@]}"; do
  echo "   → Starting $worker specialist..."
  
  # Each worker gets its specialized prompt
  (
    PROMPT="You are a ${worker} specialist reviewing code.
Focus ONLY on ${WORKERS[$worker]}.

Analyze the code and return a JSON report:
{
  \"aspect\": \"$worker\",
  \"findings\": [
    {
      \"severity\": \"critical|high|medium|low\",
      \"line\": line_number_or_range,
      \"issue\": \"description\",
      \"suggestion\": \"how to fix\"
    }
  ],
  \"overall_score\": 0-100,
  \"summary\": \"brief overall assessment\"
}

CODE TO REVIEW:
$(cat "$CODE_FILE")"

    echo "$PROMPT" | claude -p > "$TEMP_DIR/${worker}.json"
  ) &
  
  PIDS+=($!)
done

# Phase 2: Wait for all workers to complete
echo "⏳ Waiting for all specialists to complete their reviews..."
for pid in "${PIDS[@]}"; do
  wait "$pid"
done

# Validate worker outputs
echo "✅ All specialists have completed. Validating outputs..."
VALID_OUTPUTS=0
for worker in "${!WORKERS[@]}"; do
  if [ -f "$TEMP_DIR/${worker}.json" ] && jq . "$TEMP_DIR/${worker}.json" > /dev/null 2>&1; then
    ((VALID_OUTPUTS++))
  else
    echo "   ⚠️  Warning: $worker specialist produced invalid output"
  fi
done

echo "   → Valid outputs: $VALID_OUTPUTS/${#WORKERS[@]}"

# Phase 3: Fan-In - Aggregate results
echo "📥 Fan-In Phase: Synthesizing results with Lead Reviewer..."

# Prepare aggregated input for the reducer
AGGREGATED_INPUT=$(jq -n '
  {
    "code_file": $file,
    "reviews": [
      inputs
    ]
  }
' --arg file "$CODE_FILE" "$TEMP_DIR"/*.json)

# Lead Reviewer prompt
REDUCER_PROMPT="You are the Lead Code Reviewer synthesizing multiple specialist reviews.

Given the individual reviews from different specialists, create a comprehensive final review that:
1. Prioritizes the most critical issues across all aspects
2. Identifies patterns and relationships between different findings
3. Provides an overall assessment and action plan

Return a structured JSON report:
{
  \"file\": \"filename\",
  \"overall_health\": \"healthy|needs_attention|critical\",
  \"priority_issues\": [
    {
      \"severity\": \"critical|high|medium|low\",
      \"category\": \"security|performance|style|testing\",
      \"description\": \"issue description\",
      \"action_required\": \"specific action\"
    }
  ],
  \"metrics\": {
    \"security_score\": 0-100,
    \"performance_score\": 0-100,
    \"style_score\": 0-100,
    \"testing_score\": 0-100,
    \"overall_score\": 0-100
  },
  \"recommendation\": \"overall recommendation\",
  \"review_summary\": \"executive summary\"
}

SPECIALIST REVIEWS:
$AGGREGATED_INPUT"

FINAL_REVIEW=$(echo "$REDUCER_PROMPT" | claude -p)

# Output results
echo -e "\n🎯 FINAL SYNTHESIZED CODE REVIEW"
echo "================================="
echo "$FINAL_REVIEW" | jq '.'

# Cleanup
rm -rf "$TEMP_DIR"
```

### Advanced Fan-Out/Fan-In Patterns

**1. Dynamic Worker Allocation:**
```bash
# Distribute work based on data size
distribute_work() {
  local items=("$@")
  local num_workers=$((${#items[@]} / 10 + 1))  # 10 items per worker
  local worker_id=0
  
  for item in "${items[@]}"; do
    worker_dir="$TEMP_DIR/worker_$((worker_id % num_workers))"
    mkdir -p "$worker_dir"
    echo "$item" >> "$worker_dir/items.txt"
    ((worker_id++))
  done
  
  echo "$num_workers"
}
```

**2. Heterogeneous Workers with Different Prompts:**
```bash
# Different analysis perspectives
declare -A PERSPECTIVES=(
  ["optimist"]="Find all the positive aspects and potential"
  ["pessimist"]="Identify all risks and potential failures"
  ["pragmatist"]="Focus on practical implementation challenges"
  ["innovator"]="Suggest creative improvements and alternatives"
)

for perspective in "${!PERSPECTIVES[@]}"; do
  analyze_with_perspective "$perspective" "${PERSPECTIVES[$perspective]}" &
done
```

**3. Hierarchical Fan-Out/Fan-In:**
```bash
# Two-level fan-out for large datasets
# Level 1: Distribute to regional processors
for region in "north" "south" "east" "west"; do
  (
    # Level 2: Each region fans out to cities
    for city in $(get_cities "$region"); do
      process_city_data "$city" &
    done
    wait
    
    # Regional aggregation
    aggregate_region "$region"
  ) &
done
wait

# Global aggregation
aggregate_global
```

**4. Fallback for Failed Workers:**
```bash
# Track and retry failed workers
process_with_retry() {
  local worker_id=$1
  local max_retries=3
  local retry=0
  
  while [ $retry -lt $max_retries ]; do
    if run_worker "$worker_id"; then
      return 0
    fi
    ((retry++))
    sleep $((2 ** retry))  # Exponential backoff
  done
  
  # Use fallback if all retries fail
  echo "{\"worker\": \"$worker_id\", \"status\": \"failed\", \"fallback\": true}" > "$TEMP_DIR/${worker_id}.json"
}
```

### Composing with Other Patterns

The Fan-Out/Fan-In pattern combines powerfully with other patterns:

```bash
# Fan-Out + Router: Different workers based on data type
classify_and_process() {
  local item=$1
  local type=$(echo "$item" | ./router.sh)
  
  case "$type" in
    "text") process_text "$item" ;;
    "code") process_code "$item" ;;
    "data") process_data "$item" ;;
  esac
}

# Fan-Out + Circuit Breaker: Protected parallel execution
for worker in "${WORKERS[@]}"; do
  (
    ./circuit_breaker.sh "$worker" "$PROMPT" "$DATA" > "$TEMP_DIR/${worker}.json"
  ) &
done
```

The Fan-Out/Fan-In pattern enables efficient parallel processing and multi-perspective analysis, transforming how we approach complex LLM orchestration tasks that benefit from concurrent execution.