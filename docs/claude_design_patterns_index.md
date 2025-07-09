# Claude Design Patterns

A comprehensive collection of design patterns for working with Claude in non-interactive mode. These patterns have been extracted and organized from various sources to provide a structured reference for building sophisticated AI-augmented development workflows.

## Pattern Categories

### 1. [JSON Output Pattern](json_output_pattern.md)
The fundamental pattern for getting structured, machine-readable responses from Claude. Learn how to use JSON schemas to control Claude's output format and enable reliable parsing.

### 2. [Stream Processing Patterns](stream_processing_pattern.md)
Patterns for continuous data flow through Claude instances, including real-time analysis, log monitoring, and handling high-volume streams.

### 3. [Pipeline Architecture Patterns](pipeline_architecture_patterns.md)
Complex workflows using linear pipelines, fan-out/fan-in, map-reduce, and other architectural patterns for chaining Claude instances.

### 4. [Advanced Composition Patterns](advanced_composition_patterns.md)
Sophisticated multi-Claude architectures including:
- State Machines
- Event-Driven Architectures
- Actor Models
- Saga Patterns
- Hierarchical Task Networks
- Blackboard Systems

### 5. [Specialized Agent Patterns](specialized_agent_patterns.md)
Creating Claude instances with specific roles:
- Conversational Agents
- Self-Healing Systems
- Code Generation Pipelines
- Documentation Systems
- Refactoring Assistants
- Learning Systems

### 6. [Control Flow and Utility Patterns](control_flow_utility_patterns.md)
Managing execution flow and resources:
- Conditional Execution
- Circuit Breakers
- Rate Limiting
- Error Recovery
- Resource Management
- Monitoring and Observability

### 7. [Claude Command Patterns](claude_command_patterns.md)
Understanding Claude's pattern recognition for various command types:
- Output/Formatting Commands
- Transformation Commands
- Analysis Commands
- Behavioral Commands
- Control Flow Commands
- Generation Commands

### 8. [Recursive and Self-Directed Patterns](recursive_self_directed_patterns.md)
Patterns where Claude controls its own execution:
- Self-Directed Workflows
- Recursive Analysis
- Multi-Agent Recursion
- Code Archaeology
- AST-Based Analysis

### 9. [Session Management Patterns](session_management_patterns.md)
Maintaining context across multiple Claude invocations:
- Basic Session Management
- Persistent Storage
- Multi-Line Input Handling
- Branching Sessions
- Windowed Context

### 10. [Bash Integration Patterns](bash_integration_patterns.md)
Advanced shell scripting with Claude:
- Pipeline Operators
- Process Substitution
- Parallel Processing
- Error Handling
- Shell Functions
- Unix Tool Integration

### 11. [Real-World Examples](real_world_examples.md)
Production-ready implementations:
- CI/CD Pipeline Automation
- Documentation Generation Systems
- Intelligent Log Analysis
- Deployment Safety Checkers

## Quick Start

### Basic JSON Output
```bash
claude -p "Analyze this code. Output JSON: {bugs: [], suggestions: []}" < code.py
```

### Simple Pipeline
```bash
cat logs.txt | claude -p "Extract errors" | claude -p "Group by type" | jq '.groups'
```

### Session Management
```bash
SESSION_ID=$(uuidgen)
claude -p "Session: $SESSION_ID. Start code review"
claude -p "Session: $SESSION_ID. Focus on security issues"
```

## Best Practices

1. **Always use structured output** - JSON format ensures reliable parsing
2. **Design for failure** - Include error handling and fallbacks
3. **Monitor resource usage** - Track tokens and API calls
4. **Version your prompts** - Treat prompts as code
5. **Test compositions** - Verify multi-Claude systems work as expected
6. **Document patterns** - Keep track of what works for your use case
7. **Use sessions wisely** - Maintain context without sending full history
8. **Cache when possible** - Avoid redundant API calls
9. **Set clear boundaries** - Use timeouts and resource limits
10. **Evolve patterns** - Continuously improve based on results

## Pattern Selection Guide

- **Need structured data?** → Start with [JSON Output Pattern](json_output_pattern.md)
- **Processing streams?** → See [Stream Processing Patterns](stream_processing_pattern.md)
- **Complex workflow?** → Check [Pipeline Architecture Patterns](pipeline_architecture_patterns.md)
- **Multiple agents?** → Review [Advanced Composition Patterns](advanced_composition_patterns.md)
- **Specific task?** → Look at [Specialized Agent Patterns](specialized_agent_patterns.md)
- **Bash automation?** → Study [Bash Integration Patterns](bash_integration_patterns.md)

## Contributing

These patterns are extracted from real-world usage. If you have patterns that have worked well for you, please consider contributing them to help the community.

## License

These patterns are provided as reference implementations. Adapt them to your specific needs and requirements.