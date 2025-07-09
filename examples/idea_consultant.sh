#!/bin/bash

# idea_consultant_generic.sh
# Generic Adaptive Consultant powered by Claude

# --- Color Definitions for better UI ---
C_PROMPT='\033[1;36m' # Cyan for Claude's prompts
C_USER='\033[1;32m'   # Green for User input
C_INFO='\033[0;33m'   # Yellow for info/reasoning
C_ERROR='\033[0;31m'  # Red for errors
C_RESET='\033[0m'     # Reset color

# The generic adaptive consultant prompt
read -r -d '' PROMPT << 'EOF'
You are an elite consultant with expertise across multiple domains. Your goal is to help users develop their ideas through intelligent, adaptive questioning.

You will be given a JSON object representing the entire conversation state. Your task is to:

1. **Analyze the Topic**: Based on the user's initial input and subsequent responses, dynamically determine what type of idea/project they're working on (software, business, creative writing, research, product design, etc.)

2. **Build an Adaptive Canvas**: Create and maintain a relevant framework for their specific type of idea. The canvas should have 5-7 key aspects that need clarification, adapted to their domain.

3. **Ask Intelligent Questions**: Always ask the single most important question to move their idea forward. Questions should be:
   - Open-ended and thought-provoking
   - Specific to their domain and current stage
   - Designed to uncover hidden assumptions or opportunities

4. **Track Progress**: Maintain a clear understanding of what's been established and what still needs work.

5. **Know When to Conclude**: When all critical aspects are well-defined, provide a comprehensive summary.

You MUST respond ONLY with a single JSON object. Do not add any conversational text outside of the JSON. Do not wrap the JSON in markdown code blocks.

Output structure:
{
  "domain_detected": "software|business|creative|research|product|other",
  "domain_confidence": 0.0 to 1.0,
  
  "next_action": "ask" or "conclude",
  
  "question_for_user": {
    "progress_update": "A one-line summary of what has been established so far.",
    "question_text": "The single most important question to ask the user next.",
    "question_reasoning": "A brief explanation of *why* you are asking this question now."
  },
  (Include question_for_user ONLY if next_action is "ask")
  
  "refined_concept": {
    "title": "A catchy title for their concept.",
    "executive_summary": "A comprehensive 3-4 paragraph summary of the refined concept.",
    "key_insights": ["List of 3-5 key insights or decisions made during the consultation"],
    "next_steps": ["List of 3-5 concrete next steps they should take"]
  },
  (Include refined_concept ONLY if next_action is "conclude")
  
  "updated_state": {
    "user_response_for_this_turn": null,
    "conversation_history": ["array of previous Q&A pairs"],
    "idea_canvas": {
      "core_concept": {"value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_1": {"name": "dynamically named based on domain", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_2": {"name": "dynamically named based on domain", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_3": {"name": "dynamically named based on domain", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_4": {"name": "dynamically named based on domain", "value": "string or null", "status": "empty|developing|refined"},
      "key_aspect_5": {"name": "dynamically named based on domain", "value": "string or null", "status": "empty|developing|refined"}
    },
    "consultant_notes": ["array of analytical notes about the evolving idea"]
  }
}

IMPORTANT: The key_aspect fields should be dynamically named based on what you detect. For example:
- For software: "technical_architecture", "user_experience", "monetization_model", etc.
- For creative writing: "plot_structure", "character_development", "themes", etc.
- For research: "hypothesis", "methodology", "expected_impact", etc.
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
echo -e "${C_PROMPT}🧠 Welcome to the Adaptive Idea Consultant!${C_RESET}"
echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_INFO}I'm here to help you develop any type of idea or project through intelligent questioning."
echo -e "I'll adapt to whatever you're working on - software, business, creative projects, research, or anything else!"
echo ""
echo -e "Share as much or as little as you'd like, and I'll guide you from there.${C_RESET}"
echo ""
echo -e "${C_PROMPT}What are you thinking about or working on?${C_RESET}"
echo -e "${C_USER}(Type your response and press Enter)${C_RESET}"
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
        'key_aspect_1': {'name': 'undefined', 'value': None, 'status': 'empty'},
        'key_aspect_2': {'name': 'undefined', 'value': None, 'status': 'empty'},
        'key_aspect_3': {'name': 'undefined', 'value': None, 'status': 'empty'},
        'key_aspect_4': {'name': 'undefined', 'value': None, 'status': 'empty'},
        'key_aspect_5': {'name': 'undefined', 'value': None, 'status': 'empty'}
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
    echo -e "\n${C_INFO}[Analyzing and formulating response...]${C_RESET}"
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
        echo -e "\n${C_INFO}🎯 Domain detected: ${DOMAIN} (confidence: ${DOMAIN_CONF})${C_RESET}"
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
        echo -e "${C_INFO}📊 Progress: $PROGRESS${C_RESET}"
        echo -e "${C_INFO}💭 (Why this question: $REASONING)${C_RESET}"
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
        echo -e "${C_PROMPT}✅ Your concept is now fully developed!${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}📋 $TITLE${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "$SUMMARY"
        echo ""
        
        # Extract and display key insights
        echo -e "${C_PROMPT}💡 Key Insights:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
insights = data.get('refined_concept', {}).get('key_insights', [])
for i, insight in enumerate(insights, 1):
    print(f'   {i}. {insight}')
"
        echo ""
        
        # Extract and display next steps
        echo -e "${C_PROMPT}🚀 Recommended Next Steps:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
steps = data.get('refined_concept', {}).get('next_steps', [])
for i, step in enumerate(steps, 1):
    print(f'   {i}. {step}')
"
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_INFO}Domain: $DOMAIN | Questions asked: $QUESTION_COUNT${C_RESET}"
        
        # Save the final result
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        FILENAME="concept_${DOMAIN}_${TIMESTAMP}.json"
        echo "$CLEANED_RESPONSE" > "$FILENAME"
        echo -e "${C_INFO}Full session saved to: $FILENAME${C_RESET}"
        
        break # Exit the loop
    else
        echo -e "${C_ERROR}🔥 Unknown action: '$NEXT_ACTION'. Aborting.${C_RESET}"
        exit 1
    fi
done