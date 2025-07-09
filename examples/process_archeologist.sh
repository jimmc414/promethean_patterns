#!/bin/bash

# process_archaeologist.sh
# Discovers and documents real-world processes through intelligent excavation

# --- Color Definitions ---
C_PROMPT='\033[1;36m'   # Cyan
C_USER='\033[1;32m'     # Green  
C_INFO='\033[0;33m'     # Yellow
C_DISCOVERY='\033[1;35m' # Magenta for discoveries
C_ERROR='\033[0;31m'    # Red
C_RESET='\033[0m'       # Reset

# The Process Archaeologist master prompt
read -r -d '' ARCHAEOLOGIST_PROMPT << 'EOF'
You are a Process Archaeologist - an expert at uncovering how work actually gets done in organizations.
Your mission is to build a complete mental model of a process through careful excavation of knowledge from multiple sources.

You will receive a JSON state containing interview transcripts, document excerpts, and your evolving process model.

Your archaeological method:
1. **Excavate**: Extract process fragments from interviews and documents
2. **Reconstruct**: Piece together the actual workflow (not the idealized version)
3. **Identify Gaps**: Find discrepancies between documented and actual processes
4. **Map Hidden Paths**: Discover unofficial workarounds and tribal knowledge
5. **Build Model**: Create a comprehensive mental model of how things really work

You MUST respond with a single JSON object:

{
  "excavation_phase": "discovery|reconstruction|validation|documentation",
  "confidence_level": 0.0 to 1.0,
  
  "discoveries": [
    {
      "type": "process_step|decision_point|hidden_dependency|workaround|tool|stakeholder",
      "description": str,
      "source": "interview_X|document_Y",
      "importance": "critical|high|medium|low"
    }
  ],
  
  "process_model": {
    "nodes": [
      {
        "id": str,
        "type": "start|step|decision|integration|end",
        "name": str,
        "description": str,
        "actors": [str],
        "tools": [str],
        "actual_vs_documented": "matches|differs|undocumented",
        "pain_points": [str],
        "tribal_knowledge": [str]
      }
    ],
    "edges": [
      {
        "from": node_id,
        "to": node_id,
        "condition": str,
        "probability": float,
        "is_official": bool,
        "is_workaround": bool
      }
    ],
    "parallel_tracks": [
      {
        "name": str,
        "nodes": [node_id],
        "description": "Things that happen simultaneously"
      }
    ]
  },
  
  "knowledge_gaps": [
    {
      "area": str,
      "impact": "blocks_understanding|creates_ambiguity|minor",
      "suggested_question": str,
      "suggested_interviewee": str
    }
  ],
  
  "next_action": "interview|analyze_document|validate_finding|generate_docs|conclude",
  
  "interview_request": {
    "target_role": str,
    "focus_area": str,
    "key_questions": [
      {
        "question": str,
        "purpose": "discover_step|validate_assumption|find_exception|uncover_workaround"
      }
    ],
    "expected_insights": [str]
  },
  (Include interview_request ONLY if next_action is "interview")
  
  "document_request": {
    "document_type": "sop|email|ticket|code|config|training_material",
    "search_terms": [str],
    "extraction_focus": str
  },
  (Include document_request ONLY if next_action is "analyze_document")
  
  "validation_check": {
    "finding_to_validate": str,
    "validation_method": "cross_reference|walk_through|observation",
    "validation_questions": [str]
  },
  (Include validation_check ONLY if next_action is "validate_finding")
  
  "generated_artifacts": {
    "process_documentation": {
      "executive_summary": str,
      "detailed_workflow": str,
      "swim_lane_diagram": str,
      "raci_matrix": dict
    },
    "training_materials": {
      "new_employee_guide": str,
      "quick_reference_card": str,
      "common_scenarios": [{"scenario": str, "steps": [str]}]
    },
    "automation_opportunities": [
      {
        "step": str,
        "automation_potential": "high|medium|low",
        "suggested_approach": str
      }
    ],
    "improvement_recommendations": [
      {
        "issue": str,
        "impact": str,
        "recommendation": str,
        "effort": "low|medium|high"
      }
    ]
  },
  (Include generated_artifacts ONLY if next_action is "generate_docs")
  
  "archaeological_notes": [
    "Insights about the organization's culture and how work really flows"
  ],
  
  "updated_state": {
    "interviews_conducted": [
      {
        "interviewee_role": str,
        "key_revelations": [str],
        "transcript": str
      }
    ],
    "documents_analyzed": [
      {
        "document_name": str,
        "type": str,
        "key_findings": [str],
        "discrepancies_found": [str]
      }
    ],
    "process_model": "current complete model",
    "confidence_scores": {
      "area": float
    }
  }
}
EOF

# Document analyzer prompt
read -r -d '' DOCUMENT_ANALYZER << 'EOF'
Extract process information from this document.

Focus on:
- Explicit process steps
- Implicit assumptions  
- Tools and systems mentioned
- People and roles involved
- Time constraints and dependencies
- Exception handling
- Undocumented knowledge hints

Output JSON: {
  "process_fragments": [
    {
      "type": "step|rule|exception|tool|role",
      "content": str,
      "confidence": float,
      "context_clues": [str]
    }
  ],
  "inconsistencies": [
    "Things that don't match other sources"
  ],
  "hidden_complexity": [
    "Things glossed over that are probably complex"
  ]
}
EOF

# Initialize state
init_state() {
    python3 -c "
import json

initial_state = {
    'interviews_conducted': [],
    'documents_analyzed': [],
    'process_model': {
        'nodes': [],
        'edges': [],
        'parallel_tracks': []
    },
    'confidence_scores': {}
}

print(json.dumps(initial_state))
"
}

# Function to conduct interview
conduct_interview() {
    local role="$1"
    local questions="$2"
    
    echo -e "${C_PROMPT}🎤 Interviewing: $role${C_RESET}"
    echo -e "${C_INFO}[This is a simulated interview. In production, integrate with video call transcription]${C_RESET}"
    
    # Display questions
    echo "$questions" | python3 -c "
import json, sys
questions = json.load(sys.stdin)
for i, q in enumerate(questions, 1):
    print(f'\nQuestion {i}: {q[\"question\"]}')
    print(f'Purpose: {q[\"purpose\"]}')
"
    
    echo -e "\n${C_USER}Enter interview responses (or paste transcript):${C_RESET}"
    read -r -d '' INTERVIEW_RESPONSE
    
    echo "$INTERVIEW_RESPONSE"
}

# Function to analyze document
analyze_document() {
    local doc_path="$1"
    local doc_type="$2"
    
    if [ -f "$doc_path" ]; then
        echo -e "${C_INFO}📄 Analyzing $doc_type: $doc_path${C_RESET}"
        
        # Extract process info from document
        DOC_CONTENT=$(cat "$doc_path")
        DOC_ANALYSIS=$(echo "$DOC_CONTENT" | claude -p "$DOCUMENT_ANALYZER")
        
        echo "$DOC_ANALYSIS"
    else
        echo -e "${C_ERROR}Document not found: $doc_path${C_RESET}"
        echo "{}"
    fi
}

# Function to visualize process model
visualize_process() {
    local model="$1"
    
    echo -e "\n${C_DISCOVERY}🗺️  Current Process Model:${C_RESET}"
    echo "$model" | python3 -c "
import json, sys

model = json.load(sys.stdin)

print('\n=== PROCESS NODES ===')
for node in model['nodes']:
    status = '✓' if node['actual_vs_documented'] == 'matches' else '⚠' if node['actual_vs_documented'] == 'differs' else '❓'
    print(f'{status} [{node[\"id\"]}] {node[\"name\"]}')
    if node['actors']:
        print(f'   Actors: {', '.join(node[\"actors\"])}')
    if node['pain_points']:
        print(f'   ⚡ Pain points: {'; '.join(node[\"pain_points\"])}')
    if node['tribal_knowledge']:
        print(f'   🧠 Tribal knowledge: {'; '.join(node[\"tribal_knowledge\"])}')

print('\n=== PROCESS FLOWS ===')
for edge in model['edges']:
    flow_type = '-->' if edge['is_official'] else '~~>' if edge['is_workaround'] else '..>'
    print(f'{edge[\"from\"]} {flow_type} {edge[\"to\"]}', end='')
    if edge['condition']:
        print(f' [{edge[\"condition\"]}]', end='')
    print()
"
}

# Main execution
clear
echo -e "${C_PROMPT}🏛️  Welcome to the Process Archaeologist!${C_RESET}"
echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_INFO}I'll help you uncover how processes really work in your organization"
echo -e "through intelligent interviews and document analysis.${C_RESET}"
echo ""
echo -e "${C_PROMPT}What process would you like to excavate?${C_RESET}"
echo -e "${C_USER}(e.g., 'customer onboarding', 'incident response', 'code deployment')${C_RESET}"
echo -n -e "${C_USER}➤ ${C_RESET}"
read -r PROCESS_NAME

# Initialize
STATE=$(init_state)
EXCAVATION_COUNT=0
MAX_EXCAVATIONS=20

echo -e "\n${C_INFO}🏗️  Beginning archaeological excavation of: ${PROCESS_NAME}${C_RESET}"

# Check for existing documents
echo -e "\n${C_PROMPT}Do you have any existing documentation? (y/n)${C_RESET}"
read -r HAS_DOCS

if [ "$HAS_DOCS" = "y" ]; then
    echo -e "${C_USER}Enter document paths (one per line, empty line to finish):${C_RESET}"
    DOCUMENTS=()
    while IFS= read -r doc_path; do
        [ -z "$doc_path" ] && break
        DOCUMENTS+=("$doc_path")
    done
fi

# Main excavation loop
while [ $EXCAVATION_COUNT -lt $MAX_EXCAVATIONS ]; do
    ((EXCAVATION_COUNT++))
    
    echo -e "\n${C_INFO}[Excavation Round $EXCAVATION_COUNT]${C_RESET}"
    
    # Prepare current context
    CONTEXT=$(python3 -c "
import json

state = $STATE
context = {
    'process_name': '$PROCESS_NAME',
    'excavation_round': $EXCAVATION_COUNT,
    'current_state': state
}

print(json.dumps(context))
")
    
    # Get next archaeological action
    ARCHAEOLOGY_RESPONSE=$(echo "$CONTEXT" | claude -p "$ARCHAEOLOGIST_PROMPT")
    
    # Extract and clean response
    CLEANED_RESPONSE=$(echo "$ARCHAEOLOGY_RESPONSE" | sed -n '/^{/,/^}/p')
    
    # Get next action
    NEXT_ACTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('next_action', ''))")
    
    # Show discoveries
    echo -e "\n${C_DISCOVERY}⛏️  New Discoveries:${C_RESET}"
    echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for d in data.get('discoveries', []):
    icon = '🔍' if d['type'] == 'process_step' else '⚡' if d['type'] == 'pain_point' else '🔀'
    print(f'{icon} {d[\"description\"]} [{d[\"importance\"]}]')
"
    
    # Visualize current model
    CURRENT_MODEL=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
print(json.dumps(json.load(sys.stdin).get('process_model', {})))
")
    visualize_process "$CURRENT_MODEL"
    
    # Execute next action
    case "$NEXT_ACTION" in
        "interview")
            INTERVIEW_INFO=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
print(json.dumps(json.load(sys.stdin).get('interview_request', {})))
")
            TARGET_ROLE=$(echo "$INTERVIEW_INFO" | python3 -c "import json, sys; print(json.load(sys.stdin).get('target_role', ''))")
            QUESTIONS=$(echo "$INTERVIEW_INFO" | python3 -c "import json, sys; print(json.dumps(json.load(sys.stdin).get('key_questions', [])))")
            
            INTERVIEW_RESULT=$(conduct_interview "$TARGET_ROLE" "$QUESTIONS")
            
            # Update state with interview
            STATE=$(python3 -c "
import json
state = $STATE
interview = {
    'interviewee_role': '$TARGET_ROLE',
    'key_revelations': [],
    'transcript': '''$INTERVIEW_RESULT'''
}
state['interviews_conducted'].append(interview)
print(json.dumps(state))
")
            ;;
            
        "analyze_document")
            if [ ${#DOCUMENTS[@]} -gt 0 ]; then
                DOC_PATH="${DOCUMENTS[0]}"
                DOCUMENTS=("${DOCUMENTS[@]:1}")  # Remove first element
                
                DOC_ANALYSIS=$(analyze_document "$DOC_PATH" "document")
                
                # Update state with document analysis
                STATE=$(python3 -c "
import json
state = $STATE
doc_info = {
    'document_name': '$DOC_PATH',
    'type': 'analyzed',
    'key_findings': [],
    'discrepancies_found': []
}
state['documents_analyzed'].append(doc_info)
print(json.dumps(state))
")
            else
                echo -e "${C_INFO}No more documents to analyze${C_RESET}"
            fi
            ;;
            
        "validate_finding")
            VALIDATION_INFO=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
print(json.dumps(json.load(sys.stdin).get('validation_check', {})))
")
            
            echo -e "\n${C_PROMPT}🔍 Validation Required:${C_RESET}"
            echo "$VALIDATION_INFO" | python3 -c "
import json, sys
v = json.load(sys.stdin)
print(f'Finding: {v.get(\"finding_to_validate\", \"\")}')
print(f'Method: {v.get(\"validation_method\", \"\")}')
for q in v.get('validation_questions', []):
    print(f'- {q}')
"
            
            echo -e "\n${C_USER}Enter validation results:${C_RESET}"
            read -r VALIDATION_RESULT
            ;;
            
        "generate_docs")
            echo -e "\n${C_PROMPT}📚 Generating Documentation Suite...${C_RESET}"
            
            ARTIFACTS=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
print(json.dumps(json.load(sys.stdin).get('generated_artifacts', {})))
")
            
            # Save all generated documents
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            OUTPUT_DIR="process_archaeology_${PROCESS_NAME}_${TIMESTAMP}"
            mkdir -p "$OUTPUT_DIR"
            
            # Save each artifact type
            echo "$ARTIFACTS" | python3 -c "
import json, sys, os

artifacts = json.load(sys.stdin)
output_dir = '$OUTPUT_DIR'

# Process documentation
if 'process_documentation' in artifacts:
    docs = artifacts['process_documentation']
    with open(f'{output_dir}/process_guide.md', 'w') as f:
        f.write(f'# {\"$PROCESS_NAME\".title()} Process Guide\\n\\n')
        f.write(f'## Executive Summary\\n{docs.get(\"executive_summary\", \"\")}\\n\\n')
        f.write(f'## Detailed Workflow\\n{docs.get(\"detailed_workflow\", \"\")}\\n\\n')
        f.write(f'## RACI Matrix\\n{docs.get(\"raci_matrix\", \"\")}\\n')
    
    with open(f'{output_dir}/swim_lane_diagram.mermaid', 'w') as f:
        f.write(docs.get('swim_lane_diagram', ''))

# Training materials
if 'training_materials' in artifacts:
    training = artifacts['training_materials']
    with open(f'{output_dir}/new_employee_guide.md', 'w') as f:
        f.write(training.get('new_employee_guide', ''))
    
    with open(f'{output_dir}/quick_reference.md', 'w') as f:
        f.write(training.get('quick_reference_card', ''))

# Improvements
if 'improvement_recommendations' in artifacts:
    with open(f'{output_dir}/improvement_plan.md', 'w') as f:
        f.write('# Process Improvement Recommendations\\n\\n')
        for rec in artifacts['improvement_recommendations']:
            f.write(f'## {rec[\"issue\"]}\\n')
            f.write(f'**Impact:** {rec[\"impact\"]}\\n')
            f.write(f'**Recommendation:** {rec[\"recommendation\"]}\\n')
            f.write(f'**Effort:** {rec[\"effort\"]}\\n\\n')

print(f'✅ Documentation saved to {output_dir}/')
"
            
            echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            echo -e "${C_PROMPT}✅ Archaeological excavation complete!${C_RESET}"
            echo -e "${C_INFO}Excavation rounds: $EXCAVATION_COUNT${C_RESET}"
            echo -e "${C_INFO}Documents generated in: $OUTPUT_DIR/${C_RESET}"
            break
            ;;
            
        "conclude")
            echo -e "\n${C_PROMPT}✅ Process archaeology complete!${C_RESET}"
            
            # Show final insights
            echo -e "\n${C_DISCOVERY}🏛️  Archaeological Insights:${C_RESET}"
            echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for note in data.get('archaeological_notes', []):
    print(f'• {note}')
"
            break
            ;;
            
        *)
            echo -e "${C_ERROR}Unknown action: $NEXT_ACTION${C_RESET}"
            break
            ;;
    esac
    
    # Update state
    STATE=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
print(json.dumps(json.load(sys.stdin).get('updated_state', {})))
")
done