# Promethean Patterns

> An Exploration of Design Patterns for Claude CLI (`claude -p ""`) Orchestration

## 🎯 Claude CLI Focus

**When this project refers to "Large Language Models", it means specifically: `claude -p ""`**

This entire repository is about orchestrating Claude through its command-line interface. Every pattern, every example, every suggestion is designed for piping data through `claude -p`.

## 🧪 Experimental Boundary-Pushing

This project is an **experimental exploration** seeking to push the limits of what's possible with `claude -p`. The experiments test unconventional concepts like:

- **Claude as a State Machine**: Can a stateless CLI tool maintain complex state through clever prompt engineering?
- **Stateless Applications**: Building entire applications where `claude -p` serves as the core compute engine
- **Recursive Self-Modification**: Patterns where Claude generates prompts for itself
- **Multi-Agent Orchestration**: Complex workflows with multiple Claude instances communicating through structured data
- **Emergent Behaviors**: Discovering what happens when pushing Claude CLI beyond typical use cases

These aren't proven production patterns - they're experiments in computational creativity with `claude -p`.

## What is This?

Promethean Patterns is an experimental laboratory for pushing the boundaries of what's possible with Claude's command-line interface (`claude -p ""`). When this project refers to "Large Language Models" or "LLMs", make no mistake - it is specifically talking about Claude accessed via the CLI command `claude -p ""`. 

This is not a collection of best practices, but rather a playground for exploring radical ideas: What if `claude -p` is treated as a state machine? Can entire stateless applications be built using Claude as the compute primitive? How far can prompt engineering be pushed to create self-modifying systems?

Think of it as a research journal documenting attempts to use `claude -p` in ways it perhaps wasn't designed for - turning a simple CLI tool into complex computational systems.

**Important:** These patterns represent one perspective on Claude CLI orchestration. Your mileage may vary. Feel free to adapt, modify, or ignore these suggestions based on your specific needs. This is an evolving exploration, not established doctrine.

## Why "Promethean"?

Just as Prometheus stole fire from the gods and gave it to humanity, this project attempts to steal computational patterns from traditional programming and give them to `claude -p`. It's transgressive, experimental, and possibly ill-advised - but that's where innovation happens.

## The Promethean Metaphor

The name draws from Prometheus, the Titan who stole fire from Olympus and gave it to humanity. Each major technological leap follows this pattern: transgressive discovery → empowerment of the many → backlash/punishment. From metalworking to steam engines, from electricity to AI, we see this cycle repeat. Understanding these patterns helps us build better systems and anticipate challenges.

## Experimental Concepts Being Explored

### State Machines with Stateless Tools
Can `claude -p` maintain state across invocations? Experiments include:
- Encoding state in prompts that get passed between calls
- Using filesystem as external state storage
- Creating "memory" through clever prompt chaining

### Claude as a Computational Primitive
What if `claude -p` is just another Unix tool like `grep` or `sed`? Explorations include:
- Piping Claude output to Claude input recursively
- Building entire applications as bash scripts orchestrating `claude -p`
- Creating Claude-based compilers and interpreters

### Self-Modifying Systems
Can Claude generate its own prompts? Boundary-pushing experiments include:
- Patterns where Claude writes prompts for subsequent Claude calls
- Meta-programming with natural language
- Emergent behaviors from recursive self-improvement

## Core Perspectives

Through explorations with `claude -p ""`, these perspectives have proven helpful:

1. **Claude CLI as a Compute Primitive** - Treating `claude -p` as a stateless function (like `grep` or `awk`) can simplify system design
2. **Structured Interfaces** - Machine-readable formats (JSON) passed to `claude -p` often improve reliability
3. **Externalized State** - Managing state outside the Claude process tends to work well
4. **Orchestration over Conversation** - Focusing on piping data through `claude -p` rather than interactive chat
5. **Probabilistic Execution** - Designing defensively helps handle the non-deterministic nature of Claude's responses

These aren't rules, but rather perspectives found useful through experimentation. Your approach may differ based on your use case.

[Read more about the philosophy →](docs/philosophy.md)

## The Pattern Catalog: Experimental Designs

These patterns represent attempts to push `claude -p` beyond conventional usage. They're experiments in computational architecture, not proven solutions. Use at your own risk and excitement:

### 1. The Recursive Inquisitor
**Intent:** Iteratively refine complex problems through dynamic questioning until a termination condition is met.

*Consider when:* Building interactive systems that need to extract structured information from vague inputs.

[Full documentation →](design_patterns/recursive_inquisitor.md)

### 2. The Assembly Line
**Intent:** Process data through a series of discrete, specialized transformation stages.

*Consider when:* Complex tasks can be broken into sequential, specialized steps.

[Full documentation →](design_patterns/assembly_line.md)

### 3. The Router
**Intent:** Dynamically delegate tasks to specialized sub-agents based on initial analysis.

*Consider when:* Your system handles varied inputs requiring different processing paths.

[Full documentation →](design_patterns/router.md)

### 4. The Circuit Breaker
**Intent:** Prevent cascading failures by detecting errors and providing safe fallbacks.

*Consider when:* Building production systems that need resilience against LLM failures.

[Full documentation →](design_patterns/circuit_breaker.md)

### 5. The Fan-Out/Fan-In
**Intent:** Process data concurrently from multiple perspectives, then synthesize results.

*Consider when:* Tasks benefit from parallel processing or multi-faceted analysis.

[Full documentation →](design_patterns/fan_out_fan_in.md)

## Quick Start

### Example: Building a Code Review System with Claude CLI

Here's how you might combine patterns to build a production code review system using `claude -p`:

```bash
# 1. Use the Router pattern with Claude to classify incoming PRs
echo "feat: add user authentication" | claude -p "Classify this PR title. Output JSON: {decision: feature|bugfix|refactor, priority: high|medium|low}"
# Output: {decision: "feature", priority: "high"}

# 2. Use Fan-Out/Fan-In for multi-perspective review
cat auth_service.py | claude -p "Review this code for security issues. Output JSON with findings."
cat auth_service.py | claude -p "Review this code for performance. Output JSON with findings."
cat auth_service.py | claude -p "Review this code style. Output JSON with findings."
# Then aggregate results

# 3. Wrap critical Claude calls with Circuit Breaker pattern
# If claude -p fails repeatedly, fallback to cached responses or simpler analysis
./circuit_breaker.sh "security_reviewer" "$PROMPT" "$CODE"
```



## ⚠️ Experimental Warning

**This is research, not production code.** This project intentionally pushes `claude -p` into territories it wasn't designed for:

- **State machines built on stateless tools** - Probably shouldn't work, but sometimes does
- **Recursive self-modification** - Claude writing prompts for Claude, what could go wrong?
- **Bash scripts as application frameworks** - Because why use a real programming language?
- **Natural language as code** - Turning prompts into programs

If you're looking for stable, proven patterns, this isn't it. If you're curious about the computational possibilities of `claude -p` and enjoy experimental computer science, welcome aboard!

## A Note on Approach

This project represents an ongoing exploration of Claude CLI orchestration patterns. Nothing here should be taken as gospel - these are suggestions based on experiments piping data through `claude -p ""`, not universal truths. Claude's behavior through the CLI can be surprising and context-dependent, so what works in one `claude -p` invocation might not work in another.

You are encouraged to:
- Test these patterns in your own context
- Modify them as needed
- Share your own discoveries
- Question these assumptions

This is a collaborative exploration, not a prescriptive framework.

---

*"The best way to predict the future is to invent it." - Alan Kay*

Explore Claude CLI orchestration patterns here. Take what works for your `claude -p` workflows, leave what doesn't, and forge your own path.