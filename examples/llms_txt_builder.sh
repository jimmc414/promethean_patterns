#!/bin/bash

# llms_txt_builder.sh
# Adaptive Documentation Builder powered by Claude
# Can build llms.txt or other DSPy documentation through intelligent dialog

# --- Color Definitions for better UI ---
C_PROMPT='\033[1;36m' # Cyan for Claude's prompts
C_USER='\033[1;32m'   # Green for User input
C_INFO='\033[0;33m'   # Yellow for info/reasoning
C_ERROR='\033[0;31m'  # Red for errors
C_RESET='\033[0m'     # Reset color

# The adaptive documentation builder prompt
read -r -d '' PROMPT << 'EOF'
You are an expert documentation architect specializing in creating LLM-friendly documentation for software projects. Your primary expertise is in the llms.txt standard and DSPy framework documentation.

You will be given a JSON object representing the entire conversation state. Your task is to:

1. **Understand the Goal**: Determine what the user wants to document (default is llms.txt, but they may want other DSPy documentation types)

2. **Gather Information**: Ask intelligent questions to understand their project:
   - Repository structure and purpose
   - Key concepts and architecture
   - Usage patterns and examples
   - Target audience and use cases

3. **Fetch Resources When Needed**: If building DSPy documentation, you can reference docs from https://github.com/stanfordnlp/dspy/tree/main/docs/docs

4. **Track Progress**: Build up a comprehensive understanding of their project through adaptive questioning

5. **Generate Documentation**: When ready, produce high-quality documentation following best practices

You MUST respond ONLY with a single JSON object. Do not add any conversational text outside of the JSON.

Output structure:
{
  "documentation_type": "llms_txt|dspy_tutorial|dspy_module_docs|api_reference|custom",
  "confidence_level": 0.0 to 1.0,
  
  "next_action": "ask" | "offer_options" | "fetch_resource" | "generate_preview" | "finalize",
  
  "options_menu": {
    "prompt": "What would you like me to help you build?",
    "options": [
      {"id": 1, "label": "llms.txt - LLM-friendly project documentation", "description": "Standard format for helping LLMs understand your codebase"},
      {"id": 2, "label": "DSPy Tutorial - Step-by-step guide", "description": "Create a tutorial for a specific DSPy concept or pattern"},
      {"id": 3, "label": "DSPy Module Documentation", "description": "Document a custom DSPy module or signature"},
      {"id": 4, "label": "DSPy Application Example", "description": "Create a complete example application with explanations"},
      {"id": 5, "label": "Custom Documentation", "description": "Other documentation needs"}
    ]
  },
  (Include options_menu ONLY if next_action is "offer_options")
  
  "question_for_user": {
    "context": "Brief context about what we know so far",
    "question": "The specific question to ask",
    "why_asking": "Explanation of why this information is important",
    "examples": ["Optional examples to guide the user's response"]
  },
  (Include question_for_user ONLY if next_action is "ask")
  
  "resource_fetch": {
    "resource_type": "dspy_docs|github_file|reference",
    "url": "URL to fetch from",
    "purpose": "Why this resource is needed"
  },
  (Include resource_fetch ONLY if next_action is "fetch_resource")
  
  "documentation_preview": {
    "section": "Which section is ready for preview",
    "content": "The generated content for that section",
    "remaining_sections": ["List of sections still to complete"]
  },
  (Include documentation_preview ONLY if next_action is "generate_preview")
  
  "final_documentation": {
    "filename": "suggested filename (e.g., llms.txt)",
    "content": "Complete documentation content",
    "format": "markdown|plaintext|json",
    "usage_notes": "How to use this documentation"
  },
  (Include final_documentation ONLY if next_action is "finalize")
  
  "updated_state": {
    "user_response_for_this_turn": null,
    "conversation_history": ["array of previous Q&A pairs"],
    "project_canvas": {
      "project_name": {"value": "string or null", "status": "empty|partial|complete"},
      "project_type": {"value": "string or null", "status": "empty|partial|complete"},
      "repository_url": {"value": "string or null", "status": "empty|partial|complete"},
      "key_features": {"value": "array or null", "status": "empty|partial|complete"},
      "architecture": {"value": "object or null", "status": "empty|partial|complete"},
      "usage_examples": {"value": "array or null", "status": "empty|partial|complete"},
      "target_audience": {"value": "string or null", "status": "empty|partial|complete"},
      "documentation_goals": {"value": "array or null", "status": "empty|partial|complete"}
    },
    "documentation_sections": {
      "overview": {"content": "string or null", "status": "empty|draft|final"},
      "key_concepts": {"content": "string or null", "status": "empty|draft|final"},
      "architecture": {"content": "string or null", "status": "empty|draft|final"},
      "usage": {"content": "string or null", "status": "empty|draft|final"},
      "examples": {"content": "string or null", "status": "empty|draft|final"},
      "additional": {"content": "string or null", "status": "empty|draft|final"}
    },
    "builder_notes": ["array of analytical notes about the documentation"]
  }
}

Key Principles:
1. Start by understanding what type of documentation they need
2. Ask questions that reveal the essence of their project
3. Build documentation incrementally, showing previews when helpful
4. For DSPy projects, leverage knowledge of DSPy patterns and best practices
5. Adapt questioning based on project type (library, application, framework, etc.)
6. Focus on making documentation that helps LLMs understand and work with the code
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
echo -e "${C_PROMPT}📚 Welcome to the Adaptive Documentation Builder!${C_RESET}"
echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_INFO}I specialize in creating LLM-friendly documentation, particularly:"
echo -e "  • llms.txt files for any project"
echo -e "  • DSPy framework documentation and tutorials"
echo -e "  • API references and module documentation${C_RESET}"
echo ""
echo -e "${C_PROMPT}What project would you like to document? (or just say 'help' to see options)${C_RESET}"
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
    'project_canvas': {
        'project_name': {'value': None, 'status': 'empty'},
        'project_type': {'value': None, 'status': 'empty'},
        'repository_url': {'value': None, 'status': 'empty'},
        'key_features': {'value': None, 'status': 'empty'},
        'architecture': {'value': None, 'status': 'empty'},
        'usage_examples': {'value': None, 'status': 'empty'},
        'target_audience': {'value': None, 'status': 'empty'},
        'documentation_goals': {'value': None, 'status': 'empty'}
    },
    'documentation_sections': {
        'overview': {'content': None, 'status': 'empty'},
        'key_concepts': {'content': None, 'status': 'empty'},
        'architecture': {'content': None, 'status': 'empty'},
        'usage': {'content': None, 'status': 'empty'},
        'examples': {'content': None, 'status': 'empty'},
        'additional': {'content': None, 'status': 'empty'}
    },
    'builder_notes': []
}

print(json.dumps(initial_state))
")

# Counter for questions
QUESTION_COUNT=0
DOC_TYPE="unknown"

# 3. THE MAIN LOOP
while true; do
    # Call Claude with the current state
    echo -e "\n${C_INFO}[Analyzing and preparing response...]${C_RESET}"
    CLAUDE_RESPONSE=$(echo "$STATE" | claude -p "$PROMPT")
    
    # Extract JSON from potential markdown wrapper
    CLEANED_RESPONSE=$(extract_json "$CLAUDE_RESPONSE")
    
    # Basic validation
    if ! echo "$CLEANED_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
        echo -e "${C_ERROR}🔥 Error processing response. Aborting.${C_RESET}"
        echo -e "${C_ERROR}Raw response: $CLAUDE_RESPONSE${C_RESET}"
        exit 1
    fi
    
    # Extract documentation type
    NEW_DOC_TYPE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('documentation_type', 'unknown'))" 2>/dev/null || echo "unknown")
    if [ "$NEW_DOC_TYPE" != "unknown" ] && [ "$NEW_DOC_TYPE" != "$DOC_TYPE" ]; then
        DOC_TYPE="$NEW_DOC_TYPE"
        echo -e "\n${C_INFO}📄 Documentation type: ${DOC_TYPE}${C_RESET}"
    fi
    
    # Extract next action
    NEXT_ACTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('next_action', ''))")
    
    if [ "$NEXT_ACTION" = "offer_options" ]; then
        # Show options menu
        MENU_PROMPT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('options_menu', {}).get('prompt', ''))")
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_PROMPT}$MENU_PROMPT${C_RESET}"
        echo ""
        
        # Display options
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
options = data.get('options_menu', {}).get('options', [])
for opt in options:
    print(f\"  {opt['id']}. {opt['label']}\")
    print(f\"     {opt['description']}\")
    print()
"
        echo -e "${C_USER}Enter your choice (1-5) or describe what you need:${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r USER_CHOICE
        
    elif [ "$NEXT_ACTION" = "ask" ]; then
        QUESTION_COUNT=$((QUESTION_COUNT + 1))
        
        # Extract question details
        CONTEXT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('question_for_user', {}).get('context', ''))")
        QUESTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('question_for_user', {}).get('question', ''))")
        WHY=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('question_for_user', {}).get('why_asking', ''))")
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        if [ -n "$CONTEXT" ]; then
            echo -e "${C_INFO}📊 Context: $CONTEXT${C_RESET}"
        fi
        echo -e "${C_INFO}💭 (Why: $WHY)${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}❓ Question $QUESTION_COUNT: $QUESTION${C_RESET}"
        
        # Show examples if provided
        EXAMPLES=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
examples = data.get('question_for_user', {}).get('examples', [])
if examples:
    print('\nExamples:')
    for ex in examples:
        print(f'  • {ex}')
" 2>/dev/null)
        
        if [ -n "$EXAMPLES" ]; then
            echo -e "${C_INFO}$EXAMPLES${C_RESET}"
        fi
        
        echo ""
        echo -e "${C_USER}(Type your answer and press Enter)${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r USER_ANSWER
        
    elif [ "$NEXT_ACTION" = "generate_preview" ]; then
        # Show preview of generated section
        SECTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('documentation_preview', {}).get('section', ''))")
        CONTENT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('documentation_preview', {}).get('content', ''))")
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_PROMPT}📝 Preview: $SECTION${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        echo "$CONTENT"
        echo ""
        
        # Show remaining sections
        echo -e "${C_INFO}Remaining sections to complete:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
remaining = data.get('documentation_preview', {}).get('remaining_sections', [])
for section in remaining:
    print(f'  • {section}')
"
        echo ""
        echo -e "${C_USER}Continue? (yes/no/edit)${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r USER_FEEDBACK
        USER_ANSWER="$USER_FEEDBACK"
        
    elif [ "$NEXT_ACTION" = "finalize" ]; then
        # Generate final documentation
        FILENAME=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('final_documentation', {}).get('filename', 'documentation.txt'))")
        CONTENT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('final_documentation', {}).get('content', ''))")
        USAGE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('final_documentation', {}).get('usage_notes', ''))")
        
        echo ""
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo -e "${C_PROMPT}✅ Documentation Complete!${C_RESET}"
        echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        echo ""
        
        # Save the documentation
        echo "$CONTENT" > "$FILENAME"
        echo -e "${C_INFO}📄 Documentation saved to: $FILENAME${C_RESET}"
        echo ""
        echo -e "${C_INFO}$USAGE${C_RESET}"
        
        # Save the full session
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        SESSION_FILE="documentation_session_${TIMESTAMP}.json"
        echo "$CLEANED_RESPONSE" > "$SESSION_FILE"
        echo -e "${C_INFO}📋 Full session saved to: $SESSION_FILE${C_RESET}"
        
        echo ""
        echo -e "${C_INFO}Type: $DOC_TYPE | Questions asked: $QUESTION_COUNT${C_RESET}"
        
        break # Exit the loop
        
    elif [ "$NEXT_ACTION" = "fetch_resource" ]; then
        # Handle resource fetching (simulated)
        RESOURCE_URL=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('resource_fetch', {}).get('url', ''))")
        PURPOSE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('resource_fetch', {}).get('purpose', ''))")
        
        echo ""
        echo -e "${C_INFO}🔍 Fetching resource: $RESOURCE_URL${C_RESET}"
        echo -e "${C_INFO}   Purpose: $PURPOSE${C_RESET}"
        echo -e "${C_INFO}   [In a real implementation, this would fetch the resource]${C_RESET}"
        
        USER_ANSWER="Resource fetched successfully"
    else
        echo -e "${C_ERROR}🔥 Unknown action: '$NEXT_ACTION'. Aborting.${C_RESET}"
        exit 1
    fi
    
    # Update state for next iteration
    if [ "$NEXT_ACTION" != "finalize" ]; then
        STATE=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json
import sys

data = json.load(sys.stdin)
user_answer = '''${USER_ANSWER:-$USER_CHOICE}'''

# Update the state with the user's response
data['updated_state']['user_response_for_this_turn'] = user_answer

print(json.dumps(data['updated_state']))
")
    fi
done