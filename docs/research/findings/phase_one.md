Here is a proposed framework and a set of next steps.

---

### **Project Title Proposal:** `promethean_patterns`

A Design Patterns Guide for Orchestrating Large Language Models.

### The "ULTRATHINK" Framework: Beyond a Simple Guide

The Gang of Four's *Design Patterns* book was successful because it provided a shared vocabulary and solutions to common problems in a specific paradigm (Object-Oriented Programming). This project aims to do the same for the **LLM-as-a-Component** paradigm.

This guide cannot be a static PDF. It must be a **living system** composed of three interconnected parts:

1.  **The Philosophy (The "Why"):** The core principles that underpin the entire methodology.
2.  **The Pattern Catalog (The "What"):** A formal, structured catalog of individual patterns.
3.  **The Reference Implementation (The "How"):** A working code library and set of examples that make the patterns real and usable.

---

### **Next Steps: A Phased Roadmap**

#### **Phase 1: Codifying the Philosophy & Vocabulary (The Foundation)**

The first step is establishing foundational axioms. Before documenting any patterns, it's essential to define the "laws of physics" for this new world. This becomes Chapter 1 of the guide.

**First Task:** Draft and refine these core principles.

1.  **Principle of the LLM as a Compute Primitive:** The LLM is not a "partner" but a powerful, stateless function `f(prompt) -> output`. Treat it like `grep`, `awk`, or a compiler, not a person.
2.  **Principle of Structured Interfaces:** Communication with the LLM primitive should be through a strict, machine-readable format (e.g., JSON). This is the Application Binary Interface (ABI) for this new form of computing.
3.  **Principle of Externalized State:** The LLM is stateless. All state must be managed by the orchestration layer and explicitly passed into the prompt on each call. There is no "memory" other than what you provide.
4.  **Principle of Orchestration over Conversation:** The goal is to build automated systems, not to chat. The "conversation" is the structured data passed between system components.
5.  **Principle of Probabilistic Execution:** The output is not guaranteed to be identical or even valid. The system must be designed defensively with validation, retries, and fallback mechanisms.

#### **Phase 2: Architecting the Pattern Catalog**

This is the core of the guide. A formal template is needed for each pattern, inspired by the Gang of Four but adapted for this paradigm.

**Second Task:** Define the pattern template and start populating it.

**Proposed Pattern Template:**

*   **Pattern Name:** A clear, memorable name (e.g., `Recursive Inquisitor`, `Stateful Canvas`).
*   **Intent:** A one-sentence summary of the pattern's goal.
*   **Motivation:** The problem this pattern solves. What "pain point" in LLM orchestration does it address?
*   **Applicability:** In what specific scenarios should this pattern be used?
*   **Structure:** A diagram showing the components (User, Orchestrator, LLM Prompt, State Object).
*   **Participants & Collaborations:** A description of how the components interact.
*   **Consequences & Trade-offs:** What are the benefits? What are the potential pitfalls (e.g., cost, latency, risk of prompt injection)?
*   **Reference Implementation:** A clean, minimal, working code example (`bash`/`python`).
*   **Known Uses:** Real-world or hypothetical examples (e.g., "Used for interactive debugging," "Used for concept refinement").

**Proposed Pattern Categories:**

1.  **Generative Patterns (Creating the "Mind"):** Patterns for how a *single* LLM call is constructed to elicit complex behavior.
    *   *Examples:* Holographic Prompt, Effects Protocol, Self-Critique Loop.
2.  **Structural Patterns (Connecting the "Minds"):** Patterns for how *multiple* LLM calls are orchestrated.
    *   *Examples:* Pipeline, Fan-Out/Fan-In, Multi-Agent Debate, Recursive Inquiry.
3.  **Behavioral Patterns (Managing the "Lifecycle"):** Patterns for controlling the flow and state of an LLM-driven system over time.
    *   *Examples:* Stateful Canvas, Circuit Breaker, State Machine, Self-Terminating Loop.

#### **Phase 3: Building the Reference Toolkit (`libpromethean`)**

A guide is good. A tool is better. Building a tiny, lightweight library (e.g., a `bash` include script or a simple Python module) would make these patterns easier to implement.

**Third Task:** Start building helper functions for the most common operations.

*   `claude_call(prompt, state_json)`: A function that wraps the `claude -p` call, including JSON validation and retries.
*   `extract_state(response_json)`: A reliable way to get the `updated_state` object.
*   `execute_effects(effects_array)`: A safe executor for the "$effects" pattern.
*   A set of template `state.json` files for common patterns.

This toolkit would serve as the official code for the "Reference Implementation" section of each pattern in the guide.

#### **Phase 4: Establishing a Living Document & Community**

This project should live on a platform like GitHub.

**Fourth Task:** Structure a repository for the `promethean_patterns` guide.

*   **`README.md`:** The project mission statement.
*   **`/philosophy`:** A folder for foundational principles.
*   **`/patterns`:** A folder where each pattern gets its own markdown file (`recursive_inquisitor.md`).
*   **`/lib`:** The reference implementation toolkit.
*   **`/examples`:** Working examples for each pattern.
*   **`CONTRIBUTING.md`:** This is crucial. Defining a process for others to propose new patterns, providing a template and criteria for acceptance, allows the guide to grow beyond the initial work.

---
