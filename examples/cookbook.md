# **The Promethean Cookbook (Final Comprehensive Edition)**

**A Complete Guide to Foundational Primitives, Practical Techniques, and Advanced Recipes for LLM Orchestration**

## **Introduction: From Patterns to Primitives**

The **Promethean Patterns Guide** describes the high-level *architecture* for building robust LLM-driven systems. This **Cookbook** provides the low-level *tactics*—the individual tools, prompt structures, and command-line recipes required to implement those patterns effectively.

This guide is built on one core realization: **a command-line LLM is a new kind of Unix primitive**. It reads from standard input, processes based on its prompt (its "arguments"), and writes to standard output. By mastering the primitives of both prompting (`STRUCTURED_INTERFACE`) and shell orchestration (`ORCHESTRATION_LOGIC`), you can build systems of remarkable power and complexity.

---

## **Part 1: The Core Principles of LLM Interaction**

Understanding *why* these techniques work is essential. The LLM is not executing code; it is performing sophisticated pattern recognition based on its training on vast amounts of code, documentation, and technical writing.

### **1.1. The Operator's Mental Model**

-   **Contract Fulfillment:** When you provide a structured format like JSON in your prompt, the LLM treats it as a strict API contract. Its highest priority becomes fulfilling this contract, which is why structured output is so reliable.

-   **Role-Based Specialization:** A role (`You are a cybersecurity analyst`) primes the model, focusing its attention and activating the specific knowledge relevant to that domain.

-   **Inferred Intent from Schema:** The model decodes your intent from the structure you provide:
    -   `"action": "test" | "build"` infers an `enum`, forcing a choice.
    -   `"next_file": "path or null"` infers an `iterator` or linked list, hinting at control flow.
    -   `"confidence_score": float` infers a need for self-assessment.
    -   `"if_approved": {...}` infers a conditional block pattern.

-   **The Unix Philosophy as Training Data:** The LLM has been trained on decades of examples where small, single-purpose command-line tools are piped together. By using `|`, `>` and other shell operators, you are placing your LLM call within a familiar context, and it adapts its behavior accordingly.

### **1.2. The Foundational Technique: Structured Output**

The cornerstone of all Promethean Patterns is commanding the LLM to respond in a machine-readable format.

**The Basic Prompt Structure:**
```bash
claude -p "You are a [ROLE]. Output [FORMAT]: [SCHEMA_DEFINITION]"
```

**Example:**
```bash
claude -p "You are a code analyzer. Output JSON: {analysis: ..., next_file: ...}"
```

**Why This Works So Well (The Four Pillars):**
1.  **Eliminates Parsing Ambiguity:** The output is machine-readable `application/json`, not unpredictable natural language prose. This allows direct, reliable parsing with tools like `jq` or `json.loads()`.
2.  **Enforces Type and Shape Safety:** The schema (`{key: type}`) acts as a contract. The orchestrator knows exactly what fields and data types to expect, reducing runtime errors.
3.  **Enables Composability:** The structured output of one LLM call can be reliably piped as the structured input to another, forming the basis for the **Assembly Line** pattern.
4.  **Acts as Self-Documentation:** The prompt itself clearly documents the expected data structure of the LLM agent's response.

### **1.3. The Prompt "Verbs": A Command Vocabulary**

Using strong, imperative verbs turns your prompt from a question into a command. This vocabulary is the tactical toolkit for building the master prompts used in all Promethean Patterns.

#### **Output & Formatting Commands**
-   `Output JSON: {key: type}` - The most common and reliable method.
-   `Format as: markdown table with columns: ...` - For human-readable reports.
-   `Render as: ASCII diagram` - For visualizations.
-   `Generate: YAML configuration` - For structured, non-JSON output.
-   `Produce:`, `Emit:` - Alternative formatting verbs.

#### **Transformation & Analysis Commands**
-   `Convert to: TypeScript` - For code translation.
-   `Rewrite as: functional style` - For refactoring.
-   `Extract: all email addresses as a JSON array` - For entity extraction.
-   `Identify: security vulnerabilities as {type, severity}` - For targeted analysis.
-   `Transform into:`, `Express as:`, `Translate to:` - Variations for different contexts.

#### **Behavioral & Control Flow Commands**
-   `Act as: a Python REPL` - To simulate another program.
-   `Decide: which files need review` - To guide `The Router` pattern.
-   `Judge: code quality on a scale of 1-10` - For scoring and ranking.
-   `For each function: output a JSON object` - For iterative processing on input.
-   `Behave like:`, `Simulate:`, `Emulate:` - For system impersonation.
-   `Choose:`, `Determine:`, `Evaluate to:`, `Classify as:` - For decision making.

#### **Constraint Modifiers**
-   `Only output:`, `Exclusively return:`, `Limit response to:` - For pure, non-verbose output.
-   `Restrict to:`, `Limit to:` - Additional constraint variations.

---

## **Part 2: The Orchestrator's Toolkit (The Unix Philosophy)**

These are the shell primitives used by your orchestrator scripts to manage data flow and implement `EXTERNAL_STATE`.

### **2.1. Standard I/O: The Pipes of Communication**

-   **Pipe `|`**: Chains commands. The backbone of **The Assembly Line**.
    ```bash
    cat code.py | claude -p "Extract..." | jq '.'
    ```

-   **Input Redirect `<`**: Feeds a file to `stdin`.
    ```bash
    claude -p "Summarize..." < notes.txt
    ```

-   **Output Redirects `>` & `>>`**: Saves or appends output to a file.
    ```bash
    claude -p "Analyze..." > analysis.log
    claude -p "Format as log entry" >> system.log
    ```

-   **Here-String `<<<`**: Feeds a short string to `stdin`.
    ```bash
    claude -p "Translate..." <<< "Hello, world!"
    ```

-   **Here-Document `<<EOF`**: The standard for multi-line strings or prompts within a script.
    ```bash
    PROMPT=$(cat <<EOF
    You are a specialist reviewer.
    The user will provide input below.
    Analyze it carefully.
    EOF
    )
    claude -p "$PROMPT" < data.txt
    ```

### **2.2. Advanced Process & File Handling**

-   **Command Substitution `$(...)`**: Captures a command's output to be used as a string argument.
    ```bash
    claude -p "Review this diff" "$(git diff)"
    ```

-   **Process Substitution `<(...)`**: Makes a command's output behave like a temporary file. Essential for tools like `diff` that require file paths.
    ```bash
    # Compare Python and JavaScript versions
    diff <(claude -p "Write a Python version...") <(claude -p "Write a JS version...")
    ```

-   **Named Pipes `mkfifo`**: Decouples processes. A long-running data source can write to the pipe, and an LLM consumer can read from it at its own pace.
    ```bash
    mkfifo /tmp/log_stream
    tail -f app.log > /tmp/log_stream &
    claude -p "Monitor this log stream..." < /tmp/log_stream
    ```

### **2.3. The `jq` Parser: The Key to State Management**

`jq` is the indispensable tool for interacting with the LLM's JSON output. It is how the orchestrator implements `EXTERNAL_STATE`.

-   **Reading State:** Extracting a single field to make a decision.
    ```bash
    DECISION=$(echo "$LLM_RESPONSE" | jq -r '.next_action')
    ```
    *(Used in the `Router` and `Recursive Inquisitor`)*

-   **Writing State:** Creating a new JSON object to send to the next LLM call.
    ```bash
    COMBINED_INPUT=$(jq -n --argjson analysis "$ANALYSIS_1" --argjson tests "$ANALYSIS_2" \
      '{ "code_analysis": $analysis, "test_cases": $tests }')
    ```
    *(Used in the `Fan-In` reducer and multi-stage `Assembly Line`)*

-   **Aggregating Data:** Combining multiple JSON files.
    ```bash
    AGGREGATED=$(jq -s . *.json)
    ```

-   **Validation:** Checking for the existence of required keys.
    ```bash
    if ! echo "$RESPONSE" | jq -e 'has("error")' >/dev/null; then
      echo "No error field found"
    fi
    ```
    *(Used in the `Circuit Breaker` and all robust implementations for `PROBABILISTIC_RESILIENCE`)*

---

## **Part 3: The Recipe Book - From Primitives to Patterns**

These recipes are concrete applications of the primitives. They serve as inspirations and building blocks for full architectural patterns.

### **Category 1: Code & Data Transformation**

#### **Recipe: The On-the-Fly Migrator**
-   **Task:** Convert data from one format to another on a stream.
-   **Command:** 
    ```bash
    cat old_data.log | claude -p 'For each log line, convert it to the new JSON format: 
    {"timestamp": ..., "level": ..., "message": ...}'
    ```
-   **Mental Model:** The phrase "For each line" combined with JSON triggers an *iterator* pattern.
-   **Pattern Link:** Building block for **Assembly Line** transformations.

#### **Recipe: The Regex/SQL/DSL Generator**
-   **Task:** Generate domain-specific languages from natural language.
-   **Command:** 
    ```bash
    echo "Find lines that start with a timestamp and contain ERROR" | \
    claude -p 'Express this as a single PCRE regex. Only output the regex.'
    ```
-   **Mental Model:** `Express as:` + `Only output:` = pure transformation.

#### **Recipe: The API-to-Type Generator**
-   **Task:** Scaffold code from example data.
-   **Command:** 
    ```bash
    cat api_response.json | claude -p 'Generate a Python Pydantic model for this JSON structure.'
    ```
-   **Mental Model:** Infers schema from instance data.

### **Category 2: System Simulation & Emulation**

#### **Recipe: The Git Impersonator**
-   **Task:** Safely simulate command-line tools.
-   **Command:** 
    ```bash
    echo "status" | claude -p 'Behave like the "git" command-line tool. 
    I will give you subcommands. Respond as git would.'
    ```
-   **Mental Model:** `Behave like:` triggers role-playing mode.

#### **Recipe: The Interactive SQL Database**
-   **Task:** Create a stateful mock database.
-   **Command:** 
    ```bash
    claude -p 'Simulate a SQL database with a table named "users" (id, name, email). 
    Accept SQL queries and return the result as a markdown table.'
    ```
-   **Mental Model:** `Simulate:` + schema = stateful REPL.
-   **Pattern Link:** Mini **Recursive Inquisitor** when wrapped in a loop.

#### **Recipe: The Protocol Follower**
-   **Task:** Implement technical specifications.
-   **Command:** 
    ```bash
    cat rpc_request.json | claude -p 'Follow the JSON-RPC 2.0 protocol. 
    Process this request and return a valid response.'
    ```
-   **Mental Model:** Leverages training on RFCs and specs.

### **Category 3: Autonomous & Planning Agents**

#### **Recipe: The Dynamic Build Coordinator**
-   **Task:** Make intelligent CI/CD decisions.
-   **Command:** 
    ```bash
    git status --porcelain | claude -p 'You are a build coordinator. Decide the next action. 
    Output JSON: {"action": "test"|"build"|"lint", "target": "...", "reason": "..."}'
    ```
-   **Mental Model:** `Decide:` + discriminated union = planning engine.
-   **Pattern Link:** Core of **The Router** pattern.

#### **Recipe: The Recursive Filesystem Explorer**
-   **Task:** Autonomously navigate and understand a codebase.
-   **Command:** 
    ```bash
    ls -F | claude -p 'Which file should you explore next to understand this project? 
    Output JSON: {"next_target": "filename", "reason": "...", "should_recurse": boolean}'
    ```
-   **Mental Model:** `next_target` key creates self-direction.
-   **Pattern Link:** Autonomous **Recursive Inquisitor** variant.

#### **Recipe: The Self-Healing System Monitor**
-   **Task:** Diagnose and propose fixes.
-   **Command:** 
    ```bash
    tail -n 100 error.log | claude -p 'You are a system monitor. 
    Output JSON: {"status": "healthy"|"degraded"|"failing", 
    "suggested_fix_command": "...", "confidence": float}'
    ```
-   **Mental Model:** Combines analysis with actionable output.
-   **Pattern Link:** Advanced **Circuit Breaker** recovery.

### **Category 4: Power User Combinations**

#### **The `git-summarize` Alias**
```bash
alias git-summarize="git diff main | \
  claude -p 'Summarize these code changes in three bullet points, focusing on intent.'"
```

#### **The Self-Improving Prompt Optimizer**
```bash
PROMPT_V1="Summarize text."
FEEDBACK="The summaries were too short and missed key details."

IMPROVED=$(claude -p "Given the original prompt and user feedback, generate an improved prompt.
Original: '$PROMPT_V1'
Feedback: '$FEEDBACK'
Output JSON: {\"improved_prompt\": \"...\"}" | jq -r '.improved_prompt')

echo "Improved prompt: $IMPROVED"
```

#### **Real-time Log Monitoring & Alerting**
```bash
tail -f application.log | \
  claude -p "Read this log stream. If you see 'FATAL' or 'PANIC', 
  output JSON alert: {\"alert\": true, \"line\": \"...\"}. 
  Otherwise output nothing." | \
  grep --line-buffered alert
```

#### **Git-Aware Code Review**
```bash
claude -p "Review these code changes. Focus on potential bugs and style issues." \
  "$(git diff HEAD~1)"
```

#### **Interactive Command Line Assistant**
```bash
HISTORY=""
while true; do
  read -p "> " INPUT
  RESPONSE=$(claude -p "Context: $HISTORY\n\nUser: $INPUT\n\nAssistant:")
  echo "Assistant: $RESPONSE"
  HISTORY="$HISTORY\nUser: $INPUT\nAssistant: $RESPONSE"
done
```

---

## **Appendix: Pattern Cross-Reference**

This cookbook's techniques map directly to the Promethean Patterns:

- **Structured Output + Pipes** → **The Assembly Line**
- **Decision Verbs + Discriminated Unions** → **The Router**  
- **State Management with `jq`** → **The Recursive Inquisitor**
- **Parallel Processing + Aggregation** → **Fan-Out/Fan-In**
- **Validation + Error Handling** → **The Circuit Breaker**

---

**Final Note:** This cookbook is a living document. As you discover new techniques and mental models, add them here. The true power of the Promethean approach lies not in any single pattern or recipe, but in understanding how to compose these primitives into systems of arbitrary complexity and sophistication.