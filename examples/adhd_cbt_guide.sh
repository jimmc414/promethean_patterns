#!/bin/bash

# adhd_cbt_guide.sh
# CBT-based ADHD Therapy Consultant powered by Claude

# --- Color Definitions for better UI ---
C_PROMPT='\033[1;36m' # Cyan for Claude's prompts
C_USER='\033[1;32m'   # Green for User input
C_INFO='\033[0;33m'   # Yellow for info/reasoning
C_ERROR='\033[0;31m'  # Red for errors
C_RESET='\033[0m'     # Reset color

# The CBT-ADHD therapy consultant prompt
read -r -d '' PROMPT << 'EOF'
You are an experienced CBT therapist specializing in ADHD. Your goal is to help users develop a personalized CBT-based approach to managing their ADHD through intelligent, therapeutic questioning.

You will be given a JSON object representing the entire conversation state. Your task is to:

1. **Explore ADHD Presentation**: Understand their specific ADHD challenges without making assumptions. Everyone's ADHD is different.

2. **Apply CBT Principles**: Guide the conversation using evidence-based CBT techniques for ADHD:
   - Cognitive restructuring (identifying and challenging unhelpful thoughts)
   - Behavioral activation and scheduling
   - Problem-solving training
   - Time management and organization skills
   - Emotional regulation strategies
   - Executive function support

3. **Build Personalized Strategies**: Help them discover what works for their unique brain, lifestyle, and challenges.

4. **Focus on Practical Skills**: Always move toward actionable, concrete strategies they can implement immediately.

5. **Validate and Normalize**: ADHD is real, and their struggles are valid. Avoid toxic positivity or minimizing their experience.

You MUST respond ONLY with a single JSON object. Do not add any conversational text outside of the JSON. Do not wrap the JSON in markdown code blocks.

Output structure:
{
  "therapeutic_focus": "assessment|cognitive|behavioral|skills|integration",
  "cbt_technique_used": "Brief description of the CBT approach being used this turn",
  
  "next_action": "ask" or "conclude",
  
  "question_for_user": {
    "progress_update": "A supportive summary of insights gained so far.",
    "question_text": "The therapeutic question to ask next.",
    "question_reasoning": "The clinical reasoning behind this question."
  },
  (Include question_for_user ONLY if next_action is "ask")
  
  "therapy_plan": {
    "title": "Personalized CBT Plan for [Key Challenge Area]",
    "executive_summary": "A comprehensive summary of their personalized CBT approach.",
    "key_strategies": ["List of 4-6 specific CBT strategies tailored to their needs"],
    "implementation_steps": ["List of 4-6 concrete first steps to take"],
    "maintenance_tips": ["List of 3-4 tips for long-term success"]
  },
  (Include therapy_plan ONLY if next_action is "conclude")
  
  "updated_state": {
    "user_response_for_this_turn": null,
    "conversation_history": ["array of previous Q&A pairs"],
    "adhd_profile": {
      "primary_challenges": {"value": "string or null", "status": "empty|developing|refined"},
      "cognitive_patterns": {"value": "string or null", "status": "empty|developing|refined"},
      "behavioral_patterns": {"value": "string or null", "status": "empty|developing|refined"},
      "emotional_regulation": {"value": "string or null", "status": "empty|developing|refined"},
      "executive_function": {"value": "string or null", "status": "empty|developing|refined"},
      "strengths_resources": {"value": "string or null", "status": "empty|developing|refined"},
      "environmental_factors": {"value": "string or null", "status": "empty|developing|refined"}
    },
    "therapeutic_notes": ["array of clinical observations and insights"]
  }
}

IMPORTANT Guidelines:
- Be warm, validating, and non-judgmental
- Use person-first language (person with ADHD, not ADHDer)
- Recognize ADHD as neurodivergence, not a deficit
- Focus on building skills, not fixing brokenness
- Acknowledge that strategies that work for neurotypical people may not work for ADHD
- Respect their expertise about their own experience
- Don't assume medication status or push any particular treatment
- Remember that ADHD affects executive function - keep strategies ADHD-friendly (simple, concrete, low-barrier)
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
echo -e "${C_PROMPT}🧠 Welcome to the CBT-Based ADHD Strategy Builder${C_RESET}"
echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_INFO}I'm here to help you develop personalized CBT strategies for managing ADHD."
echo -e "We'll explore what works for YOUR unique brain and create practical tools together."
echo ""
echo -e "This is a judgment-free space. Your experiences and challenges are valid.${C_RESET}"
echo ""
echo -e "${C_PROMPT}What aspect of ADHD would you like to work on, or what's been challenging lately?${C_RESET}"
echo -e "${C_USER}(Share as much or as little as you're comfortable with)${C_RESET}"
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
    'adhd_profile': {
        'primary_challenges': {'value': None, 'status': 'empty'},
        'cognitive_patterns': {'value': None, 'status': 'empty'},
        'behavioral_patterns': {'value': None, 'status': 'empty'},
        'emotional_regulation': {'value': None, 'status': 'empty'},
        'executive_function': {'value': None, 'status': 'empty'},
        'strengths_resources': {'value': None, 'status': 'empty'},
        'environmental_factors': {'value': None, 'status': 'empty'}
    },
    'therapeutic_notes': []
}

print(json.dumps(initial_state))
")

# Counter for questions
QUESTION_COUNT=0
FOCUS_AREA="assessment"

# 3. THE RECURSIVE LOOP
while true; do
    # Call Claude with the current state, get its JSON response
    echo -e "\n${C_INFO}[Processing your response therapeutically...]${C_RESET}"
    CLAUDE_RESPONSE=$(echo "$STATE" | claude -p "$PROMPT")
    
    # Extract JSON from potential markdown wrapper
    CLEANED_RESPONSE=$(extract_json "$CLAUDE_RESPONSE")
    
    # Basic validation
    if ! echo "$CLEANED_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
        echo -e "${C_ERROR}🔥 Error processing response. Aborting.${C_RESET}"
        echo -e "${C_ERROR}Raw response: $CLAUDE_RESPONSE${C_RESET}"
        exit 1
    fi
    
    # Extract therapeutic focus and technique
    NEW_FOCUS=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('therapeutic_focus', 'unknown'))" 2>/dev/null || echo "unknown")
    CBT_TECHNIQUE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('cbt_technique_used', ''))" 2>/dev/null || echo "")
    
    if [ "$NEW_FOCUS" != "$FOCUS_AREA" ]; then
        FOCUS_AREA="$NEW_FOCUS"
        echo -e "\n${C_INFO}🎯 Therapeutic focus: ${FOCUS_AREA}${C_RESET}"
        if [ -n "$CBT_TECHNIQUE" ]; then
            echo -e "${C_INFO}📋 Using: ${CBT_TECHNIQUE}${C_RESET}"
        fi
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
        echo -e "${C_INFO}✨ ${PROGRESS}${C_RESET}"
        echo -e "${C_INFO}💭 (Therapeutic rationale: ${REASONING})${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}Question ${QUESTION_COUNT}: ${QUESTION}${C_RESET}"
        echo ""
        echo -e "${C_USER}(Take your time. There's no wrong answer here.)${C_RESET}"
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
        # Extract the therapy plan
        TITLE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('therapy_plan', {}).get('title', ''))")
        SUMMARY=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('therapy_plan', {}).get('executive_summary', ''))")
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_PROMPT}✅ Your Personalized CBT-ADHD Strategy Plan${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}📋 ${TITLE}${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "$SUMMARY"
        echo ""
        
        # Extract and display key strategies
        echo -e "${C_PROMPT}🛠️ Your CBT Strategies:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
strategies = data.get('therapy_plan', {}).get('key_strategies', [])
for i, strategy in enumerate(strategies, 1):
    print(f'   {i}. {strategy}')
"
        echo ""
        
        # Extract and display implementation steps
        echo -e "${C_PROMPT}🚀 First Steps to Take:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
steps = data.get('therapy_plan', {}).get('implementation_steps', [])
for i, step in enumerate(steps, 1):
    print(f'   {i}. {step}')
"
        echo ""
        
        # Extract and display maintenance tips
        echo -e "${C_PROMPT}💪 For Long-term Success:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
tips = data.get('therapy_plan', {}).get('maintenance_tips', [])
for i, tip in enumerate(tips, 1):
    print(f'   • {tip}')
"
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_INFO}Remember: Progress isn't linear. Be kind to yourself as you practice these strategies.${C_RESET}"
        echo -e "${C_INFO}What works one day might not work the next, and that's okay.${C_RESET}"
        
        # Save the session
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        FILENAME="adhd_cbt_plan_${TIMESTAMP}.json"
        echo "$CLEANED_RESPONSE" > "$FILENAME"
        echo ""
        echo -e "${C_INFO}Your personalized plan has been saved to: ${FILENAME}${C_RESET}"
        echo -e "${C_INFO}Questions explored: ${QUESTION_COUNT}${C_RESET}"
        
        break # Exit the loop
    else
        echo -e "${C_ERROR}🔥 Unknown action: '$NEXT_ACTION'. Aborting.${C_RESET}"
        exit 1
    fi
done