#!/bin/bash

# example_recipe_builder.sh
# Example implementation using the generic state machine template
# This builds a personalized recipe assistant

# --- Color Definitions ---
C_PROMPT='\033[1;36m'  # Cyan
C_USER='\033[1;32m'    # Green  
C_INFO='\033[0;33m'    # Yellow
C_ERROR='\033[0;31m'   # Red
C_SUCCESS='\033[0;32m' # Green
C_RESET='\033[0m'      # Reset

# --- Application Settings ---
APP_NAME="AI Recipe Builder"
APP_VERSION="1.0.0"
SESSION_DIR="recipes/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$SESSION_DIR/session.log"

mkdir -p "$SESSION_DIR"

# --- Recipe Builder Prompt ---
read -r -d '' SYSTEM_PROMPT << 'EOF'
You are a friendly culinary expert helping users create personalized recipes. You adapt recipes based on dietary restrictions, available ingredients, cooking skills, and preferences.

You will receive a JSON object representing the current state and must respond with a JSON object specifying the next action.

Your capabilities:
1. **Dietary Analysis**: Understand restrictions (vegan, gluten-free, allergies, etc.)
2. **Ingredient Matching**: Work with what users have available
3. **Skill Adaptation**: Adjust complexity based on cooking experience
4. **Recipe Generation**: Create detailed, easy-to-follow recipes

You MUST respond ONLY with a single JSON object.

Output structure:
{
  "analysis": {
    "current_situation": "What information we have gathered",
    "user_intent": "What kind of recipe they want",
    "confidence": 0.0 to 1.0
  },
  
  "next_action": "ask|menu|generate_recipe|preview|complete",
  
  "ask_user": {
    "context": "Why you need this information",
    "question": "Your specific question",
    "input_type": "text|choice|multiline",
    "examples": ["Example answers"]
  },
  
  "show_menu": {
    "title": "Menu title",
    "prompt": "What to ask the user",
    "options": [
      {"id": 1, "label": "Option", "description": "Details"}
    ]
  },
  
  "generate_recipe": {
    "recipe_name": "Name of the dish",
    "cuisine": "Type of cuisine",
    "difficulty": "easy|medium|hard",
    "prep_time": "X minutes",
    "cook_time": "Y minutes",
    "servings": "Number of servings",
    "ingredients": ["List of ingredients with amounts"],
    "instructions": ["Step by step instructions"],
    "tips": ["Helpful tips"],
    "nutritional_info": "Basic nutritional information"
  },
  
  "preview_result": {
    "title": "Recipe Preview",
    "content": "The formatted recipe",
    "format": "markdown"
  },
  
  "final_output": {
    "summary": "What we created",
    "recipe": "Complete recipe",
    "alternatives": ["Suggested variations"],
    "shopping_list": ["Items you might need to buy"]
  },
  
  "state_update": {
    "user_response": null,
    "conversation_history": [],
    "recipe_profile": {
      "dietary_restrictions": {"value": null, "status": "empty"},
      "available_ingredients": {"value": [], "status": "empty"},
      "cuisine_preference": {"value": null, "status": "empty"},
      "meal_type": {"value": null, "status": "empty"},
      "cooking_time": {"value": null, "status": "empty"},
      "skill_level": {"value": null, "status": "empty"},
      "servings_needed": {"value": null, "status": "empty"}
    },
    "process_state": {
      "current_phase": "initialization|gathering|generating|reviewing|complete",
      "info_completeness": 0.0
    }
  }
}

Decision-making guidelines:
1. Always start by checking for dietary restrictions and allergies
2. Gather core requirements before suggesting specific recipes
3. Adapt complexity to match stated skill level
4. Provide substitutions for uncommon ingredients
5. Include prep/cook times and difficulty ratings
EOF

# --- Helper Functions ---

log_both() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

extract_json() {
    local response="$1"
    if [[ "$response" == *'```json'* ]]; then
        echo "$response" | sed -n '/```json/,/```/p' | sed '1d;$d'
    else
        echo "$response"
    fi
}

safe_json_get() {
    local json="$1"
    local field="$2"
    local default="${3:-}"
    
    echo "$json" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    keys = '$field'.split('.')
    result = data
    for key in keys:
        result = result.get(key, '$default')
    print(result if result is not None else '$default')
except:
    print('$default')
" 2>/dev/null || echo "$default"
}

# --- Initialize ---

clear
log_both "${C_PROMPT}🍳 Welcome to AI Recipe Builder!${C_RESET}"
log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
log_both ""
log_both "${C_INFO}I'll help you create a personalized recipe based on:${C_RESET}"
log_both "${C_INFO}  • Your dietary needs${C_RESET}"
log_both "${C_INFO}  • Available ingredients${C_RESET}"
log_both "${C_INFO}  • Cooking skill level${C_RESET}"
log_both "${C_INFO}  • Time constraints${C_RESET}"
log_both ""

log_both "${C_PROMPT}What kind of meal are you thinking about?${C_RESET}"
log_both "${C_USER}(e.g., 'quick dinner', 'healthy lunch', 'dessert', or just 'help')${C_RESET}"
echo -n -e "${C_USER}➤ ${C_RESET}"
read -r INITIAL_INPUT

if [ -z "$INITIAL_INPUT" ]; then
    log_both "${C_ERROR}No input provided. Exiting...${C_RESET}"
    exit 1
fi

# Initialize state
STATE=$(python3 -c "
import json
from datetime import datetime

initial_input = '''$INITIAL_INPUT'''

initial_state = {
    'user_response': initial_input,
    'conversation_history': [],
    'recipe_profile': {
        'dietary_restrictions': {'value': None, 'status': 'empty'},
        'available_ingredients': {'value': [], 'status': 'empty'},
        'cuisine_preference': {'value': None, 'status': 'empty'},
        'meal_type': {'value': None, 'status': 'empty'},
        'cooking_time': {'value': None, 'status': 'empty'},
        'skill_level': {'value': None, 'status': 'empty'},
        'servings_needed': {'value': None, 'status': 'empty'}
    },
    'process_state': {
        'current_phase': 'initialization',
        'info_completeness': 0.0
    },
    'session_metadata': {
        'session_id': '$(basename $SESSION_DIR)',
        'start_time': datetime.now().isoformat()
    }
}

print(json.dumps(initial_state))
")

# --- Main Loop ---

CONTINUE_LOOP=true
QUESTION_COUNT=0

while $CONTINUE_LOOP; do
    log_both "\n${C_INFO}[Thinking about your recipe...]${C_RESET}"
    
    # Get AI response
    AI_RESPONSE=$(echo "$STATE" | claude -p "$SYSTEM_PROMPT" 2>&1)
    CLEANED_RESPONSE=$(extract_json "$AI_RESPONSE")
    
    # Validate JSON
    if ! echo "$CLEANED_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
        log_both "${C_ERROR}Error processing response. Retrying...${C_RESET}"
        continue
    fi
    
    # Extract action
    NEXT_ACTION=$(safe_json_get "$CLEANED_RESPONSE" "next_action" "unknown")
    
    case "$NEXT_ACTION" in
        "ask")
            QUESTION_COUNT=$((QUESTION_COUNT + 1))
            CONTEXT=$(safe_json_get "$CLEANED_RESPONSE" "ask_user.context")
            QUESTION=$(safe_json_get "$CLEANED_RESPONSE" "ask_user.question")
            
            log_both ""
            log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            if [ -n "$CONTEXT" ]; then
                log_both "${C_INFO}💭 $CONTEXT${C_RESET}"
            fi
            log_both "${C_PROMPT}Question $QUESTION_COUNT: $QUESTION${C_RESET}"
            
            # Show examples if provided
            EXAMPLES=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
examples = data.get('ask_user', {}).get('examples', [])
if examples:
    print('\\nExamples: ' + ', '.join(examples))
" 2>/dev/null)
            
            if [ -n "$EXAMPLES" ]; then
                log_both "${C_INFO}$EXAMPLES${C_RESET}"
            fi
            
            echo -n -e "${C_USER}➤ ${C_RESET}"
            read -r USER_RESPONSE
            ;;
            
        "menu")
            MENU_TITLE=$(safe_json_get "$CLEANED_RESPONSE" "show_menu.title")
            
            log_both ""
            log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both "${C_PROMPT}$MENU_TITLE${C_RESET}"
            log_both ""
            
            echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
options = data.get('show_menu', {}).get('options', [])
for opt in options:
    print(f\"  {opt['id']}. {opt['label']}\")
    if opt.get('description'):
        print(f\"     {opt['description']}\")
"
            echo -n -e "${C_USER}➤ ${C_RESET}"
            read -r USER_RESPONSE
            ;;
            
        "generate_recipe"|"preview")
            # Extract recipe details
            if [ "$NEXT_ACTION" = "generate_recipe" ]; then
                RECIPE_NAME=$(safe_json_get "$CLEANED_RESPONSE" "generate_recipe.recipe_name")
                CONTENT=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
recipe = data.get('generate_recipe', {})

print(f\"# {recipe.get('recipe_name', 'Recipe')}\")
print(f\"\\n**Cuisine:** {recipe.get('cuisine', 'N/A')}\")
print(f\"**Difficulty:** {recipe.get('difficulty', 'N/A')}\")
print(f\"**Prep Time:** {recipe.get('prep_time', 'N/A')}\")
print(f\"**Cook Time:** {recipe.get('cook_time', 'N/A')}\")
print(f\"**Servings:** {recipe.get('servings', 'N/A')}\")

print(\"\\n## Ingredients\")
for ing in recipe.get('ingredients', []):
    print(f\"- {ing}\")

print(\"\\n## Instructions\")
for i, step in enumerate(recipe.get('instructions', []), 1):
    print(f\"{i}. {step}\")

if recipe.get('tips'):
    print(\"\\n## Tips\")
    for tip in recipe['tips']:
        print(f\"- {tip}\")

if recipe.get('nutritional_info'):
    print(f\"\\n## Nutritional Information\")
    print(recipe['nutritional_info'])
")
            else:
                RECIPE_NAME=$(safe_json_get "$CLEANED_RESPONSE" "preview_result.title")
                CONTENT=$(safe_json_get "$CLEANED_RESPONSE" "preview_result.content")
            fi
            
            log_both ""
            log_both "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both "${C_SUCCESS}📖 $RECIPE_NAME${C_RESET}"
            log_both "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both ""
            log_both "$CONTENT"
            log_both ""
            
            # Save recipe
            echo "$CONTENT" > "$SESSION_DIR/recipe.md"
            log_both "${C_INFO}Recipe saved to: $SESSION_DIR/recipe.md${C_RESET}"
            
            log_both ""
            log_both "${C_USER}Happy with this recipe? (yes/no/modify)${C_RESET}"
            echo -n -e "${C_USER}➤ ${C_RESET}"
            read -r USER_RESPONSE
            ;;
            
        "complete")
            SUMMARY=$(safe_json_get "$CLEANED_RESPONSE" "final_output.summary")
            
            log_both ""
            log_both "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both "${C_SUCCESS}✅ Recipe Complete!${C_RESET}"
            log_both "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both ""
            log_both "${C_INFO}$SUMMARY${C_RESET}"
            
            # Generate shopping list
            SHOPPING_LIST=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
items = data.get('final_output', {}).get('shopping_list', [])
if items:
    print('\\n📝 Shopping List:')
    for item in items:
        print(f'  □ {item}')
" 2>/dev/null)
            
            if [ -n "$SHOPPING_LIST" ]; then
                log_both "$SHOPPING_LIST"
                echo "$SHOPPING_LIST" > "$SESSION_DIR/shopping_list.txt"
            fi
            
            log_both ""
            log_both "${C_INFO}All files saved in: $SESSION_DIR${C_RESET}"
            
            CONTINUE_LOOP=false
            ;;
            
        *)
            log_both "${C_ERROR}Unexpected response. Let me try again...${C_RESET}"
            USER_RESPONSE="Please continue"
            ;;
    esac
    
    # Update state
    if $CONTINUE_LOOP; then
        STATE=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json
import sys

data = json.load(sys.stdin)
user_response = '''${USER_RESPONSE}'''

new_state = data.get('state_update', {})
new_state['user_response'] = user_response

# Update conversation history
if 'conversation_history' not in new_state:
    new_state['conversation_history'] = []

# Add Q&A to history
if data.get('ask_user', {}).get('question'):
    new_state['conversation_history'].extend([
        {'role': 'assistant', 'content': data['ask_user']['question']},
        {'role': 'user', 'content': user_response}
    ])

print(json.dumps(new_state))
")
    fi
done

log_both ""
log_both "${C_PROMPT}Thanks for using AI Recipe Builder! Enjoy your meal! 🍽️${C_RESET}"