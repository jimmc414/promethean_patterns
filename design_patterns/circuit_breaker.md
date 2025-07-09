# PATTERN: The Circuit Breaker

> **Intent:** To prevent cascading failures in an LLM-driven system by automatically detecting repeated errors from a specific LLM agent, temporarily halting calls to it, and providing a safe fallback mechanism.

---

## 1. Context & Motivation

LLM-based systems can fail in ways traditional deterministic systems cannot. An LLM agent might repeatedly return malformed JSON, enter a repetitive loop, or provide low-quality, "hallucinated" responses. Continuously re-trying a failing agent can be costly, can increase system latency, and can lead to a cascade of errors that brings down the entire application.

In electrical engineering, a circuit breaker automatically trips to stop the flow of current when it detects a fault, protecting the downstream components. The Circuit Breaker pattern applies this same concept to LLM orchestration.

This pattern introduces a "stateful wrapper" around an LLM agent. This wrapper monitors the health of the agent's calls. If the failure rate for a specific agent exceeds a set threshold, the breaker "trips" or "opens." While the circuit is open, all subsequent calls to that agent are immediately rerouted to a safe, fast fallback without hitting the LLM API. After a cooldown period, the breaker moves to a "half-open" state, allowing a single trial call to test if the underlying issue is resolved.

## 2. Applicability & Use Cases

This pattern is a crucial safeguard for any production-grade system that relies on LLM calls, especially those that are high-volume or business-critical.

Use this pattern when:
-   An LLM agent is mission-critical, and its failure should not crash the entire application.
-   You want to prevent runaway costs from an LLM agent that is stuck in a retry loop.
-   The system can provide a reasonable (even if degraded) fallback experience when an LLM agent is unavailable.
-   You need to build a system that can gracefully handle transient LLM API issues (e.g., service degradation, temporary model performance issues).

**Examples:**
-   **High-Volume Email Classifier:** An `Assembly Line` uses an LLM to classify emails. If the classifier agent starts returning malformed JSON repeatedly, the Circuit Breaker trips. All incoming emails are temporarily routed to a "default" inbox or marked as "needs manual review" instead of stopping the entire ingestion pipeline.
-   **Real-Time Recommendation Engine:** A service calls an LLM to generate personalized product recommendations. If the recommendation agent starts failing, the breaker trips and the system serves a generic, non-personalized list of "popular products" as a fallback until the agent recovers.
-   **Interactive Chatbot:** A `Recursive Inquisitor` drives a conversation. If any of its core prompts begin to fail consistently, the breaker for that specific reasoning task trips. The bot can then respond with a safe, pre-scripted message like, "I'm having trouble with that request right now. Please try again in a few minutes or rephrase your question."

## 3. Structure & Participants

**Diagram:**
```mermaid
graph TD
    subgraph Orchestrator
        Request -- "1. Request" --> BreakerWrapper[Circuit Breaker Wrapper];
    end

    subgraph BreakerWrapper
        direction LR
        BreakerState[State: Closed | Open | Half-Open];
        Counter[Failure Count];
        BreakerLogic{Breaker Logic};

        BreakerState --> BreakerLogic;
        Counter --> BreakerLogic;
    end

    BreakerLogic -- "2a. (Closed) Forward Call" --> LLMAgent[LLM Agent];
    BreakerLogic -- "2b. (Open) Route to Fallback" --> FallbackHandler[Fallback Handler];

    LLMAgent -- "Success" --> SuccessResponse;
    LLMAgent -- "Failure" --> FailureHandler[Failure Handler];
    FailureHandler -- "Increment Counter" --> Counter;

    FallbackHandler -- "Fallback Response" --> FinalResponse;
    SuccessResponse --> FinalResponse;

    style BreakerWrapper fill:#e6e6e6,stroke:#333
```

**Participants:**
-   **The Orchestrator:** The main application logic that wishes to call an LLM agent.
-   **The Circuit Breaker Wrapper:** A component that intercepts the call from the Orchestrator. It is the core of the pattern. It maintains the agent's current `state` (`CLOSED`, `OPEN`, `HALF-OPEN`), a `failure_count`, and a timestamp for when the breaker was last tripped.
-   **The LLM Agent:** The actual LLM call being protected. This can be any LLM-based component, such as a worker from an `Assembly Line`.
-   **The Fallback Handler:** A safe, deterministic, and typically low-latency function that provides a default response when the circuit is open. This could be returning a cached result, a pre-defined error message, or a simplified version of the expected output.

## 4. Collaboration & Dynamics

The pattern operates as a state machine that gates access to the LLM agent.

**States:**
1.  **`CLOSED`:** The initial state. Calls pass through directly to the LLM agent.
    -   If a call **succeeds**, the `failure_count` is reset to 0.
    -   If a call **fails** (e.g., invalid JSON, timeout, semantic error), the `failure_count` is incremented.
    -   When `failure_count` exceeds a **threshold** (e.g., 3 failures in 60 seconds), the breaker `trips`: its state changes to `OPEN`, and a cooldown timer is started.

2.  **`OPEN`:** The "tripped" state.
    -   All incoming calls are immediately **rejected** without contacting the LLM.
    -   The call is instantly redirected to the **Fallback Handler**, which returns a safe, default response.
    -   When the **cooldown timer** expires (e.g., 5 minutes), the state changes to `HALF-OPEN`.

3.  **`HALF-OPEN`:** The "testing the waters" state.
    -   The **next single call** is allowed to pass through to the LLM agent.
    -   If this trial call **succeeds**, the breaker is considered healthy. The state resets to `CLOSED`, and the `failure_count` is cleared.
    -   If this trial call **fails**, the system assumes the fault persists. The breaker state immediately reverts to `OPEN`, and the cooldown timer is reset.

## 5. Consequences & Trade-offs

-   **Benefits:**
    -   `High Resilience:` Protects the application from being overwhelmed by a faulty or unavailable LLM agent, preventing system-wide outages.
    -   `Fail Fast:` When the circuit is open, the system fails instantly and predictably, providing an immediate fallback instead of waiting for a slow, timed-out request.
    -   `Cost Control:` Prevents wasted API calls and associated costs when an agent is clearly malfunctioning.
    -   `Automatic Recovery:` The `HALF-OPEN` state provides a mechanism for the system to automatically detect when the LLM agent has recovered without manual intervention.

-   **Trade-offs / Risks:**
    -   `Increased Complexity:` The orchestrator must now manage the state (count, state, timestamp) for each protected agent. This is typically handled in a shared cache like Redis or an in-memory store.
    -   `Degraded Service:` While the breaker is open, users receive a fallback response which is, by definition, less functional than the primary response.
    -   `Configuration Tuning:` The parameters (failure threshold, cooldown period) need to be carefully tuned for each agent based on its criticality and expected traffic.

## 6. Reference Implementation

A robust implementation requires a state store. Here is a simplified `bash` version using temporary files to simulate state.

### Example Implementation

**`circuit_breaker.sh` (The Wrapper):**
```bash
#!/bin/bash
# Circuit Breaker Pattern - Protecting LLM Agents

# Arguments
AGENT_NAME="$1"
AGENT_PROMPT="$2"
INPUT_DATA="$3"

# Validate arguments
if [ -z "$AGENT_NAME" ] || [ -z "$AGENT_PROMPT" ] || [ -z "$INPUT_DATA" ]; then
  echo "Usage: $0 <agent_name> <agent_prompt> <input_data>"
  exit 1
fi

# Configuration
STATE_DIR="/tmp/circuit_breakers"
mkdir -p "$STATE_DIR"

# State files for this agent
STATE_FILE="${STATE_DIR}/${AGENT_NAME}.state"
COUNT_FILE="${STATE_DIR}/${AGENT_NAME}.count"
TIMER_FILE="${STATE_DIR}/${AGENT_NAME}.timer"
WINDOW_FILE="${STATE_DIR}/${AGENT_NAME}.window"

# Breaker configuration
FAILURE_THRESHOLD=3
TIME_WINDOW=60  # seconds
COOLDOWN_SECONDS=300  # 5 minutes

# Initialize files
touch "$STATE_FILE" "$COUNT_FILE" "$TIMER_FILE" "$WINDOW_FILE"

# Function to clean old failures outside time window
clean_old_failures() {
  local current_time=$(date +%s)
  local window_start=$((current_time - TIME_WINDOW))
  
  # Read all failure timestamps and keep only recent ones
  local recent_failures=""
  while IFS= read -r timestamp; do
    if [ -n "$timestamp" ] && [ "$timestamp" -gt "$window_start" ]; then
      recent_failures="${recent_failures}${timestamp}\n"
    fi
  done < "$WINDOW_FILE"
  
  echo -e "$recent_failures" > "$WINDOW_FILE"
}

# Function to count recent failures
count_recent_failures() {
  clean_old_failures
  local count=$(grep -c "^[0-9]" "$WINDOW_FILE" 2>/dev/null || echo "0")
  echo "$count"
}

# Function to record failure
record_failure() {
  echo "$(date +%s)" >> "$WINDOW_FILE"
}

# Read current state
CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null | tr -d '[:space:]')
[ -z "$CURRENT_STATE" ] && CURRENT_STATE="CLOSED"

# Main breaker logic
case "$CURRENT_STATE" in
  "OPEN")
    TRIP_TIME=$(cat "$TIMER_FILE" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    
    if (( NOW > TRIP_TIME + COOLDOWN_SECONDS )); then
      # Cooldown expired, move to half-open
      echo "HALF-OPEN" > "$STATE_FILE"
      CURRENT_STATE="HALF-OPEN"
      echo "🔶 Circuit breaker for '$AGENT_NAME' is HALF-OPEN (testing...)"
    else
      # Still in cooldown
      REMAINING=$((TRIP_TIME + COOLDOWN_SECONDS - NOW))
      echo "{
        \"error\": \"Circuit breaker is OPEN for agent '$AGENT_NAME'\",
        \"fallback\": true,
        \"retry_after_seconds\": $REMAINING,
        \"message\": \"Service temporarily unavailable. Using fallback response.\"
      }"
      exit 0
    fi
    ;;
esac

# Attempt the actual LLM call
if [ "$CURRENT_STATE" = "CLOSED" ] || [ "$CURRENT_STATE" = "HALF-OPEN" ]; then
  # Make the LLM call
  RESPONSE=$(echo "$INPUT_DATA" | claude -p "$AGENT_PROMPT" 2>&1)
  EXIT_CODE=$?
  
  # Validate response (check if it's valid JSON)
  if [ $EXIT_CODE -eq 0 ] && echo "$RESPONSE" | jq . > /dev/null 2>&1; then
    # SUCCESS
    echo "CLOSED" > "$STATE_FILE"
    echo "0" > "$COUNT_FILE"
    > "$WINDOW_FILE"  # Clear failure window
    echo "$RESPONSE"
    exit 0
  else
    # FAILURE
    record_failure
    FAILURE_COUNT=$(count_recent_failures)
    
    if [ "$CURRENT_STATE" = "HALF-OPEN" ]; then
      # Trial call failed, reopen circuit
      echo "OPEN" > "$STATE_FILE"
      echo "$(date +%s)" > "$TIMER_FILE"
      echo "{
        \"error\": \"Agent '$AGENT_NAME' test call failed. Circuit RE-OPENED.\",
        \"fallback\": true,
        \"details\": \"Half-open test failed, returning to open state\"
      }"
      exit 1
    else
      # Regular failure in CLOSED state
      if (( FAILURE_COUNT >= FAILURE_THRESHOLD )); then
        # Threshold exceeded, trip the breaker
        echo "OPEN" > "$STATE_FILE"
        echo "$(date +%s)" > "$TIMER_FILE"
        echo "🔴 Circuit breaker TRIPPED for agent '$AGENT_NAME' (failures: $FAILURE_COUNT)"
        echo "{
          \"error\": \"Agent '$AGENT_NAME' exceeded failure threshold\",
          \"fallback\": true,
          \"failure_count\": $FAILURE_COUNT,
          \"circuit_state\": \"OPEN\"
        }"
        exit 1
      else
        # Under threshold, return error but keep circuit closed
        echo "{
          \"error\": \"Agent '$AGENT_NAME' call failed\",
          \"fallback\": false,
          \"failure_count\": $FAILURE_COUNT,
          \"threshold\": $FAILURE_THRESHOLD,
          \"raw_error\": \"$RESPONSE\"
        }"
        exit 1
      fi
    fi
  fi
fi
```

### Usage Example

**`protected_classifier.sh`:**
```bash
#!/bin/bash
# Example: Email classifier protected by circuit breaker

EMAIL_CONTENT="$1"

# Define the classification prompt
CLASSIFIER_PROMPT='Classify this email as SPAM, URGENT, or NORMAL.
Respond with JSON: {"category": "CLASSIFICATION", "confidence": 0.0-1.0}'

# Call through circuit breaker
RESULT=$(./circuit_breaker.sh "email_classifier" "$CLASSIFIER_PROMPT" "$EMAIL_CONTENT")

if [ $? -eq 0 ]; then
  # Success - process normally
  CATEGORY=$(echo "$RESULT" | jq -r '.category')
  echo "✅ Email classified as: $CATEGORY"
else
  # Check if it's a fallback response
  IS_FALLBACK=$(echo "$RESULT" | jq -r '.fallback')
  
  if [ "$IS_FALLBACK" = "true" ]; then
    echo "⚠️  Classifier unavailable, using fallback"
    # Default classification when breaker is open
    echo "📥 Email routed to: MANUAL_REVIEW"
  else
    echo "❌ Classification error (circuit still closed)"
    # Handle regular failure
  fi
fi
```

### Advanced Circuit Breaker Features

**1. Per-Agent Configuration:**
```bash
# Load agent-specific configuration
case "$AGENT_NAME" in
  "critical_agent")
    FAILURE_THRESHOLD=1  # Very sensitive
    COOLDOWN_SECONDS=600  # 10 minutes
    ;;
  "bulk_processor")
    FAILURE_THRESHOLD=10  # More tolerant
    COOLDOWN_SECONDS=60   # 1 minute
    ;;
esac
```

**2. Sophisticated Failure Detection:**
```bash
# Check multiple failure conditions
validate_response() {
  local response="$1"
  
  # Check JSON validity
  if ! echo "$response" | jq . > /dev/null 2>&1; then
    return 1
  fi
  
  # Check for specific error patterns
  if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
    return 1
  fi
  
  # Check for quality metrics
  local confidence=$(echo "$response" | jq -r '.confidence // 0')
  if (( $(echo "$confidence < 0.5" | bc -l) )); then
    return 1
  fi
  
  return 0
}
```

**3. Metrics and Monitoring:**
```bash
# Log breaker events for monitoring
log_breaker_event() {
  local event_type="$1"
  local agent="$2"
  local state="$3"
  
  echo "$(date -Iseconds) | BREAKER_EVENT | agent=$agent | type=$event_type | state=$state" >> /var/log/circuit_breaker.log
  
  # Could also send to monitoring service
  # curl -X POST monitoring.service/metrics \
  #   -d "{\"metric\": \"circuit_breaker.$event_type\", \"agent\": \"$agent\"}"
}
```

The Circuit Breaker pattern provides essential resilience for production LLM systems, ensuring that failures are contained and systems degrade gracefully rather than catastrophically.