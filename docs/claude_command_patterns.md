# Claude Command Patterns (Verbs and Instructions)

## Overview

Claude recognizes specific command patterns and verbs that trigger particular behaviors. Understanding these patterns helps create more effective prompts.

## Output/Formatting Commands

### Output JSON
```bash
claude -p "Analyze file. Output JSON: {analysis: str, issues: []}"
```
Claude understands this as an instruction to format response as JSON.

### Return as
```bash
claude -p "Analyze code. Return as: YAML"
claude -p "Summarize document. Return as: bullet points"
claude -p "Extract data. Return as: CSV"
```

### Format as
```bash
claude -p "Explain concept. Format as: ELI5"
claude -p "Document API. Format as: OpenAPI spec"
claude -p "Create test. Format as: pytest"
```

## Transformation Commands

### Convert to
```bash
claude -p "Convert to TypeScript"
claude -p "Convert to functional style"
claude -p "Convert to async/await pattern"
```

### Transform into
```bash
claude -p "Transform into class-based design"
claude -p "Transform into REST API"
claude -p "Transform into microservices"
```

### Rewrite as
```bash
claude -p "Rewrite as list comprehension"
claude -p "Rewrite as generator"
claude -p "Rewrite as recursive function"
```

## Analysis Commands

### Extract
```bash
claude -p "Extract function signatures"
claude -p "Extract business logic"
claude -p "Extract test cases from comments"
```

### Identify
```bash
claude -p "Identify security vulnerabilities"
claude -p "Identify performance bottlenecks"
claude -p "Identify code smells"
```

### Detect
```bash
claude -p "Detect circular dependencies"
claude -p "Detect memory leaks"
claude -p "Detect race conditions"
```

### Find
```bash
claude -p "Find all API endpoints"
claude -p "Find hardcoded values"
claude -p "Find duplicate code"
```

## Behavioral Commands

### Act as
```bash
claude -p "Act as a Python REPL"
claude -p "Act as a SQL query optimizer"
claude -p "Act as a code reviewer"
```

### Behave like
```bash
claude -p "Behave like a strict linter"
claude -p "Behave like a patient teacher"
claude -p "Behave like a security auditor"
```

### Simulate
```bash
claude -p "Simulate user interactions"
claude -p "Simulate API responses"
claude -p "Simulate error conditions"
```

### Respond as
```bash
claude -p "Respond as a REST API would"
claude -p "Respond as a database would"
claude -p "Respond as a compiler would"
```

## Control Flow Commands

### Decide
```bash
claude -p "Decide: should we cache this? Output JSON: {cache: bool, ttl: int}"
claude -p "Decide next action based on: {error_count: int, time_elapsed: float}"
```

### Choose
```bash
claude -p "Choose best algorithm for this data size"
claude -p "Choose appropriate data structure"
claude -p "Choose optimization strategy"
```

### Determine
```bash
claude -p "Determine if refactoring needed"
claude -p "Determine root cause of error"
claude -p "Determine test coverage gaps"
```

### Evaluate
```bash
claude -p "Evaluate code quality. Score 1-10"
claude -p "Evaluate security posture"
claude -p "Evaluate performance impact"
```

## Listing Commands

### List
```bash
claude -p "List all dependencies"
claude -p "List potential improvements"
claude -p "List breaking changes"
```

### Enumerate
```bash
claude -p "Enumerate test cases"
claude -p "Enumerate error scenarios"
claude -p "Enumerate API endpoints"
```

### Itemize
```bash
claude -p "Itemize refactoring steps"
claude -p "Itemize deployment tasks"
claude -p "Itemize security concerns"
```

### Catalog
```bash
claude -p "Catalog all functions by category"
claude -p "Catalog external API calls"
claude -p "Catalog database queries"
```

## Generation Commands

### Generate
```bash
claude -p "Generate unit tests"
claude -p "Generate API documentation"
claude -p "Generate mock data"
```

### Create
```bash
claude -p "Create factory functions"
claude -p "Create migration script"
claude -p "Create CI/CD pipeline"
```

### Produce
```bash
claude -p "Produce OpenAPI spec"
claude -p "Produce ER diagram"
claude -p "Produce test fixtures"
```

### Build
```bash
claude -p "Build regex pattern for validation"
claude -p "Build SQL query"
claude -p "Build class hierarchy"
```

## Iteration Commands

### For each
```bash
claude -p "For each function, generate a test"
claude -p "For each endpoint, create documentation"
claude -p "For each class, analyze complexity"
```

### Per line
```bash
claude -p "Per line: extract variables"
claude -p "Per line: check syntax"
claude -p "Per line: add type hints"
```

### Stream
```bash
claude -p "Stream process each record"
claude -p "Stream transform log entries"
claude -p "Stream validate data"
```

### Process
```bash
claude -p "Process in batches of 10"
claude -p "Process recursively"
claude -p "Process in parallel"
```

## Constraint Commands

### Only output
```bash
claude -p "Only output the fixed code"
claude -p "Only output JSON, no explanation"
claude -p "Only output test names"
```

### Limit to
```bash
claude -p "Limit to 5 suggestions"
claude -p "Limit to critical issues"
claude -p "Limit to public methods"
```

### Restrict response to
```bash
claude -p "Restrict response to yes/no"
claude -p "Restrict response to numeric score"
claude -p "Restrict response to valid JSON"
```

### Must include
```bash
claude -p "Must include error handling"
claude -p "Must include type annotations"
claude -p "Must include docstrings"
```

## Protocol Commands

### Follow protocol
```bash
claude -p "Follow protocol: {request: str} -> {response: str, status: int}"
claude -p "Follow protocol: REST API conventions"
claude -p "Follow protocol: GraphQL schema"
```

### Implement interface
```bash
claude -p "Implement interface: Iterator"
claude -p "Implement interface: Comparable"
claude -p "Implement interface: Serializable"
```

### Adhere to
```bash
claude -p "Adhere to PEP-8"
claude -p "Adhere to semantic versioning"
claude -p "Adhere to REST principles"
```

### Conform to
```bash
claude -p "Conform to company style guide"
claude -p "Conform to API specification"
claude -p "Conform to security standards"
```

## Combination Patterns

### Multi-verb Instructions
```bash
claude -p "Analyze and refactor this code. Output JSON: {analysis: str, refactored_code: str}"
claude -p "Detect issues and generate fixes. For each issue, create a patch"
claude -p "Extract patterns and build abstractions. Return as class definitions"
```

### Conditional Instructions
```bash
claude -p "If error found, explain and fix. Otherwise, optimize for performance"
claude -p "If complexity > 10, refactor. Else, add tests"
claude -p "If deprecated APIs used, modernize. Else, improve documentation"
```

### Sequential Instructions
```bash
claude -p "First analyze, then refactor, finally generate tests"
claude -p "1. Identify patterns 2. Extract to functions 3. Create interfaces"
claude -p "Step 1: Validate. Step 2: Transform. Step 3: Output results"
```

## Advanced Patterns

### Meta-instructions
```bash
claude -p "Think step-by-step. Show reasoning. Output conclusion as JSON"
claude -p "Consider edge cases. Be exhaustive. Prioritize by impact"
claude -p "Assume production environment. Be conservative. Explain risks"
```

### Role-based Instructions
```bash
claude -p "As a security expert: audit this code"
claude -p "As a performance engineer: optimize this algorithm"
claude -p "As a beginner: explain this concept"
```

### Context-setting Instructions
```bash
claude -p "Given a microservices architecture: design the service"
claude -p "In a high-traffic scenario: suggest caching strategy"
claude -p "For a startup with limited resources: prioritize features"
```

## Understanding Claude's Pattern Recognition

Claude recognizes these patterns through:

1. **Verb Recognition**: Specific action words trigger behavioral modes
2. **Structure Patterns**: JSON, lists, and other structures are recognized
3. **Domain Keywords**: Technical terms activate specialized knowledge
4. **Instruction Markers**: Words like "must", "only", "limit" set constraints
5. **Role Indicators**: "As a", "Act as", "Behave like" activate personas

## Best Practices

1. **Be explicit** - Clear verbs produce predictable behavior
2. **Use structure** - JSON/format specifications guide output
3. **Combine wisely** - Multi-verb instructions should be logical
4. **Set constraints** - Use limiting words to focus output
5. **Specify format** - Tell Claude exactly how to structure response
6. **Use domain language** - Technical terms activate specialized knowledge
7. **Layer instructions** - Build complex behaviors from simple commands
8. **Test patterns** - Verify Claude interprets instructions as intended
9. **Document patterns** - Keep track of effective command combinations
10. **Iterate on prompts** - Refine based on Claude's responses