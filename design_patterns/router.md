# PATTERN: The Router

> **Intent:** To dynamically delegate a task to one of several specialized sub-agents based on an initial analysis of the input, acting as an intelligent, context-aware switchboard.

---

## 1. Context & Motivation

Complex systems often handle a variety of tasks that cannot be processed by a single, linear pipeline. For example, a system monitoring incoming customer support tickets must handle diverse requests: one ticket might be a simple password reset, another a critical bug report, and a third a sales inquiry.

A naive approach would be to create a monolithic "do-everything" prompt, but this violates the principle of specialization and leads to poor performance. An `Assembly Line` is unsuitable because the processing path for a password reset is completely different from that of a bug report.

**The Router** pattern solves this by introducing a "triage" step. A dedicated, lightweight "Router" LLM agent first examines the input and does *nothing but classify it*. Based on its classification, the Orchestrator then dispatches the task to a completely separate, specialized `Assembly Line` or `Inquisitor` process. This is the programmatic equivalent of a call center operator asking, "Is this about sales, support, or billing?" and routing you to the correct department.

## 2. Applicability & Use Cases

This pattern is essential for any system that must handle a variety of inputs or tasks whose processing paths are not uniform.

Use this pattern when:
-   Your system has multiple, distinct "entry points" or task types.
-   The type of an incoming task is not known in advance and must be determined from the content of the input itself.
-   You want to direct tasks to highly specialized workers or sub-pipelines for maximum efficiency and quality.
-   You need to separate the logic of "classification" from the logic of "execution."

**Examples:**
-   **Intelligent Log Processor:** The `Router` reads a log line. If it sees "ERROR," it routes to the `Root Cause Analysis Inquisitor`. If "WARN," it routes to the `Trend Analysis Pipeline`. If "INFO," it sends it to a simple log archiver.
-   **Multi-purpose Chatbot Command Parser:** The `Router` reads a user's message. If it detects an intent to "book a flight," it dispatches to the `Flight Booking Assembly Line`. If the intent is "check my flight status," it dispatches to a simple `API Fetcher` agent.
-   **Dynamic Document Processing:** The `Router` inspects a document. If it's a legal contract, it routes to a `Clause Extraction Pipeline`. If it's a financial report, it routes to a `Key Figure Summarizer`. If it's a resume, it routes to a `Skills Parser`.

## 3. Structure & Participants

**Diagram:**
```mermaid
graph TD
    subgraph Orchestrator
        InputData -- "1. Receive Input" --> RouterAgent[Router LLM];
        RouterAgent -- "2. Returns `{route_decision: 'Path_A', payload: ...}`" --> DecisionGate{Decision Logic};
        DecisionGate -- "If Path A" --> Worker_A[Worker/Pipeline A];
        DecisionGate -- "If Path B" --> Worker_B[Worker/Pipeline B];
        DecisionGate -- "If Fallback" --> Fallback[Fallback Handler];
        Worker_A -- "Result A" --> FinalResult;
        Worker_B -- "Result B" --> FinalResult;
        Fallback -- "Error/Info" --> FinalResult;
    end
    
    LLM_Primitive
    Orchestrator -- "Calls LLM for agents" --> LLM_Primitive

    classDef router fill:#c9f,stroke:#333,stroke-width:2px;
    class RouterAgent router;
    classDef worker fill:#f9f,stroke:#333,stroke-width:2px;
    class Worker_A, Worker_B, Fallback worker;
```

**Participants:**
-   **The Orchestrator:** The main script or application. Its key role here is to implement the `switch` statement or `if/elif/else` logic that acts on the Router's decision.
-   **The Router Agent:** The first LLM call in the sequence. This is a lightweight, fast, and highly focused agent. Its sole purpose is to analyze the input and output a decision object, typically containing a `route` key and the original or slightly modified `payload`. Its prompt is optimized for classification and nothing else.
-   **The Specialized Workers / Pipelines:** These are the destinations for the routing. Each worker is a separate LLM agent, or even a full `Assembly Line` or `Recursive Inquisitor` pattern, with its own specialized prompt and logic.
-   **The Fallback Handler (Optional but Recommended):** A special worker designed to handle inputs that the Router cannot classify. This is a critical component for `PROBABILISTIC_RESILIENCE`.

## 4. Collaboration & Dynamics

The pattern operates as a conditional dispatch workflow.

1.  **Initialization:** The Orchestrator receives an input of unknown type.
2.  **Routing / Triage:** The Orchestrator invokes the **Router Agent**, passing it the input. The Router's prompt is a strict command like: "Analyze the following input. Classify it as one of: `BUG_REPORT`, `FEATURE_REQUEST`, or `USER_QUESTION`. Respond ONLY with JSON: `{\"decision\": \"CLASSIFICATION\", \"payload\": \"ORIGINAL_INPUT\"}`."
3.  **Decision & Validation:** The Orchestrator receives the decision object from the Router. It validates the response and reads the value of the `decision` key.
4.  **Dispatch:** The Orchestrator uses a conditional block (e.g., `case` or `if/elif/else`) to execute the appropriate logic based on the `decision`:
    -   If `"BUG_REPORT"`, it invokes the Bug Report Analysis Pipeline.
    -   If `"FEATURE_REQUEST"`, it calls the Feature Spec Generation Inquisitor.
    -   If `"USER_QUESTION"`, it calls the Documentation Search agent.
    -   If the `decision` is unknown or confidence is low, it calls the Fallback Handler (e.g., "I'm not sure how to handle this, please clarify.").
5.  **Execution:** The selected Specialized Worker or Pipeline runs to completion.
6.  **Termination:** The Orchestrator returns the result from the executed worker.

## 5. Consequences & Trade-offs

-   **Benefits:**
    -   `Efficiency`: The initial routing step is fast and cheap, preventing large, expensive specialized agents from being invoked unnecessarily.
    -   `Extreme Specialization`: Enables the creation of "expert" sub-agents that perform exceptionally well at their single task.
    -   `Scalability`: It is very easy to add new capabilities to the system. You simply train the Router to recognize a new category and then build a new worker pipeline for it, without modifying the existing ones.
    -   `Clarity of Logic`: The top-level control flow is clean and easy to understand (`switch(task_type)`), abstracting away the complexity of each individual path.

-   **Trade-offs / Risks:**
    -   `Central Point of Failure`: The entire system's effectiveness hinges on the Router's accuracy. A misclassification by the Router will send the task down the wrong path, leading to incorrect results.
    -   `Increased Latency (for simple tasks):` There is always a minimum of two LLM calls (Router + Worker), which can be slower for very simple tasks than a single, less specialized agent.
    -   `Router Brittleness`: The Router prompt needs to be very carefully designed with a strict, closed set of possible decision outputs to ensure it doesn't "hallucinate" a new, unhandled route.

## 6. Reference Implementation

### Example Implementation

**`run_router.sh` (Orchestrator):**
```bash
#!/bin/bash
# Router Pattern - Support Ticket Processor

# Validate input
if [ -z "$1" ]; then
  echo "Usage: $0 \"<ticket_text>\""
  exit 1
fi
INPUT_DATA="$1"

# Configuration
PROMPT_DIR="prompts"
HELPERS_DIR="helpers"

# 1. Routing Stage
echo "🔀 Routing ticket..."
ROUTER_PROMPT="You are a support ticket classifier.

Analyze this ticket and classify it as exactly one of:
- BUG: Technical issues, errors, or malfunctions
- FEATURE: New functionality requests or enhancements
- QUESTION: General inquiries or how-to questions

Respond ONLY with JSON:
{\"decision\": \"CLASSIFICATION\", \"confidence\": 0.0-1.0}

TICKET: $INPUT_DATA"

ROUTER_OUTPUT=$(echo "$ROUTER_PROMPT" | claude -p)

# Validate routing decision
if ! echo "$ROUTER_OUTPUT" | jq -e '.decision' > /dev/null 2>&1; then
  echo "❌ Router failed: Invalid classification"
  exit 1
fi

DECISION=$(echo "$ROUTER_OUTPUT" | jq -r '.decision')
CONFIDENCE=$(echo "$ROUTER_OUTPUT" | jq -r '.confidence // 0')

echo "📋 Classification: $DECISION (confidence: $CONFIDENCE)"

# Check confidence threshold
if (( $(echo "$CONFIDENCE < 0.7" | bc -l) )); then
  echo "⚠️  Low confidence routing to fallback handler"
  DECISION="FALLBACK"
fi

# 2. Dispatch Stage
case "$DECISION" in
  "BUG")
    echo "🐛 Processing as bug report..."
    BUG_PROMPT=$(cat "${PROMPT_DIR}/worker_bug.txt")
    RESULT=$(echo -e "${BUG_PROMPT}\n\nTICKET: $INPUT_DATA" | claude -p)
    ;;
    
  "FEATURE")
    echo "✨ Processing as feature request..."
    FEATURE_PROMPT=$(cat "${PROMPT_DIR}/worker_feature.txt")
    RESULT=$(echo -e "${FEATURE_PROMPT}\n\nTICKET: $INPUT_DATA" | claude -p)
    ;;
    
  "QUESTION")
    echo "❓ Processing as user question..."
    QUESTION_PROMPT=$(cat "${PROMPT_DIR}/worker_question.txt")
    RESULT=$(echo -e "${QUESTION_PROMPT}\n\nTICKET: $INPUT_DATA" | claude -p)
    ;;
    
  "FALLBACK"|*)
    echo "🤷 Using fallback handler..."
    FALLBACK_PROMPT="Process this ambiguous support ticket with a general response.
    Acknowledge the request and ask for clarification if needed.
    
    TICKET: $INPUT_DATA"
    RESULT=$(echo "$FALLBACK_PROMPT" | claude -p)
    ;;
esac

# Output result
echo -e "\n📄 Processed Result:\n"
echo "$RESULT"
```

**Worker Prompt Examples:**

**`prompts/worker_bug.txt`:**
```
You are a bug report specialist. Analyze this bug report and extract:
1. Steps to reproduce
2. Expected vs actual behavior
3. Severity assessment
4. Suggested troubleshooting steps

Format as structured JSON with these fields:
{
  "summary": "brief description",
  "steps_to_reproduce": ["step1", "step2"],
  "expected_behavior": "description",
  "actual_behavior": "description",
  "severity": "critical|high|medium|low",
  "troubleshooting": ["suggestion1", "suggestion2"],
  "requires_escalation": boolean
}
```

**`prompts/worker_feature.txt`:**
```
You are a feature request analyst. For this feature request:
1. Identify the core need
2. Assess feasibility and impact
3. Generate clarifying questions
4. Suggest implementation approach

Return a structured analysis:
{
  "feature_title": "concise title",
  "user_story": "As a [user], I want [feature] so that [benefit]",
  "impact": "high|medium|low",
  "complexity": "simple|moderate|complex",
  "clarifying_questions": ["question1", "question2"],
  "implementation_notes": "brief technical approach"
}
```

### Advanced Router Implementation

For more sophisticated routing, consider:

```bash
# Multi-level routing with sub-routers
PRIMARY_ROUTE=$(classify_primary "$INPUT")
case "$PRIMARY_ROUTE" in
  "TECHNICAL")
    SUB_ROUTE=$(classify_technical "$INPUT")
    case "$SUB_ROUTE" in
      "BACKEND") process_backend_issue "$INPUT" ;;
      "FRONTEND") process_frontend_issue "$INPUT" ;;
      "DATABASE") process_database_issue "$INPUT" ;;
    esac
    ;;
  "BUSINESS")
    SUB_ROUTE=$(classify_business "$INPUT")
    # ... handle business sub-routes
    ;;
esac

# Parallel routing for multi-aspect analysis
ROUTES=$(echo "$INPUT" | claude -p "Identify ALL applicable categories")
for route in $(echo "$ROUTES" | jq -r '.categories[]'); do
  process_route "$route" "$INPUT" &
done
wait
```

### Composing with Other Patterns

The Router often serves as the entry point to other patterns:

```bash
case "$DECISION" in
  "COMPLEX_ANALYSIS")
    # Route to a Recursive Inquisitor
    ./inquisitor_debug.sh "$INPUT"
    ;;
  "DOCUMENT_PROCESSING")
    # Route to an Assembly Line
    ./pipeline_document.sh "$INPUT"
    ;;
  "MULTI_REVIEW")
    # Route to Fan-Out/Fan-In
    ./fanout_review.sh "$INPUT"
    ;;
esac
```

The Router pattern enables intelligent task distribution, ensuring each input receives specialized processing while maintaining system-wide coherence and efficiency.