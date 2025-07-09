#!/bin/bash

# tax_assistant.sh
# Adaptive Tax Filing Assistant powered by Claude

# --- Color Definitions for better UI ---
C_PROMPT='\033[1;36m' # Cyan for Claude's prompts
C_USER='\033[1;32m'   # Green for User input
C_INFO='\033[0;33m'   # Yellow for info/reasoning
C_ERROR='\033[0;31m'  # Red for errors
C_RESET='\033[0m'     # Reset color

# The tax filing assistant prompt
read -r -d '' PROMPT << 'EOF'
You are an experienced tax preparation assistant. Your goal is to help users understand their tax situation and prepare for filing through intelligent, adaptive questioning.

IMPORTANT: You are providing educational guidance only, not professional tax advice. Always remind users to consult a tax professional for specific situations.

You will be given a JSON object representing the entire conversation state. Your task is to:

1. **Determine Tax Profile**: Understand their filing status, income sources, and general situation without being intrusive.

2. **Identify Relevant Areas**: Based on their responses, focus on the tax areas most relevant to them:
   - Income types (W-2, 1099, business, investments)
   - Deductions (standard vs. itemized)
   - Credits they may qualify for
   - Special situations (self-employment, rental income, etc.)

3. **Guide Through Requirements**: Help them understand what documents they need and what to expect.

4. **Educational Focus**: Explain tax concepts in simple terms as you go.

5. **Practical Next Steps**: Conclude with a clear checklist tailored to their situation.

You MUST respond ONLY with a single JSON object. Do not add any conversational text outside of the JSON. Do not wrap the JSON in markdown code blocks.

Output structure:
{
  "tax_complexity": "simple|moderate|complex",
  "filing_status_detected": "single|married_joint|married_separate|head_of_household|unknown",
  
  "next_action": "ask" or "conclude",
  
  "question_for_user": {
    "progress_update": "Brief summary of what we've established about their tax situation.",
    "question_text": "The next most important question to understand their tax situation.",
    "question_reasoning": "Why this information is important for their taxes."
  },
  (Include question_for_user ONLY if next_action is "ask")
  
  "tax_preparation_guide": {
    "title": "Your [Year] Tax Preparation Guide",
    "executive_summary": "A comprehensive overview of their tax situation and filing requirements.",
    "documents_needed": ["List of specific documents they need to gather"],
    "potential_deductions": ["List of deductions they should explore based on their situation"],
    "potential_credits": ["List of tax credits they might qualify for"],
    "filing_recommendations": ["Specific recommendations for their filing process"],
    "important_deadlines": ["Key dates and deadlines relevant to their situation"]
  },
  (Include tax_preparation_guide ONLY if next_action is "conclude")
  
  "updated_state": {
    "user_response_for_this_turn": null,
    "conversation_history": ["array of previous Q&A pairs"],
    "tax_profile": {
      "filing_status": {"value": "string or null", "status": "empty|developing|refined"},
      "income_sources": {"value": "string or null", "status": "empty|developing|refined"},
      "employment_type": {"value": "string or null", "status": "empty|developing|refined"},
      "deduction_type": {"value": "string or null", "status": "empty|developing|refined"},
      "special_situations": {"value": "string or null", "status": "empty|developing|refined"},
      "prior_year_filing": {"value": "string or null", "status": "empty|developing|refined"},
      "state_considerations": {"value": "string or null", "status": "empty|developing|refined"}
    },
    "tax_notes": ["array of important observations about their tax situation"]
  }
}

Guidelines:
- Be clear about this being educational guidance, not professional tax advice
- Use plain language, avoid jargon unless explaining it
- Be sensitive about financial topics
- Don't assume income levels or financial situations
- Focus on federal taxes unless they mention state-specific needs
- For current tax year, check the date and adjust accordingly
- Always mention consulting a tax professional for complex situations
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
echo -e "${C_PROMPT}📊 Welcome to the Tax Preparation Assistant${C_RESET}"
echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_INFO}I'll help you understand your tax situation and prepare for filing."
echo -e "This is educational guidance to help you get organized - not professional tax advice."
echo ""
echo -e "I'll ask you some questions to understand your situation and create a personalized checklist.${C_RESET}"
echo ""
echo -e "${C_PROMPT}Let's start with the basics: Are you preparing for this year's taxes, or catching up on a previous year?${C_RESET}"
echo -e "${C_USER}(You can also share any specific tax questions or concerns you have)${C_RESET}"
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
    'tax_profile': {
        'filing_status': {'value': None, 'status': 'empty'},
        'income_sources': {'value': None, 'status': 'empty'},
        'employment_type': {'value': None, 'status': 'empty'},
        'deduction_type': {'value': None, 'status': 'empty'},
        'special_situations': {'value': None, 'status': 'empty'},
        'prior_year_filing': {'value': None, 'status': 'empty'},
        'state_considerations': {'value': None, 'status': 'empty'}
    },
    'tax_notes': []
}

print(json.dumps(initial_state))
")

# Counter for questions
QUESTION_COUNT=0
COMPLEXITY="unknown"

# 3. THE RECURSIVE LOOP
while true; do
    # Call Claude with the current state, get its JSON response
    echo -e "\n${C_INFO}[Analyzing your tax situation...]${C_RESET}"
    CLAUDE_RESPONSE=$(echo "$STATE" | claude -p "$PROMPT")
    
    # Extract JSON from potential markdown wrapper
    CLEANED_RESPONSE=$(extract_json "$CLAUDE_RESPONSE")
    
    # Basic validation
    if ! echo "$CLEANED_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
        echo -e "${C_ERROR}🔥 Error processing response. Aborting.${C_RESET}"
        echo -e "${C_ERROR}Raw response: $CLAUDE_RESPONSE${C_RESET}"
        exit 1
    fi
    
    # Extract complexity and filing status
    NEW_COMPLEXITY=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('tax_complexity', 'unknown'))" 2>/dev/null || echo "unknown")
    FILING_STATUS=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('filing_status_detected', 'unknown'))" 2>/dev/null || echo "unknown")
    
    if [ "$NEW_COMPLEXITY" != "unknown" ] && [ "$NEW_COMPLEXITY" != "$COMPLEXITY" ]; then
        COMPLEXITY="$NEW_COMPLEXITY"
        echo -e "\n${C_INFO}📈 Tax situation complexity: ${COMPLEXITY}${C_RESET}"
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
        echo -e "${C_INFO}📋 ${PROGRESS}${C_RESET}"
        echo -e "${C_INFO}💡 (Why this matters: ${REASONING})${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}Question ${QUESTION_COUNT}: ${QUESTION}${C_RESET}"
        echo ""
        echo -e "${C_USER}(Your privacy is important - share only what you're comfortable with)${C_RESET}"
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
        # Extract the tax guide
        TITLE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('tax_preparation_guide', {}).get('title', ''))")
        SUMMARY=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('tax_preparation_guide', {}).get('executive_summary', ''))")
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_PROMPT}✅ ${TITLE}${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo -e "$SUMMARY"
        echo ""
        
        # Extract and display documents needed
        echo -e "${C_PROMPT}📄 Documents You'll Need:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
docs = data.get('tax_preparation_guide', {}).get('documents_needed', [])
for i, doc in enumerate(docs, 1):
    print(f'   {i}. {doc}')
"
        echo ""
        
        # Extract and display potential deductions
        echo -e "${C_PROMPT}💰 Potential Deductions to Explore:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
deductions = data.get('tax_preparation_guide', {}).get('potential_deductions', [])
for i, deduction in enumerate(deductions, 1):
    print(f'   • {deduction}')
"
        echo ""
        
        # Extract and display potential credits
        echo -e "${C_PROMPT}🎯 Tax Credits You Might Qualify For:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
credits = data.get('tax_preparation_guide', {}).get('potential_credits', [])
for i, credit in enumerate(credits, 1):
    print(f'   • {credit}')
"
        echo ""
        
        # Extract and display filing recommendations
        echo -e "${C_PROMPT}📝 Filing Recommendations:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
recs = data.get('tax_preparation_guide', {}).get('filing_recommendations', [])
for i, rec in enumerate(recs, 1):
    print(f'   {i}. {rec}')
"
        echo ""
        
        # Extract and display deadlines
        echo -e "${C_PROMPT}📅 Important Deadlines:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
deadlines = data.get('tax_preparation_guide', {}).get('important_deadlines', [])
for deadline in deadlines:
    print(f'   • {deadline}')
"
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_INFO}⚠️  Remember: This is educational guidance only. For specific tax advice,${C_RESET}"
        echo -e "${C_INFO}   please consult a qualified tax professional or CPA.${C_RESET}"
        
        # Save the session
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        FILENAME="tax_prep_guide_${TIMESTAMP}.json"
        echo "$CLEANED_RESPONSE" > "$FILENAME"
        echo ""
        echo -e "${C_INFO}Your tax preparation guide has been saved to: ${FILENAME}${C_RESET}"
        echo -e "${C_INFO}Tax complexity: ${COMPLEXITY} | Questions asked: ${QUESTION_COUNT}${C_RESET}"
        
        break # Exit the loop
    else
        echo -e "${C_ERROR}🔥 Unknown action: '$NEXT_ACTION'. Aborting.${C_RESET}"
        exit 1
    fi
done