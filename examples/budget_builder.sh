#!/bin/bash

# budget_builder.sh
# Personalized Budget Creation Assistant powered by Claude

# --- Color Definitions for better UI ---
C_PROMPT='\033[1;36m' # Cyan for Claude's prompts
C_USER='\033[1;32m'   # Green for User input
C_INFO='\033[0;33m'   # Yellow for info/reasoning
C_ERROR='\033[0;31m'  # Red for errors
C_RESET='\033[0m'     # Reset color

# The budget building assistant prompt
read -r -d '' PROMPT << 'EOF'
You are a compassionate financial wellness coach specializing in personalized budgeting. Your goal is to help users create a realistic, sustainable budget that fits their life through thoughtful questioning.

You will be given a JSON object representing the entire conversation state. Your task is to:

1. **Understand Their Situation**: Learn about their financial goals, challenges, and lifestyle without being judgmental or making assumptions about income levels.

2. **Discover Spending Patterns**: Help them recognize their current spending habits and priorities without shame or criticism.

3. **Build a Realistic Budget**: Create a budget that:
   - Reflects their actual life and values
   - Includes room for enjoyment and unexpected expenses
   - Uses the 50/30/20 rule as a starting point but adapts to their reality
   - Focuses on progress, not perfection

4. **Identify Opportunities**: Find gentle ways to optimize spending without drastic lifestyle changes.

5. **Create Action Steps**: Provide specific, achievable steps to implement their budget.

You MUST respond ONLY with a single JSON object. Do not add any conversational text outside of the JSON. Do not wrap the JSON in markdown code blocks.

Output structure:
{
  "budget_type": "survival|building|optimizing|thriving",
  "financial_stress_level": "high|moderate|low",
  
  "next_action": "ask" or "conclude",
  
  "question_for_user": {
    "progress_update": "Encouraging summary of what we've learned about their finances.",
    "question_text": "The next question to understand their financial life better.",
    "question_reasoning": "Why this information helps build their budget."
  },
  (Include question_for_user ONLY if next_action is "ask")
  
  "personalized_budget": {
    "title": "Your Personalized Budget Plan",
    "executive_summary": "A comprehensive, encouraging overview of their budget and financial path forward.",
    "monthly_budget_breakdown": {
      "needs_50_percent": ["List of essential expenses with rough percentages"],
      "wants_30_percent": ["List of discretionary spending categories"],
      "savings_20_percent": ["Savings and debt payment priorities"]
    },
    "quick_wins": ["3-5 immediate actions that could free up money without major sacrifice"],
    "budget_tools": ["Recommended apps, methods, or systems for their situation"],
    "success_strategies": ["3-4 strategies to stick to the budget long-term"],
    "milestone_goals": ["3-4 short and medium-term financial milestones to celebrate"]
  },
  (Include personalized_budget ONLY if next_action is "conclude")
  
  "updated_state": {
    "user_response_for_this_turn": null,
    "conversation_history": ["array of previous Q&A pairs"],
    "financial_profile": {
      "income_situation": {"value": "string or null", "status": "empty|developing|refined"},
      "fixed_expenses": {"value": "string or null", "status": "empty|developing|refined"},
      "variable_expenses": {"value": "string or null", "status": "empty|developing|refined"},
      "financial_goals": {"value": "string or null", "status": "empty|developing|refined"},
      "challenges_concerns": {"value": "string or null", "status": "empty|developing|refined"},
      "current_methods": {"value": "string or null", "status": "empty|developing|refined"},
      "lifestyle_priorities": {"value": "string or null", "status": "empty|developing|refined"}
    },
    "budget_insights": ["array of observations about their financial situation and opportunities"]
  }
}

Guidelines:
- Be encouraging and non-judgmental about all financial situations
- Recognize that everyone's financial journey is different
- Don't assume traditional employment or stable income
- Be sensitive to financial stress and systemic barriers
- Focus on progress over perfection
- Acknowledge that budgets need to be flexible and forgiving
- Celebrate small wins and incremental improvements
- Avoid toxic positivity - acknowledge when things are genuinely difficult
- Remember that financial wellness includes mental health and quality of life
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
echo -e "${C_PROMPT}💰 Welcome to Your Personal Budget Builder${C_RESET}"
echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_INFO}I'm here to help you create a budget that actually works for your life."
echo -e "No judgment, no shame - just practical support for your financial wellness."
echo ""
echo -e "We'll work together to understand your finances and build something sustainable.${C_RESET}"
echo ""
echo -e "${C_PROMPT}What brings you here today? Are you looking to get started with budgeting,${C_RESET}"
echo -e "${C_PROMPT}improve your current system, or work through a specific financial challenge?${C_RESET}"
echo -e "${C_USER}(Share whatever feels comfortable)${C_RESET}"
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
    'financial_profile': {
        'income_situation': {'value': None, 'status': 'empty'},
        'fixed_expenses': {'value': None, 'status': 'empty'},
        'variable_expenses': {'value': None, 'status': 'empty'},
        'financial_goals': {'value': None, 'status': 'empty'},
        'challenges_concerns': {'value': None, 'status': 'empty'},
        'current_methods': {'value': None, 'status': 'empty'},
        'lifestyle_priorities': {'value': None, 'status': 'empty'}
    },
    'budget_insights': []
}

print(json.dumps(initial_state))
")

# Counter for questions
QUESTION_COUNT=0
BUDGET_TYPE="unknown"

# 3. THE RECURSIVE LOOP
while true; do
    # Call Claude with the current state, get its JSON response
    echo -e "\n${C_INFO}[Thoughtfully considering your situation...]${C_RESET}"
    CLAUDE_RESPONSE=$(echo "$STATE" | claude -p "$PROMPT")
    
    # Extract JSON from potential markdown wrapper
    CLEANED_RESPONSE=$(extract_json "$CLAUDE_RESPONSE")
    
    # Basic validation
    if ! echo "$CLEANED_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
        echo -e "${C_ERROR}🔥 Error processing response. Aborting.${C_RESET}"
        echo -e "${C_ERROR}Raw response: $CLAUDE_RESPONSE${C_RESET}"
        exit 1
    fi
    
    # Extract budget type and stress level
    NEW_BUDGET_TYPE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('budget_type', 'unknown'))" 2>/dev/null || echo "unknown")
    STRESS_LEVEL=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('financial_stress_level', 'unknown'))" 2>/dev/null || echo "unknown")
    
    if [ "$NEW_BUDGET_TYPE" != "unknown" ] && [ "$NEW_BUDGET_TYPE" != "$BUDGET_TYPE" ]; then
        BUDGET_TYPE="$NEW_BUDGET_TYPE"
        echo -e "\n${C_INFO}📊 Budget approach: ${BUDGET_TYPE} mode${C_RESET}"
        if [ "$STRESS_LEVEL" = "high" ]; then
            echo -e "${C_INFO}💙 I hear that finances are stressful right now. Let's take this one step at a time.${C_RESET}"
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
        echo -e "${C_INFO}💭 (Why I'm asking: ${REASONING})${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}Question ${QUESTION_COUNT}: ${QUESTION}${C_RESET}"
        echo ""
        echo -e "${C_USER}(Remember: rough estimates are perfectly fine - we can refine later)${C_RESET}"
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
        # Extract the budget plan
        TITLE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('personalized_budget', {}).get('title', ''))")
        SUMMARY=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('personalized_budget', {}).get('executive_summary', ''))")
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_PROMPT}✅ ${TITLE}${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "$SUMMARY"
        echo ""
        
        # Extract and display budget breakdown
        echo -e "${C_PROMPT}📊 Your Monthly Budget Framework:${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        
        echo -e "${C_INFO}🏠 NEEDS (Essential Expenses - Target ~50%):${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
needs = data.get('personalized_budget', {}).get('monthly_budget_breakdown', {}).get('needs_50_percent', [])
for item in needs:
    print(f'   • {item}')
"
        echo ""
        
        echo -e "${C_INFO}😊 WANTS (Life Enjoyment - Target ~30%):${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
wants = data.get('personalized_budget', {}).get('monthly_budget_breakdown', {}).get('wants_30_percent', [])
for item in wants:
    print(f'   • {item}')
"
        echo ""
        
        echo -e "${C_INFO}💪 SAVINGS & DEBT (Future You - Target ~20%):${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
savings = data.get('personalized_budget', {}).get('monthly_budget_breakdown', {}).get('savings_20_percent', [])
for item in savings:
    print(f'   • {item}')
"
        echo ""
        
        # Extract and display quick wins
        echo -e "${C_PROMPT}⚡ Quick Wins to Free Up Money:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
wins = data.get('personalized_budget', {}).get('quick_wins', [])
for i, win in enumerate(wins, 1):
    print(f'   {i}. {win}')
"
        echo ""
        
        # Extract and display tools
        echo -e "${C_PROMPT}🛠️ Recommended Budget Tools:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
tools = data.get('personalized_budget', {}).get('budget_tools', [])
for tool in tools:
    print(f'   • {tool}')
"
        echo ""
        
        # Extract and display success strategies
        echo -e "${C_PROMPT}🎯 Strategies for Long-term Success:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
strategies = data.get('personalized_budget', {}).get('success_strategies', [])
for i, strategy in enumerate(strategies, 1):
    print(f'   {i}. {strategy}')
"
        echo ""
        
        # Extract and display milestones
        echo -e "${C_PROMPT}🏆 Milestones to Celebrate:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
milestones = data.get('personalized_budget', {}).get('milestone_goals', [])
for milestone in milestones:
    print(f'   ✓ {milestone}')
"
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_INFO}💚 Remember: This budget is a living document. Adjust it as your life changes.${C_RESET}"
        echo -e "${C_INFO}   Progress matters more than perfection. You've got this!${C_RESET}"
        
        # Save the session
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        FILENAME="personal_budget_${TIMESTAMP}.json"
        echo "$CLEANED_RESPONSE" > "$FILENAME"
        echo ""
        echo -e "${C_INFO}Your budget plan has been saved to: ${FILENAME}${C_RESET}"
        echo -e "${C_INFO}Budget type: ${BUDGET_TYPE} | Questions explored: ${QUESTION_COUNT}${C_RESET}"
        
        break # Exit the loop
    else
        echo -e "${C_ERROR}🔥 Unknown action: '$NEXT_ACTION'. Aborting.${C_RESET}"
        exit 1
    fi
done