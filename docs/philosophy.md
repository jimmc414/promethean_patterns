# The Philosophy of Promethean Patterns

## Core Principles

Before we document any patterns, we must define the "laws of physics" for our new world. These principles are the foundation upon which all Promethean Patterns are built.

### 1. Principle of the LLM as a Compute Primitive

The LLM is not a "partner" but a powerful, stateless function `f(prompt) -> output`. Treat it like `grep`, `awk`, or a compiler, not a person.

**Implications:**
- No anthropomorphization in system design
- Clear input/output contracts
- Deterministic orchestration logic
- The LLM is a tool, not the architect

**Example:**
```bash
# Good: LLM as function
result=$(echo "$data" | claude -p "Extract entities")

# Bad: LLM as conversationalist
claude -p "Hey Claude, can you help me extract entities?"
```

### 2. Principle of Structured Interfaces

Communication with the LLM primitive should be through a strict, machine-readable format (e.g., JSON). This is the Application Binary Interface (ABI) for this new form of computing.

**Implications:**
- All inputs and outputs must be parseable
- Schema validation is mandatory
- Type safety through structure
- No ambiguous text responses

**Example:**
```json
// Input
{
  "task": "analyze_code",
  "data": "function foo() { return 42; }",
  "output_schema": "security_analysis_v1"
}

// Output
{
  "vulnerabilities": [],
  "quality_score": 95,
  "recommendations": ["Add JSDoc comments"]
}
```

### 3. Principle of Externalized State

The LLM is stateless. All state must be managed by the orchestration layer and explicitly passed into the prompt on each call. There is no "memory" other than what you provide.

**Implications:**
- State is always explicit
- No hidden context
- Full state reconstruction on each call
- State persistence is orchestrator's responsibility

**Example:**
```bash
# State explicitly managed and passed
STATE='{"conversation_history": [...], "current_topic": "..."}'
RESPONSE=$(echo "$STATE" | claude -p "$PROMPT_WITH_STATE_INJECTION")
NEW_STATE=$(echo "$RESPONSE" | jq '.updated_state')
```

### 4. Principle of Orchestration over Conversation

The goal is to build automated systems, not to chat. The "conversation" is the structured data passed between system components.

**Implications:**
- Focus on task completion, not dialogue
- Minimize interactive elements
- Batch operations where possible
- System-to-system communication patterns

**Example:**
```bash
# Good: Orchestrated pipeline
cat data.json |
  analyze_stage |
  transform_stage |
  validate_stage > result.json

# Bad: Chat-oriented design
while true; do
  read -p "What would you like to do next? " user_input
  claude -p "$user_input"
done
```

### 5. Principle of Probabilistic Execution

The output is not guaranteed to be identical or even valid. The system must be designed defensively with validation, retries, and fallback mechanisms.

**Implications:**
- Always validate outputs
- Implement retry logic
- Design fallback paths
- Monitor success rates
- Handle partial failures gracefully

**Example:**
```bash
# Defensive design with validation and retry
attempt=0
max_attempts=3
while [ $attempt -lt $max_attempts ]; do
  RESPONSE=$(echo "$INPUT" | claude -p "$PROMPT")
  if validate_json "$RESPONSE"; then
    break
  fi
  ((attempt++))
  sleep $((2 ** attempt))  # Exponential backoff
done

if [ $attempt -eq $max_attempts ]; then
  use_fallback_response
fi
```

## The Promethean Mindset

Beyond these technical principles, adopting Promethean Patterns requires a philosophical shift:

### From Conversation to Computation
Stop thinking of LLMs as chat partners. Start thinking of them as computational units in a larger system. The question isn't "What should I ask Claude?" but "How do I decompose this problem into computational steps?"

### From Monoliths to Modules
Just as Unix philosophy advocates for small, focused tools that do one thing well, Promethean Patterns advocate for specialized, focused prompts that excel at specific tasks.

### From Sequential to Systematic
Move beyond simple request-response patterns. Think in terms of pipelines, routers, parallel processing, and error handling. Build systems, not scripts.

### From Fragile to Fault-Tolerant
Accept that LLMs will fail, hallucinate, and produce unexpected outputs. Design for these failures from the start, not as an afterthought.

## Why These Principles Matter

These principles aren't arbitrary constraints—they're hard-won lessons from production systems. Violating them leads to:

- **Fragile systems** that break when the LLM's behavior changes
- **Unmaintainable code** where logic is scattered between prompts and code
- **Poor performance** from unnecessary back-and-forth exchanges
- **Security vulnerabilities** from unvalidated outputs
- **Debugging nightmares** from implicit state and context

By following these principles, you build systems that are:

- **Robust**: They handle failures gracefully
- **Maintainable**: Clear separation of concerns
- **Performant**: Efficient use of LLM calls
- **Testable**: Deterministic orchestration logic
- **Scalable**: Patterns that work at any scale

## The Path Forward

These principles form the foundation of the Promethean Patterns catalog. Each pattern in our collection respects these principles while solving specific orchestration challenges.

As you implement these patterns, always return to these principles. They are your North Star in the emerging field of LLM orchestration.

---

*"Principles are the fundamental truths that serve as the foundations for behavior that gets you what you want out of life." - Ray Dalio*

Next: [Explore the Pattern Catalog →](patterns/)