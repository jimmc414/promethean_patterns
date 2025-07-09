#!/bin/bash

# wellness_guide.sh
# Holistic Wellness Consultant powered by Claude

# --- Color Definitions for better UI ---
C_PROMPT='\033[1;36m' # Cyan for Claude's prompts
C_USER='\033[1;32m'   # Green for User input
C_INFO='\033[0;33m'   # Yellow for info/reasoning
C_ERROR='\033[0;31m'  # Red for errors
C_RESET='\033[0m'     # Reset color

# The wellness guide prompt
read -r -d '' PROMPT << 'EOF'
You are an expert wellness consultant specializing in holistic health approaches. Your goal is to help users improve their physical, mental, and lifestyle wellbeing through personalized guidance.

You will be given a JSON object representing the entire conversation state. Your task is to:

1. **Assess Wellness Needs**: Based on the user's input, understand their wellness goals, current challenges, and lifestyle context.

2. **Build a Wellness Canvas**: Create and maintain a holistic framework with 5-7 key aspects:
   - Current wellness state
   - Primary health goals
   - Physical activity and fitness
   - Mental and emotional health
   - Nutrition and sleep patterns
   - Stress and lifestyle factors
   - Support systems and resources

3. **Ask Compassionate Questions**: Always ask the single most important question to understand their wellness needs. Questions should:
   - Be sensitive and non-judgmental
   - Explore root causes, not just symptoms
   - Consider the whole person
   - Identify realistic opportunities for improvement
   - Respect personal boundaries

4. **Apply Wellness Principles**: Use evidence-based approaches while respecting individual preferences and constraints.

5. **Create Wellness Plan**: When sufficient information is gathered, provide a balanced, achievable wellness roadmap.

You MUST respond ONLY with a single JSON object. Do not add any conversational text outside of the JSON. Do not wrap the JSON in markdown code blocks.

IMPORTANT: Always include disclaimers about consulting healthcare professionals for medical concerns.

Output structure:
{
  "domain_detected": "physical|mental|nutrition|sleep|stress|lifestyle|other",
  "domain_confidence": 0.0 to 1.0,
  
  "next_action": "ask" or "conclude",
  
  "question_for_user": {
    "progress_update": "A one-line summary of what has been established about their wellness profile.",
    "question_text": "The single most important question to ask the user next.",
    "question_reasoning": "A brief explanation of *why* this question matters for their wellness journey."
  },
  (Include question_for_user ONLY if next_action is "ask")
  
  "refined_concept": {
    "title": "Personalized Wellness Plan: [Focus Area]",
    "executive_summary": "A comprehensive 3-4 paragraph wellness strategy with disclaimers.",
    "key_insights": ["List of 3-5 key discoveries about their wellness needs and opportunities"],
    "next_steps": ["List of 3-5 concrete wellness actions to start with"]
  },
  (Include refined_concept ONLY if next_action is "conclude")
  
  "updated_state": {
    "user_response_for_this_turn": null,
    "conversation_history": ["array of previous Q&A pairs"],
    "idea_canvas": {
      "core_concept": {"value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_1": {"name": "wellness_goals", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_2": {"name": "current_challenges", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_3": {"name": "physical_activity", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_4": {"name": "mental_wellbeing", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_5": {"name": "lifestyle_factors", "value": "string or null", "status": "empty|developing|refined"}
    },
    "consultant_notes": ["array of analytical notes about the wellness journey"]
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
echo -e "${C_PROMPT}🌱 Welcome to Your Holistic Wellness Guide!${C_RESET}"
echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_INFO}I'm here to help you create a personalized wellness plan that addresses"
echo -e "your physical, mental, and lifestyle needs in a balanced, sustainable way."
echo ""
echo -e "Remember: This guidance is educational and should complement, not replace,"
echo -e "professional medical advice.${C_RESET}"
echo ""
echo -e "${C_PROMPT}What aspect of your wellness would you like to improve?${C_RESET}"
echo -e "${C_USER}(Share your wellness goals or current challenges)${C_RESET}"
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
        'key_aspect_1': {'name': 'wellness_goals', 'value': None, 'status': 'empty'},
        'key_aspect_2': {'name': 'current_challenges', 'value': None, 'status': 'empty'},
        'key_aspect_3': {'name': 'physical_activity', 'value': None, 'status': 'empty'},
        'key_aspect_4': {'name': 'mental_wellbeing', 'value': None, 'status': 'empty'},
        'key_aspect_5': {'name': 'lifestyle_factors', 'value': None, 'status': 'empty'}
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
    echo -e "\n${C_INFO}[Analyzing your wellness needs holistically...]${C_RESET}"
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
        echo -e "\n${C_INFO}🎯 Primary wellness focus: ${DOMAIN} (confidence: ${DOMAIN_CONF})${C_RESET}"
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
        echo -e "${C_INFO}📊 Wellness Profile: $PROGRESS${C_RESET}"
        echo -e "${C_INFO}💭 (Why this matters: $REASONING)${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}❓ Question $QUESTION_COUNT: $QUESTION${C_RESET}"
        echo ""
        echo -e "${C_USER}(Type your answer and press Enter - share only what you're comfortable with)${C_RESET}"
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
        echo -e "${C_PROMPT}✅ Your Personalized Wellness Plan is Ready!${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}📋 $TITLE${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "$SUMMARY"
        echo ""
        
        # Extract and display key insights
        echo -e "${C_PROMPT}💡 Key Wellness Insights:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
insights = data.get('refined_concept', {}).get('key_insights', [])
for i, insight in enumerate(insights, 1):
    print(f'   {i}. {insight}')
"
        echo ""
        
        # Extract and display next steps
        echo -e "${C_PROMPT}🚀 Your Wellness Action Steps:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
steps = data.get('refined_concept', {}).get('next_steps', [])
for i, step in enumerate(steps, 1):
    print(f'   {i}. {step}')
"
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_INFO}Wellness focus: $DOMAIN | Questions asked: $QUESTION_COUNT${C_RESET}"
        echo ""
        echo -e "${C_INFO}⚕️  Important: This plan is for educational purposes only."
        echo -e "Always consult healthcare professionals for medical concerns.${C_RESET}"
        
        # Save the final result
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        FILENAME="wellness_plan_${DOMAIN}_${TIMESTAMP}.json"
        echo "$CLEANED_RESPONSE" > "$FILENAME"
        echo -e "${C_INFO}Your wellness plan saved to: $FILENAME${C_RESET}"
        
        break # Exit the loop
    else
        echo -e "${C_ERROR}🔥 Unknown action: '$NEXT_ACTION'. Aborting.${C_RESET}"
        exit 1
    fi
done