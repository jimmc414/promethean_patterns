# Adaptive Documentation Builder

An intelligent, conversation-driven documentation builder powered by Claude that specializes in creating llms.txt files and DSPy documentation.

## Overview

This tool adapts the elegant state-machine approach from `idea_consultant.sh` to guide users through creating high-quality, LLM-friendly documentation. Instead of hard-coding every interaction, it leverages Claude's natural abilities to:

- Understand what type of documentation is needed
- Ask intelligent, context-aware questions
- Build documentation incrementally
- Adapt to different project types and domains

## Features

### 1. **Multiple Documentation Types**
- **llms.txt** - Standard format for LLM-friendly project documentation
- **DSPy Tutorials** - Step-by-step guides for DSPy concepts
- **Module Documentation** - Document custom DSPy modules and signatures
- **Application Examples** - Complete DSPy applications with explanations
- **Custom Documentation** - Flexible support for other needs

### 2. **Adaptive Questioning**
The system doesn't follow a rigid script. Instead, it:
- Detects the type of project (library, application, framework)
- Asks questions that reveal the essence of the project
- Adapts follow-up questions based on previous answers
- Shows progress and explains why each question matters

### 3. **State-Driven Architecture**
Every interaction maintains a complete state including:
```json
{
  "project_canvas": {
    "project_name": {"value": "...", "status": "complete"},
    "architecture": {"value": "...", "status": "partial"},
    // ... other project aspects
  },
  "documentation_sections": {
    "overview": {"content": "...", "status": "draft"},
    // ... other sections
  }
}
```

### 4. **Intelligent Features**
- **Preview Generation**: See sections as they're built
- **Resource Fetching**: Can reference DSPy docs when needed
- **Quality Tracking**: Ensures all important aspects are covered
- **Flexible Output**: Supports multiple formats (markdown, plaintext, JSON)

## Usage

```bash
# Make the script executable
chmod +x llms_txt_builder.sh

# Run the builder
./llms_txt_builder.sh
```

### Example Session Flow

1. **Initial Input**
   ```
   User: I want to document my DSPy RAG application
   ```

2. **Adaptive Response**
   - Detects this is a DSPy application
   - Asks about the specific RAG implementation
   - Inquires about signatures and modules used
   - Gathers usage examples

3. **Progressive Building**
   - Shows preview of each section
   - Allows editing and refinement
   - Builds comprehensive documentation

4. **Final Output**
   - Complete llms.txt file
   - Usage instructions
   - Session history for reference

## How It Works

### 1. **Single Prompt Design**
The entire system runs on one sophisticated prompt that enables Claude to:
- Understand documentation standards
- Ask domain-appropriate questions
- Generate high-quality content
- Maintain conversation state

### 2. **JSON State Machine**
Each interaction:
```bash
Current State → Claude → Response JSON → Update State → Next Interaction
```

### 3. **Dynamic Adaptation**
The system doesn't hard-code question flows. Instead:
- Questions emerge from understanding the project
- Each question builds on previous knowledge
- The path to completion is discovered, not prescribed

## Key Design Principles

### 1. **Freedom Within Structure**
- Clear goal (create documentation)
- Flexible path to achieve it
- Claude determines the best questions to ask

### 2. **State as Memory**
- Complete conversation history
- Project understanding canvas
- Documentation sections tracking

### 3. **User-Centric Design**
- Shows reasoning for each question
- Provides examples when helpful
- Allows preview and editing

### 4. **Leverage LLM Strengths**
- Natural language understanding
- Context-aware questioning
- Domain knowledge application

## Comparison with Hard-Coded Approach

### Traditional Approach
```python
# Fixed sequence of questions
questions = [
    "What is your project name?",
    "What does it do?",
    "What are the main features?",
    # ... rigid list
]
```

### This Approach
```json
{
  "question_for_user": {
    "context": "I see you're building a RAG system with DSPy",
    "question": "How does your retrieval component work? Do you use dense retrieval, sparse retrieval, or a hybrid approach?",
    "why_asking": "Understanding the retrieval strategy helps document the architecture and performance characteristics"
  }
}
```

## Advanced Features

### 1. **Domain Detection**
Automatically identifies:
- DSPy applications vs general projects
- Library vs application vs framework
- Technical depth needed

### 2. **Progressive Disclosure**
- Starts with high-level understanding
- Dives deeper based on project complexity
- Skips irrelevant questions

### 3. **Quality Assurance**
- Tracks completion status of each section
- Ensures comprehensive coverage
- Validates against documentation standards

## Extending the Builder

The system can be extended by modifying the main prompt to:
- Support new documentation formats
- Add domain-specific knowledge
- Include additional quality checks
- Integrate with external resources

## Why This Design?

1. **Flexibility**: Adapts to any project without code changes
2. **Intelligence**: Leverages Claude's understanding, not just templates
3. **Maintainability**: One prompt to update vs. complex logic
4. **User Experience**: Natural conversation vs. rigid forms
5. **Completeness**: Discovers what's important vs. assuming

## Requirements

- Bash shell
- Python 3 (for JSON processing)
- Claude CLI tool
- No other dependencies!

## Future Enhancements

- Direct GitHub integration
- Multiple documentation format support
- Team collaboration features
- Documentation versioning
- Auto-update capabilities

---

This builder demonstrates how to create sophisticated tools that leverage LLM intelligence rather than constraining it, resulting in more adaptive and effective solutions.