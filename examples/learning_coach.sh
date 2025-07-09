#!/bin/bash

# learning_coach.sh
# Adaptive Learning Consultant powered by Claude

# --- Color Definitions for better UI ---
C_PROMPT='\033[1;36m' # Cyan for Claude's prompts
C_USER='\033[1;32m'   # Green for User input
C_INFO='\033[0;33m'   # Yellow for info/reasoning
C_ERROR='\033[0;31m'  # Red for errors
C_RESET='\033[0m'     # Reset color

# The learning coach prompt
read -r -d '' PROMPT << 'EOF'
You are an expert learning coach specializing in personalized education strategies. Your goal is to help users master any subject through adaptive questioning and learning path creation.

You will be given a JSON object representing the entire conversation state. Your task is to:

1. **Assess Learning Needs**: Based on the user's initial input, identify what they want to learn, their current knowledge level, and learning preferences.

2. **Build a Learning Canvas**: Create and maintain a personalized learning framework with 5-7 key aspects:
   - Learning objective
   - Current knowledge baseline
   - Learning style preferences
   - Time commitment/constraints
   - Resources and environment
   - Progress metrics
   - Potential obstacles

3. **Ask Adaptive Questions**: Always ask the single most important question to customize their learning path. Questions should:
   - Assess knowledge gaps and strengths
   - Uncover learning preferences and habits
   - Identify resources and constraints
   - Build on previous responses

4. **Track Learning Journey**: Monitor what's been established about their learning profile and what needs clarification.

5. **Create Learning Path**: When sufficient information is gathered, provide a comprehensive, personalized learning plan.

You MUST respond ONLY with a single JSON object. Do not add any conversational text outside of the JSON. Do not wrap the JSON in markdown code blocks.

Output structure:
{
  "domain_detected": "mathematics|programming|language|science|business|arts|other",
  "domain_confidence": 0.0 to 1.0,
  
  "next_action": "ask" or "conclude",
  
  "question_for_user": {
    "progress_update": "A one-line summary of what has been established about their learning profile.",
    "question_text": "The single most important question to ask the user next.",
    "question_reasoning": "A brief explanation of *why* this question matters for their learning path."
  },
  (Include question_for_user ONLY if next_action is "ask")
  
  "refined_concept": {
    "title": "Personalized Learning Path: [Subject]",
    "executive_summary": "A comprehensive 3-4 paragraph learning plan tailored to the user.",
    "key_insights": ["List of 3-5 key discoveries about their learning needs and style"],
    "next_steps": ["List of 3-5 concrete learning actions to start immediately"]
  },
  (Include refined_concept ONLY if next_action is "conclude")
  
  "updated_state": {
    "user_response_for_this_turn": null,
    "conversation_history": ["array of previous Q&A pairs"],
    "idea_canvas": {
      "core_concept": {"value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_1": {"name": "learning_objective", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_2": {"name": "current_knowledge", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_3": {"name": "learning_style", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_4": {"name": "time_commitment", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_5": {"name": "resources_available", "value": "string or null", "status": "empty|developing|refined"}
    },
    "consultant_notes": ["array of analytical notes about the learning profile"]
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
echo -e "${C_PROMPT}📚 Welcome to Your Adaptive Learning Coach!${C_RESET}"
echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_INFO}I'm here to help you master any subject through personalized learning strategies."
echo -e "Whether you're learning programming, languages, mathematics, or any other topic,"
echo -e "I'll create a customized learning path based on your unique needs and style."
echo ""
echo -e "Let's start by understanding what you want to learn.${C_RESET}"
echo ""
echo -e "${C_PROMPT}What subject or skill would you like to master?${C_RESET}"
echo -e "${C_USER}(Share what you want to learn and any context about your goals)${C_RESET}"
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
        'key_aspect_1': {'name': 'learning_objective', 'value': None, 'status': 'empty'},
        'key_aspect_2': {'name': 'current_knowledge', 'value': None, 'status': 'empty'},
        'key_aspect_3': {'name': 'learning_style', 'value': None, 'status': 'empty'},
        'key_aspect_4': {'name': 'time_commitment', 'value': None, 'status': 'empty'},
        'key_aspect_5': {'name': 'resources_available', 'value': None, 'status': 'empty'}
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
    echo -e "\n${C_INFO}[Analyzing your learning needs...]${C_RESET}"
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
        echo -e "\n${C_INFO}🎯 Subject area identified: ${DOMAIN} (confidence: ${DOMAIN_CONF})${C_RESET}"
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
        echo -e "${C_INFO}📊 Learning Profile: $PROGRESS${C_RESET}"
        echo -e "${C_INFO}💭 (Why this matters: $REASONING)${C_RESET}"
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
        echo -e "${C_PROMPT}✅ Your Personalized Learning Path is Ready!${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}📋 $TITLE${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "$SUMMARY"
        echo ""
        
        # Extract and display key insights
        echo -e "${C_PROMPT}💡 Key Learning Insights:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
insights = data.get('refined_concept', {}).get('key_insights', [])
for i, insight in enumerate(insights, 1):
    print(f'   {i}. {insight}')
"
        echo ""
        
        # Extract and display next steps
        echo -e "${C_PROMPT}🚀 Your First Learning Steps:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
steps = data.get('refined_concept', {}).get('next_steps', [])
for i, step in enumerate(steps, 1):
    print(f'   {i}. {step}')
"
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_INFO}Subject: $DOMAIN | Questions asked: $QUESTION_COUNT${C_RESET}"
        
        # Save the final result
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        FILENAME="learning_path_${DOMAIN}_${TIMESTAMP}.json"
        echo "$CLEANED_RESPONSE" > "$FILENAME"
        echo -e "${C_INFO}Your learning path saved to: $FILENAME${C_RESET}"
        
        break # Exit the loop
    else
        echo -e "${C_ERROR}🔥 Unknown action: '$NEXT_ACTION'. Aborting.${C_RESET}"
        exit 1
    fi
done