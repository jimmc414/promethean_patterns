#!/bin/bash

# problem_solver.sh
# Systematic Problem-Solving Consultant powered by Claude

# --- Color Definitions for better UI ---
C_PROMPT='\033[1;36m' # Cyan for Claude's prompts
C_USER='\033[1;32m'   # Green for User input
C_INFO='\033[0;33m'   # Yellow for info/reasoning
C_ERROR='\033[0;31m'  # Red for errors
C_RESET='\033[0m'     # Reset color

# The problem solver prompt
read -r -d '' PROMPT << 'EOF'
You are an expert problem-solving consultant specializing in systematic approaches like root cause analysis, solution brainstorming, and implementation planning. Your goal is to help users solve complex problems methodically.

You will be given a JSON object representing the entire conversation state. Your task is to:

1. **Define the Problem**: Based on the user's input, identify the problem type (technical, process, interpersonal, strategic, operational) and its scope.

2. **Build a Problem-Solving Canvas**: Create and maintain a structured framework with 5-7 key aspects:
   - Problem definition and symptoms
   - Root causes and contributing factors
   - Impact and urgency assessment
   - Constraints and resources
   - Solution criteria
   - Potential solutions
   - Implementation risks

3. **Ask Diagnostic Questions**: Always ask the single most important question to understand or solve the problem. Questions should:
   - Dig deeper into root causes
   - Clarify the problem scope and impact
   - Uncover constraints and resources
   - Test assumptions
   - Explore solution feasibility

4. **Apply Problem-Solving Tools**: Use appropriate methodologies (5 Whys, Fishbone diagram, PDCA, Six Thinking Hats) based on the problem type.

5. **Provide Solution Plan**: When sufficient information is gathered, provide a comprehensive solution with implementation steps.

You MUST respond ONLY with a single JSON object. Do not add any conversational text outside of the JSON. Do not wrap the JSON in markdown code blocks.

Output structure:
{
  "domain_detected": "technical|process|interpersonal|strategic|operational|quality|other",
  "domain_confidence": 0.0 to 1.0,
  
  "next_action": "ask" or "conclude",
  
  "question_for_user": {
    "progress_update": "A one-line summary of what has been uncovered about the problem.",
    "question_text": "The single most important question to ask the user next.",
    "question_reasoning": "A brief explanation of *why* this question helps solve the problem."
  },
  (Include question_for_user ONLY if next_action is "ask")
  
  "refined_concept": {
    "title": "Solution Plan: [Problem Title]",
    "executive_summary": "A comprehensive 3-4 paragraph solution analysis and plan.",
    "key_insights": ["List of 3-5 key findings about the problem and solution"],
    "next_steps": ["List of 3-5 concrete implementation steps with priorities"]
  },
  (Include refined_concept ONLY if next_action is "conclude")
  
  "updated_state": {
    "user_response_for_this_turn": null,
    "conversation_history": ["array of previous Q&A pairs"],
    "idea_canvas": {
      "core_concept": {"value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_1": {"name": "problem_definition", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_2": {"name": "root_causes", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_3": {"name": "impact_assessment", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_4": {"name": "constraints_resources", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_5": {"name": "solution_approach", "value": "string or null", "status": "empty|developing|refined"}
    },
    "consultant_notes": ["array of analytical notes about the problem"]
  }
}
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
echo -e "${C_PROMPT}🔧 Welcome to Your Systematic Problem Solver!${C_RESET}"
echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_INFO}I'm here to help you solve complex problems using proven methodologies."
echo -e "Through systematic analysis and strategic questioning, we'll identify root causes"
echo -e "and develop effective solutions."
echo ""
echo -e "Let's start by understanding your problem.${C_RESET}"
echo ""
echo -e "${C_PROMPT}What problem are you trying to solve?${C_RESET}"
echo -e "${C_USER}(Describe the issue you're facing and any symptoms you've noticed)${C_RESET}"
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
    'idea_canvas': {
        'core_concept': {'value': None, 'status': 'empty'},
        'key_aspect_1': {'name': 'problem_definition', 'value': None, 'status': 'empty'},
        'key_aspect_2': {'name': 'root_causes', 'value': None, 'status': 'empty'},
        'key_aspect_3': {'name': 'impact_assessment', 'value': None, 'status': 'empty'},
        'key_aspect_4': {'name': 'constraints_resources', 'value': None, 'status': 'empty'},
        'key_aspect_5': {'name': 'solution_approach', 'value': None, 'status': 'empty'}
    },
    'consultant_notes': []
}

print(json.dumps(initial_state))
")

# Counter for questions
QUESTION_COUNT=0
DOMAIN="unknown"

# 3. THE RECURSIVE LOOP
while true; do
    # Call Claude with the current state, get its JSON response
    echo -e "\n${C_INFO}[Analyzing the problem systematically...]${C_RESET}"
    CLAUDE_RESPONSE=$(echo "$STATE" | claude -p "$PROMPT")
    
    # Extract JSON from potential markdown wrapper
    CLEANED_RESPONSE=$(extract_json "$CLAUDE_RESPONSE")
    
    # Basic validation
    if ! echo "$CLEANED_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
        echo -e "${C_ERROR}🔥 Error processing response. Aborting.${C_RESET}"
        echo -e "${C_ERROR}Raw response: $CLAUDE_RESPONSE${C_RESET}"
        exit 1
    fi
    
    # Extract domain info (if available)
    NEW_DOMAIN=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('domain_detected', 'unknown'))" 2>/dev/null || echo "unknown")
    DOMAIN_CONF=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(f\"{d.get('domain_confidence', 0):.1%}\")" 2>/dev/null || echo "0%")
    
    if [ "$NEW_DOMAIN" != "unknown" ] && [ "$NEW_DOMAIN" != "$DOMAIN" ]; then
        DOMAIN="$NEW_DOMAIN"
        echo -e "\n${C_INFO}🎯 Problem type identified: ${DOMAIN} (confidence: ${DOMAIN_CONF})${C_RESET}"
    fi
    
    # Extract next action
    NEXT_ACTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('next_action', ''))")
    
    if [ "$NEXT_ACTION" = "ask" ]; then
        QUESTION_COUNT=$((QUESTION_COUNT + 1))
        
        # Extract the question and reasoning from Claude's response
        PROGRESS=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('question_for_user', {}).get('progress_update', ''))")
        QUESTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('question_for_user', {}).get('question_text', ''))")
        REASONING=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('question_for_user', {}).get('question_reasoning', ''))")
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_INFO}📊 Problem Analysis: $PROGRESS${C_RESET}"
        echo -e "${C_INFO}💭 (Why this helps: $REASONING)${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}❓ Question $QUESTION_COUNT: $QUESTION${C_RESET}"
        echo ""
        echo -e "${C_USER}(Type your answer and press Enter)${C_RESET}"
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
        # Extract the final concept
        TITLE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('refined_concept', {}).get('title', ''))")
        SUMMARY=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('refined_concept', {}).get('executive_summary', ''))")
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_PROMPT}✅ Your Problem Solution is Ready!${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}📋 $TITLE${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "$SUMMARY"
        echo ""
        
        # Extract and display key insights
        echo -e "${C_PROMPT}💡 Key Findings:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
insights = data.get('refined_concept', {}).get('key_insights', [])
for i, insight in enumerate(insights, 1):
    print(f'   {i}. {insight}')
"
        echo ""
        
        # Extract and display next steps
        echo -e "${C_PROMPT}🚀 Implementation Steps:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
steps = data.get('refined_concept', {}).get('next_steps', [])
for i, step in enumerate(steps, 1):
    print(f'   {i}. {step}')
"
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_INFO}Problem type: $DOMAIN | Questions asked: $QUESTION_COUNT${C_RESET}"
        
        # Save the final result
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        FILENAME="problem_solution_${DOMAIN}_${TIMESTAMP}.json"
        echo "$CLEANED_RESPONSE" > "$FILENAME"
        echo -e "${C_INFO}Full solution plan saved to: $FILENAME${C_RESET}"
        
        break # Exit the loop
    else
        echo -e "${C_ERROR}🔥 Unknown action: '$NEXT_ACTION'. Aborting.${C_RESET}"
        exit 1
    fi
done