# Generic State Machine Template Guide

## Overview

This template provides a reusable foundation for building AI-powered applications using the state machine pattern. It's based on the elegant design from `llms_txt_builder.sh` but made completely generic.

## Key Architecture Components

### 1. **State Machine Core**
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   State     │────▶│     AI      │────▶│   Action    │
│  (JSON)     │     │  (Claude)   │     │  Handler    │
└─────────────┘     └─────────────┘     └─────────────┘
       ▲                                        │
       └────────────────────────────────────────┘
                    Update State
```

### 2. **State Structure**
The state contains everything the AI needs to make decisions:
- `user_response`: Latest user input
- `conversation_history`: Full dialogue history
- `data_store`: Your custom data fields
- `process_state`: Where we are in the workflow
- `session_metadata`: Tracking information

### 3. **Action Types**
- `ask`: Get information from user
- `menu`: Show options
- `process`: Run operations
- `preview`: Show results for review
- `complete`: Finish and save
- `custom_action`: Your own actions

## Customization Guide

### Step 1: Define Your Use Case

Replace placeholders in the `SYSTEM_PROMPT`:

```bash
# Original
You are an intelligent assistant operating within a state machine framework. 
Your role is to [DESCRIBE YOUR AI'S PURPOSE HERE].

# Example: Recipe Builder
You are a culinary expert helping users create custom recipes. 
Your role is to gather dietary preferences, available ingredients, 
and cooking skills to generate personalized recipes.
```

### Step 2: Customize the State Structure

Modify the `data_store` in initial state:

```python
'data_store': {
    # Generic
    'field1': {'value': None, 'status': 'empty', 'metadata': {}},
    
    # Recipe Builder Example
    'dietary_restrictions': {'value': None, 'status': 'empty', 'metadata': {}},
    'available_ingredients': {'value': [], 'status': 'empty', 'metadata': {}},
    'cuisine_preference': {'value': None, 'status': 'empty', 'metadata': {}},
    'cooking_time': {'value': None, 'status': 'empty', 'metadata': {}},
    'skill_level': {'value': None, 'status': 'empty', 'metadata': {}},
}
```

### Step 3: Add Custom Actions

Create handlers for your specific needs:

```bash
# In the custom action section
"generate_recipe")
    INGREDIENTS=$(safe_json_get "$CLEANED_RESPONSE" "custom_action.parameters.ingredients")
    CUISINE=$(safe_json_get "$CLEANED_RESPONSE" "custom_action.parameters.cuisine")
    
    # Generate recipe logic
    generate_recipe "$INGREDIENTS" "$CUISINE" > "$SESSION_DIR/recipe.txt"
    
    USER_RESPONSE="Recipe generated successfully"
    ;;
```

### Step 4: Define Decision Guidelines

Update the guidelines in the prompt:

```
Decision-making guidelines:
1. Start by understanding dietary restrictions and allergies
2. Gather available ingredients before suggesting recipes  
3. Match recipe complexity to stated skill level
4. Always provide alternatives for uncommon ingredients
```

## Example Transformations

### 1. **Interview Assistant**
```bash
APP_NAME="Smart Interview Assistant"
# Tracks: questions_asked, candidate_responses, evaluation_scores
# Actions: ask_behavioral, ask_technical, evaluate_response, generate_report
```

### 2. **Trip Planner**
```bash
APP_NAME="Personalized Trip Planner"
# Tracks: destinations, dates, budget, interests, accommodations
# Actions: suggest_destinations, plan_itinerary, book_preview, finalize_trip
```

### 3. **Learning Path Creator**
```bash
APP_NAME="Adaptive Learning Path Generator"
# Tracks: learning_goals, current_knowledge, time_available, resources
# Actions: assess_level, suggest_topics, create_schedule, track_progress
```

## Advanced Features

### 1. **Multi-Modal State**
Add support for different data types:
```python
'data_store': {
    'text_data': {'value': "string", 'type': 'text'},
    'numeric_data': {'value': 42, 'type': 'number'},
    'file_data': {'value': "/path/to/file", 'type': 'file'},
    'structured_data': {'value': {...}, 'type': 'json'}
}
```

### 2. **Branching Logic**
The AI can implement complex flows:
```json
{
  "next_action": "ask",
  "branch_condition": {
    "if_user_says": ["yes", "continue"],
    "then_phase": "detailed_questions",
    "else_phase": "summary"
  }
}
```

### 3. **Progress Tracking**
Built-in progress monitoring:
```python
'process_state': {
    'current_phase': 'gathering_requirements',
    'phases_completed': ['initialization', 'basic_info'],
    'percent_complete': 45.0,
    'estimated_remaining': 3  # interactions
}
```

### 4. **State Persistence**
Save and resume sessions:
```bash
# Save state
echo "$STATE" > "$SESSION_DIR/checkpoint.json"

# Resume later
if [ -f "checkpoint.json" ]; then
    STATE=$(cat checkpoint.json)
fi
```

## Best Practices

### 1. **Clear Action Definitions**
Each action should have a single, clear purpose. Don't overload actions with multiple responsibilities.

### 2. **Meaningful State Updates**
Always update the state with relevant information, not just user responses:
```python
new_state['data_store']['ingredients']['value'] = parsed_ingredients
new_state['data_store']['ingredients']['status'] = 'complete'
new_state['data_store']['ingredients']['metadata']['count'] = len(parsed_ingredients)
```

### 3. **Error Recovery**
Add fallback behavior for each action:
```bash
if [ -z "$USER_RESPONSE" ]; then
    USER_RESPONSE="No response provided"
    log_both "${C_INFO}Using default response${C_RESET}"
fi
```

### 4. **Validation Hooks**
Add validation before state updates:
```bash
validate_user_input() {
    local input="$1"
    local input_type="$2"
    
    case "$input_type" in
        "email")
            [[ "$input" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
            ;;
        "number")
            [[ "$input" =~ ^[0-9]+$ ]]
            ;;
    esac
}
```

## Debugging Tips

### 1. **Enable Verbose Logging**
```bash
DEBUG=true  # Add at the top
[ "$DEBUG" = true ] && log_file "Debug: $VARIABLE"
```

### 2. **State Inspection**
```bash
# Add this anywhere to inspect current state
echo "$STATE" | jq '.' > "$SESSION_DIR/state_snapshot_$INTERACTION_COUNT.json"
```

### 3. **AI Response Analysis**
```bash
# Save raw AI responses for debugging
echo "$AI_RESPONSE" > "$SESSION_DIR/ai_response_$INTERACTION_COUNT.txt"
```

## Common Patterns

### 1. **Progressive Disclosure**
Start with high-level questions, then drill down:
```
Phase 1: "What type of project?" → General category
Phase 2: "What specific features?" → Detailed requirements  
Phase 3: "Technical constraints?" → Implementation details
```

### 2. **Validation Loops**
Keep asking until valid input:
```json
{
  "next_action": "ask",
  "ask_user": {
    "question": "Please provide a valid email address",
    "validation": "email_format",
    "retry_on_invalid": true
  }
}
```

### 3. **Multi-Step Processes**
Chain actions together:
```
gather_data → validate → process → preview → confirm → finalize
```

## Extending the Template

### Adding New Action Types

1. Define in the prompt:
```json
"next_action": "analyze_sentiment"
```

2. Add handler in the case statement:
```bash
"analyze_sentiment")
    TEXT=$(safe_json_get "$CLEANED_RESPONSE" "sentiment_analysis.text")
    RESULT=$(analyze_sentiment_function "$TEXT")
    USER_RESPONSE="Sentiment: $RESULT"
    ;;
```

### Creating Reusable Modules

```bash
# modules/file_handler.sh
handle_file_upload() {
    local file_path="$1"
    # Implementation
}

# In main script
source modules/file_handler.sh
```

## Conclusion

This template provides a flexible foundation for building any conversational AI application. The key is to:

1. Clearly define your use case
2. Map your data to the state structure
3. Implement appropriate action handlers
4. Let the AI handle the flow logic

The beauty of this pattern is that the AI adapts to each conversation, making decisions based on context rather than following rigid paths.