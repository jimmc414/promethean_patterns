#!/bin/bash

# fitness_coach.sh
# Adaptive Fitness Planning Coach powered by Claude

# --- Color Definitions for better UI ---
C_PROMPT='\033[1;36m' # Cyan for Claude's prompts
C_USER='\033[1;32m'   # Green for User input
C_INFO='\033[0;33m'   # Yellow for info/reasoning
C_ERROR='\033[0;31m'  # Red for errors
C_RESET='\033[0m'     # Reset color

# The fitness coaching prompt
read -r -d '' PROMPT << 'EOF'
You are an experienced, supportive fitness coach who helps people create sustainable fitness plans. Your approach is inclusive, evidence-based, and focused on long-term health rather than quick fixes.

You will be given a JSON object representing the entire conversation state. Your task is to:

1. **Understand Their Goals**: Learn what they want to achieve and why, without judging or imposing standard fitness culture ideals.

2. **Assess Current State**: Understand their:
   - Current activity level and fitness experience
   - Available time and resources
   - Physical limitations or health considerations
   - Preferences and what they enjoy
   - Past experiences (positive and negative)

3. **Create a Realistic Plan**: Design a program that:
   - Starts where they are, not where they "should" be
   - Builds gradually and sustainably
   - Includes activities they'll actually enjoy
   - Fits their real life and constraints
   - Addresses all relevant fitness components

4. **Focus on Behavior Change**: Help them build habits, not just follow a program.

5. **Provide Clear Action Steps**: End with specific, achievable first steps.

You MUST respond ONLY with a single JSON object. Do not add any conversational text outside of the JSON. Do not wrap the JSON in markdown code blocks.

Output structure:
{
  "fitness_focus": "general_health|strength|endurance|flexibility|weight_management|sport_specific|rehabilitation",
  "experience_level": "beginner|returning|intermediate|advanced",
  "plan_complexity": "simple|moderate|comprehensive",
  
  "next_action": "ask" or "conclude",
  
  "coaching_question": {
    "progress_update": "Encouraging summary of what we've learned about their fitness journey.",
    "question_text": "The next question to understand their needs better.",
    "question_reasoning": "Why this information helps create their plan."
  },
  (Include coaching_question ONLY if next_action is "ask")
  
  "fitness_plan": {
    "title": "Your Personalized Fitness Journey: [Goal-Specific Title]",
    "executive_summary": "An encouraging overview of their fitness plan and path forward.",
    "weekly_schedule": {
      "primary_activities": ["List of main workout activities with frequency"],
      "active_recovery": ["Light activities for rest days"],
      "flexibility_mobility": ["Stretching or mobility work"]
    },
    "progression_plan": {
      "weeks_1_2": "Initial phase focus and goals",
      "weeks_3_4": "Building phase adjustments",
      "month_2_onwards": "Progression strategy"
    },
    "success_strategies": ["4-5 strategies for adherence and motivation"],
    "equipment_needed": ["Minimal equipment list or alternatives"],
    "tracking_metrics": ["3-4 ways to measure progress beyond the scale"],
    "first_week_plan": ["Day-by-day plan for the first week to get started"]
  },
  (Include fitness_plan ONLY if next_action is "conclude")
  
  "updated_state": {
    "user_response_for_this_turn": null,
    "conversation_history": ["array of previous Q&A pairs"],
    "fitness_profile": {
      "primary_goal": {"value": "string or null", "status": "empty|developing|refined"},
      "current_activity": {"value": "string or null", "status": "empty|developing|refined"},
      "time_availability": {"value": "string or null", "status": "empty|developing|refined"},
      "physical_considerations": {"value": "string or null", "status": "empty|developing|refined"},
      "preferences_enjoyment": {"value": "string or null", "status": "empty|developing|refined"},
      "resources_constraints": {"value": "string or null", "status": "empty|developing|refined"},
      "motivation_factors": {"value": "string or null", "status": "empty|developing|refined"}
    },
    "coaching_notes": ["array of observations about their needs and optimal approaches"]
  }
}

Guidelines:
- Be inclusive and body-positive - fitness is for every body
- Focus on health and function, not just appearance
- Recognize that rest is part of fitness
- Avoid toxic fitness culture language
- Be realistic about time and life constraints
- Emphasize enjoyment and sustainability over intensity
- Respect their autonomy and preferences
- Include mental health as part of overall fitness
- Never prescribe specific medical or dietary advice
- Adapt to disabilities and chronic conditions respectfully
- Remember that movement should add to life, not dominate it
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
echo -e "${C_PROMPT}💪 Welcome to Your Personal Fitness Planning Coach${C_RESET}"
echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_INFO}I'm here to help you create a fitness plan that fits YOUR life and goals."
echo -e "We'll work together to build something sustainable and enjoyable."
echo ""
echo -e "Remember: The best fitness plan is the one you'll actually do!${C_RESET}"
echo ""
echo -e "${C_PROMPT}What brings you here today? What would you like to achieve with your fitness?${C_RESET}"
echo -e "${C_USER}(Share your goals, hopes, or even frustrations - this is a judgment-free zone)${C_RESET}"
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
    'fitness_profile': {
        'primary_goal': {'value': None, 'status': 'empty'},
        'current_activity': {'value': None, 'status': 'empty'},
        'time_availability': {'value': None, 'status': 'empty'},
        'physical_considerations': {'value': None, 'status': 'empty'},
        'preferences_enjoyment': {'value': None, 'status': 'empty'},
        'resources_constraints': {'value': None, 'status': 'empty'},
        'motivation_factors': {'value': None, 'status': 'empty'}
    },
    'coaching_notes': []
}

print(json.dumps(initial_state))
")

# Counter for questions
QUESTION_COUNT=0
FITNESS_FOCUS="unknown"
EXPERIENCE="unknown"

# 3. THE RECURSIVE LOOP
while true; do
    # Call Claude with the current state, get its JSON response
    echo -e "\n${C_INFO}[Analyzing your fitness needs and goals...]${C_RESET}"
    CLAUDE_RESPONSE=$(echo "$STATE" | claude -p "$PROMPT")
    
    # Extract JSON from potential markdown wrapper
    CLEANED_RESPONSE=$(extract_json "$CLAUDE_RESPONSE")
    
    # Basic validation
    if ! echo "$CLEANED_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
        echo -e "${C_ERROR}🔥 Error processing response. Aborting.${C_RESET}"
        echo -e "${C_ERROR}Raw response: $CLAUDE_RESPONSE${C_RESET}"
        exit 1
    fi
    
    # Extract fitness focus and experience level
    NEW_FOCUS=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('fitness_focus', 'unknown'))" 2>/dev/null || echo "unknown")
    NEW_EXPERIENCE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('experience_level', 'unknown'))" 2>/dev/null || echo "unknown")
    COMPLEXITY=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('plan_complexity', 'unknown'))" 2>/dev/null || echo "unknown")
    
    if [ "$NEW_FOCUS" != "unknown" ] && [ "$NEW_FOCUS" != "$FITNESS_FOCUS" ]; then
        FITNESS_FOCUS="$NEW_FOCUS"
        echo -e "\n${C_INFO}🎯 Focus area: ${FITNESS_FOCUS}${C_RESET}"
    fi
    
    if [ "$NEW_EXPERIENCE" != "unknown" ] && [ "$NEW_EXPERIENCE" != "$EXPERIENCE" ]; then
        EXPERIENCE="$NEW_EXPERIENCE"
        echo -e "${C_INFO}📊 Experience level: ${EXPERIENCE}${C_RESET}"
    fi
    
    # Extract next action
    NEXT_ACTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('next_action', ''))")
    
    if [ "$NEXT_ACTION" = "ask" ]; then
        QUESTION_COUNT=$((QUESTION_COUNT + 1))
        
        # Extract the question and reasoning from Claude's response
        PROGRESS=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('coaching_question', {}).get('progress_update', ''))")
        QUESTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('coaching_question', {}).get('question_text', ''))")
        REASONING=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('coaching_question', {}).get('question_reasoning', ''))")
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_INFO}✨ ${PROGRESS}${C_RESET}"
        echo -e "${C_INFO}💭 (Why I'm asking: ${REASONING})${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}Question ${QUESTION_COUNT}: ${QUESTION}${C_RESET}"
        echo ""
        echo -e "${C_USER}(Be honest - this helps me create a plan that works for you)${C_RESET}"
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
        # Extract the fitness plan
        TITLE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('fitness_plan', {}).get('title', ''))")
        SUMMARY=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('fitness_plan', {}).get('executive_summary', ''))")
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_PROMPT}✅ ${TITLE}${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "$SUMMARY"
        echo ""
        
        # Extract and display weekly schedule
        echo -e "${C_PROMPT}📅 Your Weekly Movement Schedule:${C_RESET}"
        echo -e "${C_INFO}Primary Activities:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
activities = data.get('fitness_plan', {}).get('weekly_schedule', {}).get('primary_activities', [])
for activity in activities:
    print(f'   • {activity}')
"
        echo ""
        echo -e "${C_INFO}Active Recovery Days:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
recovery = data.get('fitness_plan', {}).get('weekly_schedule', {}).get('active_recovery', [])
for item in recovery:
    print(f'   • {item}')
"
        echo ""
        echo -e "${C_INFO}Flexibility & Mobility:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
flexibility = data.get('fitness_plan', {}).get('weekly_schedule', {}).get('flexibility_mobility', [])
for item in flexibility:
    print(f'   • {item}')
"
        echo ""
        
        # Extract and display progression plan
        echo -e "${C_PROMPT}📈 How You'll Progress:${C_RESET}"
        WEEKS_1_2=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('fitness_plan', {}).get('progression_plan', {}).get('weeks_1_2', ''))")
        WEEKS_3_4=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('fitness_plan', {}).get('progression_plan', {}).get('weeks_3_4', ''))")
        MONTH_2=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('fitness_plan', {}).get('progression_plan', {}).get('month_2_onwards', ''))")
        echo -e "${C_INFO}Weeks 1-2:${C_RESET} $WEEKS_1_2"
        echo -e "${C_INFO}Weeks 3-4:${C_RESET} $WEEKS_3_4"
        echo -e "${C_INFO}Month 2+:${C_RESET} $MONTH_2"
        echo ""
        
        # Extract and display success strategies
        echo -e "${C_PROMPT}🎯 Your Success Strategies:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
strategies = data.get('fitness_plan', {}).get('success_strategies', [])
for i, strategy in enumerate(strategies, 1):
    print(f'   {i}. {strategy}')
"
        echo ""
        
        # Extract and display equipment
        echo -e "${C_PROMPT}🏋️ Equipment Needed:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
equipment = data.get('fitness_plan', {}).get('equipment_needed', [])
for item in equipment:
    print(f'   • {item}')
"
        echo ""
        
        # Extract and display tracking metrics
        echo -e "${C_PROMPT}📊 Ways to Track Your Progress:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
metrics = data.get('fitness_plan', {}).get('tracking_metrics', [])
for metric in metrics:
    print(f'   ✓ {metric}')
"
        echo ""
        
        # Extract and display first week plan
        echo -e "${C_PROMPT}🚀 Your First Week - Let's Get Started:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
first_week = data.get('fitness_plan', {}).get('first_week_plan', [])
for day in first_week:
    print(f'   {day}')
"
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_INFO}💚 Remember: Progress isn't always linear. Celebrate showing up!${C_RESET}"
        echo -e "${C_INFO}   Listen to your body, rest when needed, and enjoy the journey.${C_RESET}"
        echo -e "${C_INFO}   You've got this! 🌟${C_RESET}"
        
        # Save the plan
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        FILENAME="fitness_plan_${FITNESS_FOCUS}_${TIMESTAMP}.json"
        echo "$CLEANED_RESPONSE" > "$FILENAME"
        echo ""
        echo -e "${C_INFO}Your personalized fitness plan has been saved to: ${FILENAME}${C_RESET}"
        echo -e "${C_INFO}Focus: ${FITNESS_FOCUS} | Experience: ${EXPERIENCE} | Complexity: ${COMPLEXITY}${C_RESET}"
        
        break # Exit the loop
    else
        echo -e "${C_ERROR}🔥 Unknown action: '$NEXT_ACTION'. Aborting.${C_RESET}"
        exit 1
    fi
done