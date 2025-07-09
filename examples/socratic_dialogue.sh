#!/bin/bash

# socratic_dialogue.sh
# True Socratic Dialogue Partner powered by Claude

# --- Color Definitions for better UI ---
C_PROMPT='\033[1;36m' # Cyan for Claude's prompts
C_USER='\033[1;32m'   # Green for User input
C_INFO='\033[0;33m'   # Yellow for info/reasoning
C_ERROR='\033[0;31m'  # Red for errors
C_RESET='\033[0m'     # Reset color

# The Socratic dialogue prompt
read -r -d '' PROMPT << 'EOF'
You are a skilled practitioner of the Socratic method. Your goal is to help users examine their beliefs, assumptions, and understanding through authentic Socratic questioning.

The TRUE spirit of Socratic questioning:
- You genuinely don't know the answers - you explore together with the questioner
- Questions arise from sincere curiosity about contradictions or gaps in reasoning
- You never lead to predetermined conclusions
- The goal is to reveal what neither party knew they didn't know
- Embrace aporia (productive puzzlement) as a valuable state
- Focus on examining definitions, assumptions, and logical consistency

You will be given a JSON object representing the entire conversation state. Your task is to:

1. **Identify the Domain**: Understand what area of knowledge or belief they want to examine.

2. **Find the Starting Point**: Locate their initial claim, belief, or assumption to examine.

3. **Practice Genuine Inquiry**: Ask questions that:
   - Expose hidden assumptions
   - Reveal contradictions in reasoning
   - Challenge definitions and certainties
   - Lead to deeper uncertainty and wonder
   - Never push toward a specific answer

4. **Track the Dialogue**: Maintain awareness of the logical thread and contradictions revealed.

5. **Recognize Aporia**: When you've reached a state of productive puzzlement where both parties realize the complexity of what seemed simple.

You MUST respond ONLY with a single JSON object. Do not add any conversational text outside of the JSON. Do not wrap the JSON in markdown code blocks.

Output structure:
{
  "domain_of_inquiry": "ethics|knowledge|politics|aesthetics|metaphysics|logic|custom",
  "dialogue_stage": "opening|examining|deepening|approaching_aporia|aporia_reached",
  
  "next_action": "ask" or "conclude",
  
  "socratic_question": {
    "dialogue_context": "Brief note on where we are in the examination.",
    "question_text": "The Socratic question to pose next.",
    "question_intent": "What assumption or contradiction this question aims to examine."
  },
  (Include socratic_question ONLY if next_action is "ask")
  
  "dialogue_summary": {
    "title": "On the Nature of [Topic Examined]",
    "journey_summary": "A philosophical summary of the journey of inquiry taken together.",
    "assumptions_examined": ["List of key assumptions that were questioned"],
    "contradictions_revealed": ["List of contradictions or paradoxes uncovered"],
    "remaining_puzzles": ["Questions that remain open and puzzling"],
    "wisdom_gained": "Not answers, but a description of what we learned we don't know"
  },
  (Include dialogue_summary ONLY if next_action is "conclude")
  
  "updated_state": {
    "user_response_for_this_turn": null,
    "conversation_history": ["array of previous Q&A pairs"],
    "examination_map": {
      "initial_position": {"claim": "string or null", "confidence": "high|medium|low|abandoned"},
      "definitions_examined": {"concepts": ["array of key concepts"], "status": "unclear|evolving|contradictory"},
      "assumptions_revealed": {"list": ["array of assumptions"], "examined": true},
      "logical_threads": {"main_thread": "string or null", "contradictions": ["array"]},
      "current_understanding": {"description": "string or null", "certainty": "certain|uncertain|puzzled"}
    },
    "socratic_notes": ["array of philosophical observations about the dialogue's progression"]
  }
}

IMPORTANT Socratic Principles:
- NEVER teach or inform - only examine through questions
- Show genuine puzzlement when contradictions arise
- Celebrate uncertainty as the beginning of wisdom
- Ask ONE focused question at a time
- Questions should feel like natural curiosity, not cross-examination
- When the user makes a claim, examine it - don't accept or reject it
- Focus on "What do you mean by X?" and "How does that follow?"
- Admit your own ignorance freely and authentically
- The goal is mutual discovery, not proving the user wrong
- Embrace not knowing as a philosophical stance
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

# 1. GET THE INITIAL INPUT
clear
echo -e "${C_PROMPT}🏛️ Welcome to Socratic Dialogue${C_RESET}"
echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_INFO}Like Socrates, I know that I know nothing. Let us examine ideas together"
echo -e "through questioning, and see what wisdom emerges from our mutual ignorance."
echo ""
echo -e "The goal is not to reach answers, but to understand our questions better.${C_RESET}"
echo ""
echo -e "${C_PROMPT}What belief, concept, or area of knowledge would you like to examine together?${C_RESET}"
echo -e "${C_USER}(Share a topic, belief, or claim you'd like to explore philosophically)${C_RESET}"
echo -n -e "${C_USER}➤ ${C_RESET}"
read -r INITIAL_INPUT

# Validate input
if [ -z "$INITIAL_INPUT" ]; then
    echo -e "${C_ERROR}No input provided. Exiting...${C_RESET}"
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
    'examination_map': {
        'initial_position': {'claim': None, 'confidence': 'high'},
        'definitions_examined': {'concepts': [], 'status': 'unclear'},
        'assumptions_revealed': {'list': [], 'examined': False},
        'logical_threads': {'main_thread': None, 'contradictions': []},
        'current_understanding': {'description': None, 'certainty': 'certain'}
    },
    'socratic_notes': []
}

print(json.dumps(initial_state))
")

# Counter for questions
QUESTION_COUNT=0
STAGE="opening"

# 3. THE RECURSIVE LOOP
while true; do
    # Call Claude with the current state, get its JSON response
    echo -e "\n${C_INFO}[Contemplating the philosophical implications...]${C_RESET}"
    CLAUDE_RESPONSE=$(echo "$STATE" | claude -p "$PROMPT")
    
    # Extract JSON from potential markdown wrapper
    CLEANED_RESPONSE=$(extract_json "$CLAUDE_RESPONSE")
    
    # Basic validation
    if ! echo "$CLEANED_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
        echo -e "${C_ERROR}🔥 Error processing response. Aborting.${C_RESET}"
        echo -e "${C_ERROR}Raw response: $CLAUDE_RESPONSE${C_RESET}"
        exit 1
    fi
    
    # Extract domain and stage
    DOMAIN=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('domain_of_inquiry', 'unknown'))" 2>/dev/null || echo "unknown")
    NEW_STAGE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('dialogue_stage', 'unknown'))" 2>/dev/null || echo "unknown")
    
    if [ "$NEW_STAGE" != "$STAGE" ]; then
        STAGE="$NEW_STAGE"
        echo -e "\n${C_INFO}📜 Dialogue stage: ${STAGE}${C_RESET}"
        if [ "$DOMAIN" != "unknown" ]; then
            echo -e "${C_INFO}🏛️ Domain of inquiry: ${DOMAIN}${C_RESET}"
        fi
    fi
    
    # Extract next action
    NEXT_ACTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('next_action', ''))")
    
    if [ "$NEXT_ACTION" = "ask" ]; then
        QUESTION_COUNT=$((QUESTION_COUNT + 1))
        
        # Extract the question and reasoning from Claude's response
        CONTEXT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('socratic_question', {}).get('dialogue_context', ''))")
        QUESTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('socratic_question', {}).get('question_text', ''))")
        INTENT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('socratic_question', {}).get('question_intent', ''))")
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_INFO}💭 ${CONTEXT}${C_RESET}"
        echo -e "${C_INFO}🔍 (Examining: ${INTENT})${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}❓ ${QUESTION}${C_RESET}"
        echo ""
        echo -e "${C_USER}(Take your time to think. There are no wrong answers in philosophy.)${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r USER_ANSWER
        
        # Prepare the state for the NEXT iteration
        STATE=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json
import sys

data = json.load(sys.stdin)
user_answer = '''$USER_ANSWER'''

# Update the state with the user's answer
data['updated_state']['user_response_for_this_turn'] = user_answer

print(json.dumps(data['updated_state']))
")
        
    elif [ "$NEXT_ACTION" = "conclude" ]; then
        # Extract the dialogue summary
        TITLE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('dialogue_summary', {}).get('title', ''))")
        JOURNEY=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('dialogue_summary', {}).get('journey_summary', ''))")
        WISDOM=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('dialogue_summary', {}).get('wisdom_gained', ''))")
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_PROMPT}🏛️ ${TITLE}${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "${C_INFO}Our Journey of Inquiry:${C_RESET}"
        echo -e "$JOURNEY"
        echo ""
        
        # Extract and display assumptions examined
        echo -e "${C_PROMPT}🤔 Assumptions We Examined:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
assumptions = data.get('dialogue_summary', {}).get('assumptions_examined', [])
for i, assumption in enumerate(assumptions, 1):
    print(f'   {i}. {assumption}')
"
        echo ""
        
        # Extract and display contradictions
        echo -e "${C_PROMPT}⚡ Contradictions Revealed:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
contradictions = data.get('dialogue_summary', {}).get('contradictions_revealed', [])
for contradiction in contradictions:
    print(f'   • {contradiction}')
"
        echo ""
        
        # Extract and display remaining puzzles
        echo -e "${C_PROMPT}❓ Questions That Remain:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
puzzles = data.get('dialogue_summary', {}).get('remaining_puzzles', [])
for puzzle in puzzles:
    print(f'   • {puzzle}')
"
        echo ""
        
        # Display wisdom gained
        echo -e "${C_PROMPT}🦉 Wisdom Gained:${C_RESET}"
        echo -e "$WISDOM"
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_INFO}\"The only true wisdom is in knowing you know nothing.\" - Socrates${C_RESET}"
        echo ""
        echo -e "${C_INFO}Thank you for this philosophical journey. May your questions continue to deepen.${C_RESET}"
        
        # Save the dialogue
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        FILENAME="socratic_dialogue_${DOMAIN}_${TIMESTAMP}.json"
        echo "$CLEANED_RESPONSE" > "$FILENAME"
        echo ""
        echo -e "${C_INFO}This dialogue has been preserved in: ${FILENAME}${C_RESET}"
        echo -e "${C_INFO}Questions explored: ${QUESTION_COUNT} | Final state: ${STAGE}${C_RESET}"
        
        break # Exit the loop
    else
        echo -e "${C_ERROR}🔥 Unknown action: '$NEXT_ACTION'. Aborting.${C_RESET}"
        exit 1
    fi
done