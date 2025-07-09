#!/bin/bash

# requirements_archaeologist.sh
# Advanced Requirements Gathering System that builds mental models from multiple sources

# --- Color Definitions ---
C_PROMPT='\033[1;36m'   # Cyan
C_USER='\033[1;32m'     # Green
C_INFO='\033[0;33m'     # Yellow
C_ERROR='\033[0;31m'    # Red
C_SUCCESS='\033[1;35m'  # Magenta
C_RESET='\033[0m'       # Reset

# The master archaeological prompt
read -r -d '' ARCHAEOLOGIST_PROMPT << 'EOF'
You are a Requirements Archaeologist - an expert at excavating, analyzing, and synthesizing software requirements from multiple sources. You build comprehensive mental models of software systems by carefully examining artifacts (documents, interviews, conversations) and asking probing questions.

You will be given a JSON object containing your current mental model and new artifacts to analyze. Your task is to:

1. **Analyze New Artifacts**: Extract requirements, constraints, and insights from any new source material (interview transcripts, documents, user responses).

2. **Update Mental Model**: Continuously refine your understanding of:
   - What the software should do (functional requirements)
   - How it should perform (non-functional requirements)
   - Who will use it (user personas)
   - Why it's being built (business context)
   - What success looks like (acceptance criteria)

3. **Identify Knowledge Gaps**: Determine what critical information is still missing or unclear.

4. **Visualize Understanding**: Create clear representations of your current mental model that users can validate or correct.

5. **Generate Questions**: Ask targeted questions to fill gaps, resolve ambiguities, or validate assumptions.

6. **Produce Requirements**: When sufficient understanding is achieved, generate a comprehensive requirements.md document.

Output structure:
{
  "artifact_analysis": {
    "source_type": "interview|document|response|observation",
    "key_findings": ["important discoveries from this artifact"],
    "extracted_requirements": [
      {
        "type": "functional|non-functional",
        "category": "core|nice-to-have|future",
        "description": "clear requirement statement",
        "source_reference": "where this came from",
        "confidence": 0.0 to 1.0
      }
    ],
    "contradictions_found": ["any conflicts with existing model"],
    "implicit_requirements": ["requirements inferred but not stated"]
  },
  
  "mental_model": {
    "system_purpose": {
      "vision": "one-sentence vision",
      "problem_solved": "core problem being addressed",
      "value_proposition": "unique value provided",
      "confidence": 0.0 to 1.0
    },
    "user_personas": [
      {
        "name": "persona identifier",
        "description": "who they are",
        "goals": ["what they want to achieve"],
        "pain_points": ["current frustrations"],
        "technical_level": "novice|intermediate|expert",
        "frequency_of_use": "daily|weekly|monthly|rare"
      }
    ],
    "functional_map": {
      "core_features": [
        {
          "name": "feature name",
          "description": "what it does",
          "user_stories": ["As a X, I want Y, so that Z"],
          "priority": "must-have|should-have|nice-to-have",
          "dependencies": ["other features this requires"]
        }
      ],
      "user_journeys": [
        {
          "name": "journey name",
          "persona": "which persona",
          "steps": ["ordered list of actions"],
          "success_criteria": "what defines success"
        }
      ]
    },
    "technical_constraints": {
      "platforms": ["target platforms"],
      "integrations": ["external systems to connect with"],
      "performance": {
        "response_time": "requirements",
        "concurrent_users": "expected load",
        "data_volume": "scale expectations"
      },
      "security": ["security requirements"],
      "compliance": ["regulatory requirements"]
    },
    "success_metrics": [
      {
        "metric": "what to measure",
        "target": "specific goal",
        "measurement_method": "how to measure"
      }
    ]
  },
  
  "model_visualization": {
    "system_diagram": "ASCII or mermaid diagram of system architecture",
    "user_flow_diagram": "Key user flow visualization",
    "confidence_map": {
      "well_understood": ["areas with high confidence"],
      "partially_understood": ["areas needing clarification"],
      "unknown": ["areas requiring investigation"]
    }
  },
  
  "next_action": "question|confirm|explore|conclude",
  
  "question_for_user": {
    "context": "Why this question matters now",
    "question_text": "The specific question",
    "question_type": "clarification|validation|exploration|prioritization",
    "expected_impact": "How the answer will improve the model"
  },
  (Include only if next_action is "question")
  
  "confirmation_request": {
    "summary": "Here's my understanding of [specific aspect]...",
    "visualization": "diagram or structured representation",
    "specific_confirmations": ["Is X correct?", "Should Y be included?"],
    "correction_prompts": ["What would you change?", "What's missing?"]
  },
  (Include only if next_action is "confirm")
  
  "exploration_proposal": {
    "area": "What area to explore",
    "method": "interview|document_review|prototype|research",
    "questions_to_explore": ["specific questions for this exploration"],
    "expected_insights": ["what we hope to learn"]
  },
  (Include only if next_action is "explore")
  
  "final_requirements": {
    "completeness_score": 0.0 to 1.0,
    "risk_areas": ["areas that may need revision"],
    "requirements_document": "Complete requirements.md content (see template below)"
  },
  (Include only if next_action is "conclude")
  
  "state_update": {
    "artifacts_processed": ["list of all analyzed artifacts"],
    "conversation_history": ["previous Q&A pairs"],
    "current_phase": "discovery|analysis|validation|finalization",
    "iteration_count": int
  }
}

Requirements.md Template:
# [Project Name] Requirements Document

## Executive Summary
[2-3 paragraph overview of the project, its purpose, and key objectives]

## Vision & Goals
### Problem Statement
[Clear description of the problem being solved]

### Vision Statement  
[One sentence describing the ideal future state]

### Success Criteria
[Measurable outcomes that define success]

## User Personas
[Detailed descriptions of each user type]

## Functional Requirements
### Core Features (Must Have)
[Detailed feature descriptions with user stories]

### Secondary Features (Should Have)
[Features that enhance the experience]

### Future Enhancements (Nice to Have)
[Features for future releases]

## Non-Functional Requirements
### Performance Requirements
[Response times, load handling, etc.]

### Security Requirements
[Authentication, authorization, data protection]

### Usability Requirements
[Accessibility, user experience standards]

### Technical Constraints
[Platform requirements, integration needs]

## User Journeys
[Key workflows with step-by-step descriptions]

## System Architecture
[High-level architecture diagram and description]

## Acceptance Criteria
[Specific, testable criteria for each major feature]

## Risks & Assumptions
[Known risks and assumptions made]

## Appendices
[Supporting documents, research, references]
EOF

# Function to extract JSON from markdown wrapper
extract_json() {
    local response="$1"
    if [[ "$response" == *'```json'* ]]; then
        echo "$response" | sed -n '/```json/,/```/p' | sed '1d;$d'
    else
        echo "$response"
    fi
}

# Function to process uploaded documents
process_document() {
    local file_path="$1"
    local file_type="${file_path##*.}"
    
    echo -e "${C_INFO}📄 Processing document: $file_path${C_RESET}"
    
    # Extract content based on file type
    case "$file_type" in
        txt)
            cat "$file_path"
            ;;
        md)
            cat "$file_path"
            ;;
        pdf)
            # Use pdftotext if available
            if command -v pdftotext >/dev/null 2>&1; then
                pdftotext "$file_path" -
            else
                echo "[PDF content extraction requires pdftotext]"
            fi
            ;;
        docx)
            # Use pandoc if available
            if command -v pandoc >/dev/null 2>&1; then
                pandoc -t plain "$file_path"
            else
                echo "[DOCX content extraction requires pandoc]"
            fi
            ;;
        *)
            echo "[Unsupported file type: $file_type]"
            ;;
    esac
}

# Function to create artifact from content
create_artifact() {
    local content="$1"
    local artifact_type="$2"
    local source="$3"
    
    echo "{
        \"type\": \"$artifact_type\",
        \"source\": \"$source\",
        \"content\": $(echo "$content" | jq -Rs .),
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
    }"
}

# Initialize system
clear
echo -e "${C_PROMPT}🏛️  Welcome to the Requirements Archaeologist!${C_RESET}"
echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_INFO}I'll help you build comprehensive software requirements by analyzing multiple sources:"
echo -e "  • User interviews and conversations"
echo -e "  • Existing documentation"  
echo -e "  • Direct Q&A to fill gaps"
echo -e "  • Observations and insights${C_RESET}"
echo ""
echo -e "${C_INFO}I'll build a mental model of your software and confirm my understanding before"
echo -e "generating a complete requirements.md document.${C_RESET}"
echo ""

# Initialize state
STATE=$(python3 -c "
import json
initial_state = {
    'artifacts_processed': [],
    'conversation_history': [],
    'current_phase': 'discovery',
    'iteration_count': 0,
    'mental_model': {
        'system_purpose': {'vision': None, 'confidence': 0.0},
        'user_personas': [],
        'functional_map': {'core_features': [], 'user_journeys': []},
        'technical_constraints': {},
        'success_metrics': []
    }
}
print(json.dumps(initial_state))
")

# Main interaction loop
ITERATION=0
MAX_ITERATIONS=20

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ((ITERATION++))
    
    # First iteration - gather initial input
    if [ $ITERATION -eq 1 ]; then
        echo -e "${C_PROMPT}Let's start by understanding your software idea.${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}You can:${C_RESET}"
        echo -e "${C_INFO}  1. Describe your idea directly"
        echo -e "  2. Upload interview transcripts (type 'upload')"
        echo -e "  3. Upload existing documents (type 'upload')"
        echo -e "  4. Paste a user story or conversation (type 'paste')${C_RESET}"
        echo ""
        echo -e "${C_PROMPT}What would you like to start with?${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r USER_INPUT
        
        ARTIFACT=""
        
        # Handle different input types
        case "$USER_INPUT" in
            upload)
                echo -e "${C_PROMPT}Enter the path to your file:${C_RESET}"
                echo -n -e "${C_USER}➤ ${C_RESET}"
                read -r FILE_PATH
                
                if [ -f "$FILE_PATH" ]; then
                    CONTENT=$(process_document "$FILE_PATH")
                    ARTIFACT=$(create_artifact "$CONTENT" "document" "$FILE_PATH")
                else
                    echo -e "${C_ERROR}File not found: $FILE_PATH${C_RESET}"
                    continue
                fi
                ;;
            paste)
                echo -e "${C_PROMPT}Paste your content (type 'END' on a new line when done):${C_RESET}"
                CONTENT=""
                while IFS= read -r line; do
                    [ "$line" = "END" ] && break
                    CONTENT+="$line"$'\n'
                done
                ARTIFACT=$(create_artifact "$CONTENT" "interview" "pasted_content")
                ;;
            *)
                ARTIFACT=$(create_artifact "$USER_INPUT" "response" "initial_description")
                ;;
        esac
    else
        # Subsequent iterations based on Claude's guidance
        ARTIFACT=$(create_artifact "$USER_INPUT" "response" "user_response")
    fi
    
    # Prepare input for Claude
    CLAUDE_INPUT=$(python3 -c "
import json
import sys

state = json.loads('''$STATE''')
artifact = json.loads('''$ARTIFACT''')

claude_input = {
    'current_state': state,
    'new_artifact': artifact
}

print(json.dumps(claude_input))
")
    
    # Call Claude
    echo -e "\n${C_INFO}[Analyzing and updating mental model...]${C_RESET}"
    CLAUDE_RESPONSE=$(echo "$CLAUDE_INPUT" | claude -p "$ARCHAEOLOGIST_PROMPT")
    
    # Extract and validate JSON
    CLEANED_RESPONSE=$(extract_json "$CLAUDE_RESPONSE")
    
    if ! echo "$CLEANED_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
        echo -e "${C_ERROR}🔥 Error processing response. Trying to recover...${C_RESET}"
        continue
    fi
    
    # Extract next action
    NEXT_ACTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('next_action', ''))")
    
    # Update state
    STATE=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json
import sys

response = json.load(sys.stdin)
state = response.get('state_update', {})
state['mental_model'] = response.get('mental_model', {})

print(json.dumps(state))
")
    
    # Handle different actions
    case "$NEXT_ACTION" in
        question)
            # Extract question details
            CONTEXT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('question_for_user', {}).get('context', ''))")
            QUESTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('question_for_user', {}).get('question_text', ''))")
            IMPACT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('question_for_user', {}).get('expected_impact', ''))")
            
            echo ""
            echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            echo -e "${C_INFO}📍 Context: $CONTEXT${C_RESET}"
            echo -e "${C_INFO}💡 Why this matters: $IMPACT${C_RESET}"
            echo ""
            echo -e "${C_PROMPT}❓ $QUESTION${C_RESET}"
            echo ""
            echo -e "${C_USER}Your answer:${C_RESET}"
            echo -n -e "${C_USER}➤ ${C_RESET}"
            read -r USER_INPUT
            ;;
            
        confirm)
            # Show mental model visualization for confirmation
            SUMMARY=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('confirmation_request', {}).get('summary', ''))")
            VISUALIZATION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('confirmation_request', {}).get('visualization', ''))")
            
            echo ""
            echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            echo -e "${C_SUCCESS}🧠 Mental Model Checkpoint${C_RESET}"
            echo ""
            echo -e "$SUMMARY"
            echo ""
            echo -e "${C_INFO}$VISUALIZATION${C_RESET}"
            echo ""
            
            # Show specific confirmations
            echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
confirmations = data.get('confirmation_request', {}).get('specific_confirmations', [])
for i, conf in enumerate(confirmations, 1):
    print(f'  ✓ {conf}')
"
            echo ""
            echo -e "${C_PROMPT}Is this understanding correct? (yes/no/clarify)${C_RESET}"
            echo -n -e "${C_USER}➤ ${C_RESET}"
            read -r USER_INPUT
            ;;
            
        explore)
            # Suggest exploration
            AREA=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('exploration_proposal', {}).get('area', ''))")
            METHOD=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('exploration_proposal', {}).get('method', ''))")
            
            echo ""
            echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            echo -e "${C_INFO}🔍 Exploration Needed${C_RESET}"
            echo -e "${C_INFO}Area: $AREA${C_RESET}"
            echo -e "${C_INFO}Suggested method: $METHOD${C_RESET}"
            echo ""
            echo -e "${C_PROMPT}Would you like to:${C_RESET}"
            echo -e "${C_INFO}  1. Upload relevant documents"
            echo -e "  2. Provide this information directly"
            echo -e "  3. Skip this exploration${C_RESET}"
            echo -n -e "${C_USER}➤ ${C_RESET}"
            read -r USER_INPUT
            ;;
            
        conclude)
            # Generate final requirements
            COMPLETENESS=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('final_requirements', {}).get('completeness_score', 0))")
            REQUIREMENTS_MD=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('final_requirements', {}).get('requirements_document', ''))")
            
            echo ""
            echo -e "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            echo -e "${C_SUCCESS}✅ Requirements Analysis Complete!${C_RESET}"
            echo -e "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            echo ""
            echo -e "${C_INFO}Completeness Score: $(printf "%.0f%%" $(echo "$COMPLETENESS * 100" | bc -l))${C_RESET}"
            echo ""
            
            # Save requirements document
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            FILENAME="requirements_${TIMESTAMP}.md"
            echo "$REQUIREMENTS_MD" > "$FILENAME"
            
            echo -e "${C_SUCCESS}📄 Requirements document saved to: $FILENAME${C_RESET}"
            echo ""
            
            # Show risk areas if any
            echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
risks = data.get('final_requirements', {}).get('risk_areas', [])
if risks:
    print('⚠️  Areas that may need future refinement:')
    for risk in risks:
        print(f'   • {risk}')
"
            
            # Save full session
            SESSION_FILE="requirements_session_${TIMESTAMP}.json"
            echo "$CLEANED_RESPONSE" > "$SESSION_FILE"
            echo -e "${C_INFO}Full session saved to: $SESSION_FILE${C_RESET}"
            
            break
            ;;
            
        *)
            echo -e "${C_ERROR}Unknown action: $NEXT_ACTION${C_RESET}"
            ;;
    esac
done

if [ $ITERATION -eq $MAX_ITERATIONS ]; then
    echo -e "${C_ERROR}Reached maximum iterations. Saving current state...${C_RESET}"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    echo "$STATE" > "requirements_incomplete_${TIMESTAMP}.json"
fi