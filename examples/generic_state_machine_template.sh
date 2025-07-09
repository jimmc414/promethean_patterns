#!/bin/bash

# generic_state_machine_template.sh
# A reusable template for building adaptive AI-powered state machines
# Based on the elegant pattern from llms_txt_builder.sh

# ============================================================================
# CONFIGURATION SECTION - Customize these for your use case
# ============================================================================

# --- Color Definitions (customize your color scheme) ---
C_PROMPT='\033[1;36m'  # Main prompt color
C_USER='\033[1;32m'    # User input color
C_INFO='\033[0;33m'    # Information/context color
C_ERROR='\033[0;31m'   # Error messages
C_SUCCESS='\033[0;32m' # Success messages
C_RESET='\033[0m'      # Reset to default

# --- Application Settings ---
APP_NAME="Generic State Machine"
APP_VERSION="1.0.0"
SESSION_DIR="sessions/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$SESSION_DIR/session.log"

# --- Create session directory ---
mkdir -p "$SESSION_DIR"

# ============================================================================
# MAIN PROMPT - This is where you define your AI's behavior
# ============================================================================

read -r -d '' SYSTEM_PROMPT << 'EOF'
You are an intelligent assistant operating within a state machine framework. Your role is to [DESCRIBE YOUR AI'S PURPOSE HERE].

You will receive a JSON object representing the current state and must respond with a JSON object specifying the next action.

Your capabilities:
1. **[CAPABILITY 1]**: [Description]
2. **[CAPABILITY 2]**: [Description]
3. **[CAPABILITY 3]**: [Description]

You MUST respond ONLY with a single JSON object. Do not add any conversational text outside of the JSON.

Output structure:
{
  "analysis": {
    "current_situation": "Your understanding of where we are",
    "user_intent": "What you think the user wants",
    "confidence": 0.0 to 1.0
  },
  
  "next_action": "ask|menu|process|preview|complete|custom_action",
  
  "ask_user": {
    "context": "Why you need this information",
    "question": "Your specific question",
    "input_type": "text|number|choice|multiline",
    "validation": "Any validation rules",
    "examples": ["Example answers to guide the user"]
  },
  (Include ask_user ONLY when next_action is "ask")
  
  "show_menu": {
    "title": "Menu title",
    "prompt": "What to ask the user",
    "options": [
      {"id": 1, "label": "Option 1", "description": "What this does"},
      {"id": 2, "label": "Option 2", "description": "What this does"}
    ],
    "allow_custom": true
  },
  (Include show_menu ONLY when next_action is "menu")
  
  "process_data": {
    "operation": "What you're doing with the data",
    "input_data": "Data to process",
    "expected_output": "What will be produced",
    "show_progress": true
  },
  (Include process_data ONLY when next_action is "process")
  
  "preview_result": {
    "title": "What you're previewing",
    "content": "The preview content",
    "format": "text|json|markdown|custom",
    "actions_available": ["approve", "edit", "regenerate", "cancel"]
  },
  (Include preview_result ONLY when next_action is "preview")
  
  "final_output": {
    "summary": "What was accomplished",
    "main_result": "The primary output",
    "additional_files": [
      {"filename": "file1.txt", "content": "content", "description": "what this is"}
    ],
    "next_steps": ["Suggested follow-up actions"]
  },
  (Include final_output ONLY when next_action is "complete")
  
  "custom_action": {
    "action_type": "your_custom_type",
    "parameters": {},
    "description": "What this custom action does"
  },
  (Define your own custom actions as needed)
  
  "state_update": {
    "user_response": null,
    "conversation_history": [
      {"role": "assistant", "content": "previous assistant message"},
      {"role": "user", "content": "previous user message"}
    ],
    "data_store": {
      "field1": {"value": "data", "status": "empty|partial|complete", "metadata": {}},
      "field2": {"value": "data", "status": "empty|partial|complete", "metadata": {}},
      "[YOUR_FIELDS]": {"value": null, "status": "empty", "metadata": {}}
    },
    "process_state": {
      "current_phase": "initialization|gathering|processing|reviewing|complete",
      "phases_completed": ["phase1", "phase2"],
      "percent_complete": 0.0
    },
    "session_metadata": {
      "session_id": "unique_id",
      "start_time": "timestamp",
      "interaction_count": 0,
      "custom_metrics": {}
    }
  }
}

Decision-making guidelines:
1. [GUIDELINE 1]: [Explanation]
2. [GUIDELINE 2]: [Explanation]
3. [GUIDELINE 3]: [Explanation]

Remember to:
- Maintain context across interactions
- Adapt your approach based on user responses
- Provide clear reasoning for your decisions
- Track progress toward the goal
EOF

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Function to log to both screen and file
log_both() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Function to log to file only
log_file() {
    echo -e "$1" >> "$LOG_FILE"
}

# Function to extract JSON from potential markdown wrapper
extract_json() {
    local response="$1"
    if [[ "$response" == *'```json'* ]]; then
        echo "$response" | sed -n '/```json/,/```/p' | sed '1d;$d'
    else
        echo "$response"
    fi
}

# Function to safely extract JSON field
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

# Function to validate JSON
validate_json() {
    echo "$1" | python3 -m json.tool > /dev/null 2>&1
}

# ============================================================================
# CUSTOM ACTION HANDLERS - Add your specific handlers here
# ============================================================================

# Example: Handle file operations
handle_file_operation() {
    local operation="$1"
    local filepath="$2"
    local content="$3"
    
    case "$operation" in
        "read")
            # Add file reading logic
            log_both "${C_INFO}Reading file: $filepath${C_RESET}"
            ;;
        "write")
            # Add file writing logic
            log_both "${C_INFO}Writing to file: $filepath${C_RESET}"
            ;;
        *)
            log_both "${C_ERROR}Unknown file operation: $operation${C_RESET}"
            ;;
    esac
}

# Example: Handle API calls
handle_api_call() {
    local endpoint="$1"
    local method="$2"
    local data="$3"
    
    # Add your API handling logic here
    log_both "${C_INFO}API Call: $method $endpoint${C_RESET}"
}

# Add more custom handlers as needed...

# ============================================================================
# INITIALIZATION
# ============================================================================

# Clear screen and show welcome message
clear
log_both "${C_PROMPT}╔═══════════════════════════════════════════════════════════════════╗${C_RESET}"
log_both "${C_PROMPT}║                    $APP_NAME v$APP_VERSION                    ║${C_RESET}"
log_both "${C_PROMPT}╚═══════════════════════════════════════════════════════════════════╝${C_RESET}"
log_both ""
log_both "${C_INFO}[CUSTOMIZE THIS WELCOME MESSAGE]${C_RESET}"
log_both "${C_INFO}Session ID: $(basename $SESSION_DIR)${C_RESET}"
log_both ""

# Get initial input
log_both "${C_PROMPT}[YOUR INITIAL PROMPT TO USER]${C_RESET}"
log_both "${C_USER}Type your response:${C_RESET}"
echo -n -e "${C_USER}➤ ${C_RESET}"
read -r INITIAL_INPUT

# Validate input
if [ -z "$INITIAL_INPUT" ]; then
    log_both "${C_ERROR}No input provided. Exiting...${C_RESET}"
    exit 1
fi

log_file "Initial input: $INITIAL_INPUT"

# ============================================================================
# INITIALIZE STATE
# ============================================================================

# Create initial state - customize this structure for your needs
STATE=$(python3 -c "
import json
import sys
from datetime import datetime

initial_input = '''$INITIAL_INPUT'''

initial_state = {
    'user_response': initial_input,
    'conversation_history': [],
    'data_store': {
        # Define your data fields here
        'field1': {'value': None, 'status': 'empty', 'metadata': {}},
        'field2': {'value': None, 'status': 'empty', 'metadata': {}},
        # Add more fields as needed
    },
    'process_state': {
        'current_phase': 'initialization',
        'phases_completed': [],
        'percent_complete': 0.0
    },
    'session_metadata': {
        'session_id': '$(basename $SESSION_DIR)',
        'start_time': datetime.now().isoformat(),
        'interaction_count': 0,
        'custom_metrics': {}
    }
}

print(json.dumps(initial_state, indent=2))
")

# ============================================================================
# MAIN STATE MACHINE LOOP
# ============================================================================

# Initialize counters and flags
INTERACTION_COUNT=0
CONTINUE_LOOP=true

while $CONTINUE_LOOP; do
    INTERACTION_COUNT=$((INTERACTION_COUNT + 1))
    
    # --- STEP 1: Send state to AI and get response ---
    log_both "\n${C_INFO}[Processing...]${C_RESET}"
    log_file "=== Interaction $INTERACTION_COUNT ==="
    log_file "Current state: $STATE"
    
    # Call AI with current state
    AI_RESPONSE=$(echo "$STATE" | claude -p "$SYSTEM_PROMPT" 2>&1)
    
    # Extract JSON from response
    CLEANED_RESPONSE=$(extract_json "$AI_RESPONSE")
    log_file "AI response: $CLEANED_RESPONSE"
    
    # --- STEP 2: Validate response ---
    if ! validate_json "$CLEANED_RESPONSE"; then
        log_both "${C_ERROR}Error: Invalid response from AI${C_RESET}"
        log_file "Invalid JSON: $AI_RESPONSE"
        
        # Attempt recovery
        log_both "${C_INFO}Attempting recovery...${C_RESET}"
        continue
    fi
    
    # --- STEP 3: Extract action and metadata ---
    NEXT_ACTION=$(safe_json_get "$CLEANED_RESPONSE" "next_action" "unknown")
    CONFIDENCE=$(safe_json_get "$CLEANED_RESPONSE" "analysis.confidence" "0.0")
    
    log_both "${C_INFO}Action: $NEXT_ACTION | Confidence: $CONFIDENCE${C_RESET}"
    
    # --- STEP 4: Handle each action type ---
    case "$NEXT_ACTION" in
        "ask")
            # Extract question details
            CONTEXT=$(safe_json_get "$CLEANED_RESPONSE" "ask_user.context")
            QUESTION=$(safe_json_get "$CLEANED_RESPONSE" "ask_user.question")
            INPUT_TYPE=$(safe_json_get "$CLEANED_RESPONSE" "ask_user.input_type" "text")
            
            # Display question
            log_both ""
            log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            if [ -n "$CONTEXT" ]; then
                log_both "${C_INFO}Context: $CONTEXT${C_RESET}"
            fi
            log_both "${C_PROMPT}Question: $QUESTION${C_RESET}"
            
            # Show examples if provided
            # [Add example extraction logic here]
            
            # Get user input based on type
            case "$INPUT_TYPE" in
                "multiline")
                    log_both "${C_USER}(Type your response, press Ctrl+D when done)${C_RESET}"
                    USER_RESPONSE=$(cat)
                    ;;
                "number")
                    log_both "${C_USER}(Enter a number)${C_RESET}"
                    echo -n -e "${C_USER}➤ ${C_RESET}"
                    read -r USER_RESPONSE
                    # [Add number validation here]
                    ;;
                *)
                    log_both "${C_USER}(Type your response)${C_RESET}"
                    echo -n -e "${C_USER}➤ ${C_RESET}"
                    read -r USER_RESPONSE
                    ;;
            esac
            ;;
            
        "menu")
            # Extract menu details
            MENU_TITLE=$(safe_json_get "$CLEANED_RESPONSE" "show_menu.title")
            MENU_PROMPT=$(safe_json_get "$CLEANED_RESPONSE" "show_menu.prompt")
            
            # Display menu
            log_both ""
            log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both "${C_PROMPT}$MENU_TITLE${C_RESET}"
            log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            
            # [Add menu option extraction and display logic here]
            
            log_both ""
            log_both "${C_PROMPT}$MENU_PROMPT${C_RESET}"
            echo -n -e "${C_USER}➤ ${C_RESET}"
            read -r USER_RESPONSE
            ;;
            
        "process")
            # Handle data processing
            OPERATION=$(safe_json_get "$CLEANED_RESPONSE" "process_data.operation")
            
            log_both ""
            log_both "${C_INFO}Processing: $OPERATION${C_RESET}"
            
            # [Add your processing logic here]
            # Example: handle_custom_processing "$CLEANED_RESPONSE"
            
            USER_RESPONSE="Processing completed"
            ;;
            
        "preview")
            # Show preview
            PREVIEW_TITLE=$(safe_json_get "$CLEANED_RESPONSE" "preview_result.title")
            PREVIEW_CONTENT=$(safe_json_get "$CLEANED_RESPONSE" "preview_result.content")
            
            log_both ""
            log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both "${C_PROMPT}Preview: $PREVIEW_TITLE${C_RESET}"
            log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both ""
            log_both "$PREVIEW_CONTENT"
            log_both ""
            
            log_both "${C_USER}Actions: approve | edit | regenerate | cancel${C_RESET}"
            echo -n -e "${C_USER}➤ ${C_RESET}"
            read -r USER_RESPONSE
            ;;
            
        "complete")
            # Handle completion
            SUMMARY=$(safe_json_get "$CLEANED_RESPONSE" "final_output.summary")
            MAIN_RESULT=$(safe_json_get "$CLEANED_RESPONSE" "final_output.main_result")
            
            log_both ""
            log_both "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both "${C_SUCCESS}✅ Process Complete!${C_RESET}"
            log_both "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both ""
            log_both "${C_INFO}Summary: $SUMMARY${C_RESET}"
            
            # Save final output
            echo "$MAIN_RESULT" > "$SESSION_DIR/output.txt"
            log_both "${C_SUCCESS}Output saved to: $SESSION_DIR/output.txt${C_RESET}"
            
            # [Add any additional file saving logic here]
            
            # Save final state
            echo "$CLEANED_RESPONSE" > "$SESSION_DIR/final_state.json"
            
            CONTINUE_LOOP=false
            ;;
            
        "custom_action")
            # Handle custom actions
            ACTION_TYPE=$(safe_json_get "$CLEANED_RESPONSE" "custom_action.action_type")
            
            log_both "${C_INFO}Custom action: $ACTION_TYPE${C_RESET}"
            
            # Route to appropriate handler
            case "$ACTION_TYPE" in
                "file_operation")
                    # handle_file_operation ...
                    ;;
                "api_call")
                    # handle_api_call ...
                    ;;
                *)
                    log_both "${C_ERROR}Unknown custom action: $ACTION_TYPE${C_RESET}"
                    ;;
            esac
            
            USER_RESPONSE="Action completed"
            ;;
            
        *)
            log_both "${C_ERROR}Unknown action: $NEXT_ACTION${C_RESET}"
            USER_RESPONSE="Please continue"
            ;;
    esac
    
    # --- STEP 5: Update state for next iteration ---
    if $CONTINUE_LOOP; then
        # Update state with user response and new information
        STATE=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json
import sys

data = json.load(sys.stdin)
user_response = '''${USER_RESPONSE}'''

# Get the state update from AI response
new_state = data.get('state_update', {})

# Add user response
new_state['user_response'] = user_response

# Update conversation history
if 'conversation_history' not in new_state:
    new_state['conversation_history'] = []

# Add current interaction to history
if data.get('ask_user', {}).get('question'):
    new_state['conversation_history'].append({
        'role': 'assistant',
        'content': data['ask_user']['question']
    })
    new_state['conversation_history'].append({
        'role': 'user',
        'content': user_response
    })

# Update interaction count
if 'session_metadata' not in new_state:
    new_state['session_metadata'] = {}
new_state['session_metadata']['interaction_count'] = $INTERACTION_COUNT

print(json.dumps(new_state, indent=2))
")
        
        log_file "Updated state: $STATE"
    fi
done

# ============================================================================
# CLEANUP AND EXIT
# ============================================================================

log_both ""
log_both "${C_INFO}Session complete. Files saved in: $SESSION_DIR${C_RESET}"
log_both "${C_INFO}Total interactions: $INTERACTION_COUNT${C_RESET}"
log_both ""
log_both "${C_PROMPT}Thank you for using $APP_NAME!${C_RESET}"

# [Add any cleanup operations here]

exit 0