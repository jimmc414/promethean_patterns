# Idea Consultant - Recursive Inquisitor Example

This is a complete, working implementation of the Recursive Inquisitor pattern. It demonstrates how to transform a vague startup idea into a comprehensive business plan through intelligent, iterative questioning.

## What It Does

The Idea Consultant acts as an expert startup advisor that:
- Analyzes your initial idea to identify weak or missing elements
- Asks targeted questions to fill knowledge gaps
- Maintains a coherent vision across all aspects of your business
- Knows when to stop (when the idea is sufficiently refined)
- Produces a structured business pitch as output

## How to Run

### Prerequisites
- Bash shell
- Claude CLI (`claude` command available)
- `jq` for JSON processing

### Basic Usage
```bash
# Make the script executable
chmod +x idea_consultant.sh

# Run the consultant
./idea_consultant.sh
```

### Environment Variables
```bash
# Use a different LLM command
LLM_COMMAND="openai -p" ./idea_consultant.sh

# Or set it globally
export LLM_COMMAND="gpt-4 -p"
./idea_consultant.sh
```

## Example Session

```
╔═══════════════════════════════════════════╗
║   Startup Idea Consultant - Promethean    ║
║   Recursive Inquisitor Pattern Demo       ║
╚═══════════════════════════════════════════╝

What's your startup idea? (Be as vague or specific as you like)
> I want to make an app for dog owners

═══ Current Idea Canvas ═══
PROBLEM        : empty [empty]
SOLUTION       : empty [empty]
TARGET_AUDIENC : empty [empty]
UNIQUE_VALUE   : empty [empty]
MONETIZATION   : empty [empty]
COMPETITION    : empty [empty]
═════════════════════════

❓ What specific problem do dog owners face that your app would solve?
> Finding safe places to let their dogs play off-leash

[... continues with targeted questions ...]
```

## How It Works

### 1. State Management
The consultant maintains a structured "idea canvas" with six key elements:
- **Problem**: The specific problem being solved
- **Solution**: How the app solves it
- **Target Audience**: Who will use it
- **Unique Value**: What makes it special
- **Monetization**: How it makes money
- **Competition**: Market landscape

### 2. Intelligent Questioning
The LLM analyzes the canvas at each step to:
- Identify the weakest or most critical missing element
- Consider relationships between elements
- Formulate questions that yield maximum insight
- Track overall completeness

### 3. Termination Logic
The process concludes when:
- All canvas elements are sufficiently refined
- Confidence scores average above 80%
- Maximum iterations reached (safety limit)
- The user cannot provide more detail

### 4. Structured Output
The final output includes:
- Executive summary
- Clear problem statement
- Proposed solution
- Target market analysis
- Business model
- Competitive advantage
- Actionable next steps

## Key Pattern Concepts Demonstrated

### Externalized State
All conversation memory is explicitly maintained in the JSON state object, not hidden in conversation history.

### Structured Interfaces
Communication with the LLM uses strict JSON for both prompts and responses.

### Goal-Oriented Orchestration
The system has a clear objective (refine the idea) and termination conditions, not just open-ended chat.

### Probabilistic Resilience
Includes JSON validation and retry logic for handling LLM failures.

## Customization

### Adding Canvas Elements
Modify the `STATE_TEMPLATE` to include additional fields:
```json
"technical_feasibility": {"value": null, "status": "empty", "confidence": 0},
"team_requirements": {"value": null, "status": "empty", "confidence": 0}
```

### Adjusting Question Strategy
Modify the prompt to change how questions are prioritized:
```
Consider technical risk as the highest priority when selecting questions.
```

### Changing Termination Criteria
Adjust when the consultant concludes:
```bash
# In the prompt
- Conclude when confidence scores average above 90%  # Stricter
- Conclude after minimum 5 questions  # Ensure depth
```

## Output Files

The consultant saves results as timestamped JSON files:
- `startup_idea_YYYYMMDD_HHMMSS.json` - Complete successful session
- `startup_idea_incomplete_YYYYMMDD_HHMMSS.json` - Partial results if max iterations reached

These files contain:
- Full refined state
- Complete pitch
- Analysis history
- All questions asked

## Extending This Example

### Integration Ideas
1. **Web Interface**: Build a web UI around this script
2. **Database Storage**: Save sessions to a database
3. **Multi-Stage Pipeline**: Feed output to other patterns
4. **Team Collaboration**: Allow multiple people to answer questions

### Pattern Compositions
- Use **Router** to handle different types of ideas (tech, retail, service)
- Add **Circuit Breaker** for production resilience
- Implement **Fan-Out** to get multiple advisor perspectives

## Troubleshooting

### Common Issues

**"Invalid response from consultant"**
- Check your LLM command is working: `echo "test" | claude -p "Say hello"`
- Ensure you have API access configured

**"Maximum iterations reached"**
- The idea may be too complex for the canvas
- Try starting with a more focused initial idea
- Increase MAX_ITERATIONS if needed

**JSON parsing errors**
- Ensure `jq` is installed: `which jq`
- Check for special characters in your input

## Learning Resources

- [Recursive Inquisitor Pattern Documentation](../../patterns/recursive_inquisitor.md)
- [Promethean Patterns Philosophy](../../PHILOSOPHY.md)
- [Contributing Guide](../../CONTRIBUTING.md)

## License

This example is part of the Promethean Patterns project and is released under the MIT License.