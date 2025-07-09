#!/bin/bash

# dspy_teacher.sh
# Interactive DSPy Teacher - Learn by Building
# Teaches DSPy concepts through hands-on solution development

# --- Color Definitions for better UI ---
C_PROMPT='\033[1;36m' # Cyan for Teacher's prompts
C_USER='\033[1;32m'   # Green for User input
C_INFO='\033[0;33m'   # Yellow for explanations
C_CODE='\033[0;35m'   # Magenta for code
C_ERROR='\033[0;31m'  # Red for errors
C_RESET='\033[0m'     # Reset color

# Create session directory
SESSION_DIR="dspy_sessions/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$SESSION_DIR"
SESSION_LOG="$SESSION_DIR/session.log"
CODE_FILE="$SESSION_DIR/solution.py"

# Function to log to file and display
log_both() {
    echo -e "$1" | tee -a "$SESSION_LOG"
}

# The DSPy teacher prompt
read -r -d '' PROMPT << 'EOF'
You are an expert DSPy teacher who helps users learn by building real solutions together. Your teaching style is hands-on, patient, and explanatory.

You will be given a JSON object representing the entire conversation state. Your task is to:

1. **Understand Learning Goals**: Determine what aspect of DSPy the user wants to learn or what problem they want to solve

2. **Teach Through Building**: Guide them through building a real DSPy solution while explaining concepts as you go

3. **Adapt to Their Level**: Gauge their experience and adjust explanations accordingly

4. **Provide Working Code**: Give them runnable code snippets they can experiment with

5. **Explain Why**: Always explain not just what to do, but why it's the DSPy way

You MUST respond ONLY with a single JSON object. Do not add any conversational text outside of the JSON.

Output structure:
{
  "learning_topic": "signatures|modules|optimization|retrieval|evaluation|composition|custom",
  "user_level": "beginner|intermediate|advanced",
  "current_phase": "exploring|designing|implementing|optimizing|complete",
  
  "next_action": "teach_concept" | "show_code" | "ask_clarification" | "provide_exercise" | "summarize_learning",
  
  "teaching_content": {
    "concept_name": "The DSPy concept being taught",
    "explanation": "Clear explanation of the concept",
    "why_important": "Why this matters in DSPy",
    "simple_analogy": "An analogy to help understanding",
    "connection_to_solution": "How this applies to what we're building"
  },
  (Include teaching_content when next_action is "teach_concept")
  
  "code_demonstration": {
    "description": "What this code demonstrates",
    "code": "Complete, runnable Python code",
    "key_points": ["List of important things to notice in the code"],
    "try_next": "Suggestion for user experimentation"
  },
  (Include code_demonstration when next_action is "show_code")
  
  "clarification_request": {
    "context": "What we need to understand better",
    "question": "Specific question for the user",
    "options": ["Possible options if applicable"]
  },
  (Include clarification_request when next_action is "ask_clarification")
  
  "practice_exercise": {
    "task": "What the user should try to build",
    "hints": ["Helpful hints without giving away the answer"],
    "starter_code": "Code skeleton to get them started",
    "learning_objective": "What they'll learn by doing this"
  },
  (Include practice_exercise when next_action is "provide_exercise")
  
  "learning_summary": {
    "concepts_covered": ["List of DSPy concepts learned"],
    "solution_built": "Description of what was built",
    "complete_code": "Full working solution with comments",
    "next_steps": ["Suggestions for continued learning"],
    "resources": ["Helpful resources and documentation"]
  },
  (Include learning_summary when next_action is "summarize_learning")
  
  "updated_state": {
    "user_response_for_this_turn": null,
    "conversation_history": ["array of previous interactions"],
    "learning_journey": {
      "main_goal": {"value": "string or null", "status": "unclear|defined|achieved"},
      "concepts_understood": ["array of mastered concepts"],
      "concepts_in_progress": ["array of concepts being learned"],
      "code_snippets": ["array of code we've written together"],
      "questions_asked": ["array of user questions"],
      "insights_gained": ["array of aha moments"]
    },
    "solution_progress": {
      "problem_statement": "What we're building",
      "current_implementation": "Current state of our code",
      "dspy_patterns_used": ["Signatures", "Modules", "etc"],
      "next_implementation_step": "What to build next"
    },
    "teacher_notes": ["Internal notes about teaching strategy"]
  }
}

Teaching Principles:
1. Start with concrete examples, then explain the theory
2. Build incrementally - each step should work and demonstrate something
3. Connect DSPy concepts to familiar programming patterns
4. Encourage experimentation and questions
5. Celebrate small wins and "aha" moments
6. Show multiple ways to solve problems with DSPy
7. Emphasize DSPy's core philosophy: "Programming, not prompting"

Focus Areas You Can Teach:
- Signatures: Input/output contracts for LLMs
- Modules: ChainOfThought, Predict, ReAct, ProgramOfThought
- Composition: Building complex systems from simple parts
- Optimization: BootstrapFewShot, MIPROv2, and metrics
- Retrieval: RAG patterns with DSPy
- Evaluation: Building metrics and evaluation pipelines
- Advanced: Custom modules, assertions, and teleprompters
EOF

# Function to extract JSON from potential markdown wrapper
extract_json() {
    local response="$1"
    if [[ "$response" == *'```json'* ]]; then
        echo "$response" | sed -n '/```json/,/```/p' | sed '1d;$d'
    else
        echo "$response"
    fi
}

# Function to display code nicely
show_code() {
    local code="$1"
    echo -e "${C_CODE}$code${C_RESET}"
}

# 1. WELCOME MESSAGE
clear
log_both "${C_PROMPT}🎓 Welcome to the Interactive DSPy Teacher!${C_RESET}"
log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
log_both "${C_INFO}I'll help you learn DSPy by building something real together!"
log_both ""
log_both "We can explore:"
log_both "  • Signatures and structured I/O"
log_both "  • Reasoning modules (ChainOfThought, ReAct, etc.)"
log_both "  • Building RAG applications"
log_both "  • Optimization and few-shot learning"
log_both "  • Creating custom DSPy modules"
log_both ""
log_both "Session files will be saved to: $SESSION_DIR${C_RESET}"
log_both ""
log_both "${C_PROMPT}What would you like to learn or build with DSPy today?${C_RESET}"
log_both "${C_USER}(Describe your learning goal or a problem you want to solve)${C_RESET}"
echo -n -e "${C_USER}➤ ${C_RESET}"
read -r INITIAL_INPUT

# Log user input
echo "➤ $INITIAL_INPUT" >> "$SESSION_LOG"

# Validate input
if [ -z "$INITIAL_INPUT" ]; then
    log_both "${C_ERROR}No input provided. Exiting...${C_RESET}"
    exit 1
fi

# 2. INITIALIZE THE STATE
STATE=$(python3 -c "
import json
import sys

initial_input = '''$INITIAL_INPUT'''

initial_state = {
    'user_response_for_this_turn': initial_input,
    'conversation_history': [],
    'learning_journey': {
        'main_goal': {'value': None, 'status': 'unclear'},
        'concepts_understood': [],
        'concepts_in_progress': [],
        'code_snippets': [],
        'questions_asked': [],
        'insights_gained': []
    },
    'solution_progress': {
        'problem_statement': None,
        'current_implementation': '',
        'dspy_patterns_used': [],
        'next_implementation_step': None
    },
    'teacher_notes': []
}

print(json.dumps(initial_state))
")

# Teaching loop variables
INTERACTION_COUNT=0
TOPIC="exploring"

# 3. THE TEACHING LOOP
while true; do
    # Call Claude with the current state
    log_both "\n${C_INFO}[Preparing teaching material...]${C_RESET}"
    CLAUDE_RESPONSE=$(echo "$STATE" | claude -p "$PROMPT" 2>&1)
    
    # Extract JSON from potential markdown wrapper
    CLEANED_RESPONSE=$(extract_json "$CLAUDE_RESPONSE")
    
    # Basic validation
    if ! echo "$CLEANED_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
        log_both "${C_ERROR}🔥 Error processing response. Let me try again...${C_RESET}"
        # Log error for debugging
        echo "ERROR: $CLAUDE_RESPONSE" >> "$SESSION_LOG"
        # Try to recover by asking Claude to reformat
        continue
    fi
    
    # Extract learning topic and phase
    TOPIC=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('learning_topic', 'unknown'))" 2>/dev/null || echo "unknown")
    PHASE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('current_phase', 'exploring'))" 2>/dev/null || echo "exploring")
    
    # Extract next action
    NEXT_ACTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('next_action', ''))")
    
    if [ "$NEXT_ACTION" = "teach_concept" ]; then
        INTERACTION_COUNT=$((INTERACTION_COUNT + 1))
        
        # Extract teaching content
        CONCEPT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('teaching_content', {}).get('concept_name', ''))")
        EXPLANATION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('teaching_content', {}).get('explanation', ''))")
        WHY=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('teaching_content', {}).get('why_important', ''))")
        ANALOGY=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('teaching_content', {}).get('simple_analogy', ''))")
        CONNECTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('teaching_content', {}).get('connection_to_solution', ''))")
        
        log_both ""
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_PROMPT}📚 Learning: $CONCEPT${C_RESET}"
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both ""
        log_both "$EXPLANATION"
        log_both ""
        log_both "${C_INFO}💡 Why this matters: $WHY${C_RESET}"
        log_both ""
        log_both "${C_INFO}🔍 Think of it like: $ANALOGY${C_RESET}"
        log_both ""
        log_both "${C_INFO}🔗 For our solution: $CONNECTION${C_RESET}"
        log_both ""
        log_both "${C_USER}Got it? (Press Enter to continue, or ask a question)${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r USER_RESPONSE
        echo "➤ $USER_RESPONSE" >> "$SESSION_LOG"
        
    elif [ "$NEXT_ACTION" = "show_code" ]; then
        # Extract code demonstration
        DESC=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('code_demonstration', {}).get('description', ''))")
        CODE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('code_demonstration', {}).get('code', ''))")
        TRY_NEXT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('code_demonstration', {}).get('try_next', ''))")
        
        log_both ""
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_PROMPT}💻 Code Example: $DESC${C_RESET}"
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both ""
        show_code "$CODE"
        
        # Save code to file
        echo "$CODE" >> "$CODE_FILE"
        echo "\n# " >> "$CODE_FILE"
        echo "# ─────────────────────────────────────────" >> "$CODE_FILE"
        echo "" >> "$CODE_FILE"
        
        log_both ""
        log_both "${C_INFO}📝 Key points:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
points = data.get('code_demonstration', {}).get('key_points', [])
for i, point in enumerate(points, 1):
    print(f'   {i}. {point}')
" | tee -a "$SESSION_LOG"
        
        log_both ""
        log_both "${C_INFO}🚀 Try this next: $TRY_NEXT${C_RESET}"
        log_both ""
        log_both "${C_USER}Ready to continue? (Press Enter, or type your thoughts/questions)${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r USER_RESPONSE
        echo "➤ $USER_RESPONSE" >> "$SESSION_LOG"
        
    elif [ "$NEXT_ACTION" = "ask_clarification" ]; then
        # Extract clarification request
        CONTEXT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('clarification_request', {}).get('context', ''))")
        QUESTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('clarification_request', {}).get('question', ''))")
        
        log_both ""
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_INFO}Context: $CONTEXT${C_RESET}"
        log_both ""
        log_both "${C_PROMPT}❓ $QUESTION${C_RESET}"
        
        # Show options if available
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
options = data.get('clarification_request', {}).get('options', [])
if options:
    print('\nOptions:')
    for i, opt in enumerate(options, 1):
        print(f'  {i}. {opt}')
" | tee -a "$SESSION_LOG"
        
        log_both ""
        log_both "${C_USER}Your answer:${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r USER_RESPONSE
        echo "➤ $USER_RESPONSE" >> "$SESSION_LOG"
        
    elif [ "$NEXT_ACTION" = "provide_exercise" ]; then
        # Extract exercise
        TASK=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('practice_exercise', {}).get('task', ''))")
        STARTER=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('practice_exercise', {}).get('starter_code', ''))")
        OBJECTIVE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('practice_exercise', {}).get('learning_objective', ''))")
        
        log_both ""
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_PROMPT}🏋️ Practice Exercise${C_RESET}"
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both ""
        log_both "${C_INFO}Task: $TASK${C_RESET}"
        log_both ""
        log_both "${C_INFO}Learning objective: $OBJECTIVE${C_RESET}"
        log_both ""
        log_both "Starter code:"
        show_code "$STARTER"
        log_both ""
        log_both "${C_INFO}Hints:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
hints = data.get('practice_exercise', {}).get('hints', [])
for i, hint in enumerate(hints, 1):
    print(f'  💡 {hint}')
" | tee -a "$SESSION_LOG"
        
        log_both ""
        log_both "${C_USER}Take your time. When ready, share your solution or ask for help:${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r USER_RESPONSE
        echo "➤ $USER_RESPONSE" >> "$SESSION_LOG"
        
    elif [ "$NEXT_ACTION" = "summarize_learning" ]; then
        # Extract summary
        CONCEPTS=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(', '.join(d.get('learning_summary', {}).get('concepts_covered', [])))")
        SOLUTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('learning_summary', {}).get('solution_built', ''))")
        COMPLETE_CODE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('learning_summary', {}).get('complete_code', ''))")
        
        log_both ""
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_PROMPT}🎉 Congratulations! Learning Session Complete${C_RESET}"
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both ""
        log_both "${C_INFO}📚 Concepts you learned: $CONCEPTS${C_RESET}"
        log_both ""
        log_both "${C_INFO}🏗️ What we built: $SOLUTION${C_RESET}"
        log_both ""
        log_both "Complete solution saved to: $CODE_FILE"
        log_both ""
        
        # Save complete code
        echo "# Complete DSPy Solution" > "$CODE_FILE"
        echo "# Generated on: $(date)" >> "$CODE_FILE"
        echo "" >> "$CODE_FILE"
        echo "$COMPLETE_CODE" >> "$CODE_FILE"
        
        log_both "${C_INFO}📚 Next steps:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
steps = data.get('learning_summary', {}).get('next_steps', [])
for i, step in enumerate(steps, 1):
    print(f'  {i}. {step}')
" | tee -a "$SESSION_LOG"
        
        log_both ""
        log_both "${C_INFO}📖 Resources:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
resources = data.get('learning_summary', {}).get('resources', [])
for resource in resources:
    print(f'  • {resource}')
" | tee -a "$SESSION_LOG"
        
        log_both ""
        log_both "${C_INFO}Session saved to: $SESSION_DIR${C_RESET}"
        log_both "${C_INFO}Topic: $TOPIC | Interactions: $INTERACTION_COUNT${C_RESET}"
        
        # Save final state
        echo "$CLEANED_RESPONSE" > "$SESSION_DIR/final_state.json"
        
        break # Exit the loop
    else
        log_both "${C_ERROR}🔥 Unknown action: '$NEXT_ACTION'. Continuing...${C_RESET}"
        USER_RESPONSE="Please continue"
    fi
    
    # Update state for next iteration
    if [ "$NEXT_ACTION" != "summarize_learning" ]; then
        STATE=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json
import sys

data = json.load(sys.stdin)
user_response = '''$USER_RESPONSE'''

# Update the state with the user's response
data['updated_state']['user_response_for_this_turn'] = user_response

print(json.dumps(data['updated_state']))
")
    fi
done

log_both ""
log_both "${C_PROMPT}Thank you for learning DSPy with me! Happy coding! 🚀${C_RESET}"