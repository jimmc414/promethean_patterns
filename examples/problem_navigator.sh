#!/bin/bash

# problem_navigator.sh
# Multi-Modal Problem Understanding & Solution Evolution System

# --- Color Definitions ---
C_PROMPT='\033[1;36m'   # Cyan
C_USER='\033[1;32m'     # Green  
C_INFO='\033[0;33m'     # Yellow
C_ERROR='\033[0;31m'    # Red
C_SUCCESS='\033[1;35m'  # Magenta
C_RESET='\033[0m'       # Reset

# The Problem Space Navigator Master Prompt
read -r -d '' NAVIGATOR_PROMPT << 'EOF'
You are a Problem Space Navigator - a system that builds deep mental models of problems through multiple lenses and evolves solutions iteratively.

You will receive a JSON state object containing all gathered intelligence. Your role evolves through phases:

PHASE 1 - DISCOVERY: Gather intelligence through interviews and documents
PHASE 2 - SYNTHESIS: Build a mental model of the problem space  
PHASE 3 - IDEATION: Generate solution hypotheses
PHASE 4 - PROTOTYPING: Create implementation plans
PHASE 5 - CALIBRATION: Test assumptions and refine

You MUST respond with ONLY a single JSON object. No other text.

Output structure:
{
  "current_phase": "discovery|synthesis|ideation|prototyping|calibration",
  "phase_progress": 0.0 to 1.0,
  
  "mental_model": {
    "problem_topology": {
      "core_problem": "string",
      "problem_layers": {
        "surface_symptoms": ["visible issues"],
        "underlying_causes": ["root causes"],
        "systemic_factors": ["environmental factors"]
      },
      "stakeholder_map": {
        "stakeholder_type": {
          "pain_points": ["list"],
          "desires": ["list"],
          "constraints": ["list"]
        }
      }
    },
    "knowledge_graph": {
      "entities": [{"id": "string", "type": "concept|person|system|process", "properties": {}}],
      "relationships": [{"from": "id", "to": "id", "type": "causes|blocks|enables|requires"}]
    },
    "uncertainty_map": {
      "known_unknowns": ["what we know we don't know"],
      "assumptions": [{"assumption": "string", "confidence": 0.0-1.0, "impact": "high|medium|low"}],
      "knowledge_gaps": ["areas needing investigation"]
    }
  },
  
  "next_action": "interview|analyze_doc|synthesize|generate_solution|test|conclude",
  
  "interview_request": {
    "target_profile": "Who to interview next and why",
    "interview_goals": ["what to learn"],
    "dynamic_questions": [
      {
        "question": "string",
        "follow_up_triggers": {"keyword": "follow_up_question"},
        "insight_extraction": "what pattern to look for"
      }
    ]
  },
  (Include ONLY if next_action is "interview")
  
  "document_request": {
    "document_type": "What kind of document would help",
    "extraction_focus": ["what to look for"],
    "parsing_strategy": "how to extract insights"
  },
  (Include ONLY if next_action is "analyze_doc")
  
  "synthesis_output": {
    "problem_statement": "Refined understanding",
    "key_insights": ["breakthrough realizations"],
    "pattern_recognition": ["recurring themes"],
    "hypothesis": "Core theory about the problem"
  },
  (Include ONLY if next_action is "synthesize")
  
  "solution_proposal": {
    "solution_architecture": {
      "approach": "High-level strategy",
      "components": [{"name": "string", "purpose": "string", "implementation": "string"}],
      "innovation_points": ["what makes this unique"]
    },
    "implementation_plan": {
      "phases": [{"phase": "string", "deliverables": ["list"], "success_metrics": ["list"]}],
      "risk_mitigation": {"risk": "mitigation_strategy"},
      "resource_requirements": ["list"]
    },
    "test_strategy": {
      "test_scenarios": [{"scenario": "string", "expected_outcome": "string", "measurement": "string"}],
      "feedback_loops": ["how to gather data"],
      "pivot_triggers": ["when to change course"]
    }
  },
  (Include ONLY if next_action is "generate_solution")
  
  "calibration_request": {
    "test_type": "prototype|simulation|user_test|analysis",
    "test_parameters": {},
    "success_criteria": ["list"],
    "data_collection": ["what metrics to track"]
  },
  (Include ONLY if next_action is "test")
  
  "evolution_delta": {
    "model_updates": {"component": "what changed and why"},
    "solution_refinements": ["adjustments based on learning"],
    "confidence_changes": {"aspect": {"before": 0.0, "after": 0.0, "reason": "string"}},
    "next_iteration": "what to explore next"
  },
  (Always include when learning occurs)
  
  "updated_state": {
    "conversation_history": [{"type": "interview|document|test", "content": {}, "insights": []}],
    "mental_model_version": "integer",
    "solution_iterations": [{"version": "integer", "changes": [], "performance": {}}],
    "active_hypotheses": [{"hypothesis": "string", "evidence_for": [], "evidence_against": []}],
    "implementation_artifacts": {"artifact_name": "content or code"}
  }
}

CRITICAL BEHAVIORS:
1. Build the mental model incrementally - each input adds nodes to the knowledge graph
2. Track uncertainty explicitly - knowing what you don't know is crucial
3. Generate interview questions that probe deeper based on the emerging model
4. Solutions must address all layers of the problem topology
5. Every test result must feed back into the mental model
6. Be ready to pivot when evidence contradicts assumptions
EOF

# Initialize problem navigator state
init_navigator() {
    python3 -c "
import json

initial_state = {
    'current_phase': 'discovery',
    'phase_progress': 0.0,
    'mental_model': {
        'problem_topology': {
            'core_problem': None,
            'problem_layers': {
                'surface_symptoms': [],
                'underlying_causes': [],
                'systemic_factors': []
            },
            'stakeholder_map': {}
        },
        'knowledge_graph': {
            'entities': [],
            'relationships': []
        },
        'uncertainty_map': {
            'known_unknowns': [],
            'assumptions': [],
            'knowledge_gaps': []
        }
    },
    'conversation_history': [],
    'mental_model_version': 1,
    'solution_iterations': [],
    'active_hypotheses': [],
    'implementation_artifacts': {}
}

print(json.dumps(initial_state))
"
}

# Extract JSON helper
extract_json() {
    local response="$1"
    if [[ "$response" == *'```json'* ]]; then
        echo "$response" | sed -n '/```json/,/```/p' | sed '1d;$d'
    else
        echo "$response"
    fi
}

# Document analyzer helper
analyze_document() {
    local file_path="$1"
    local extraction_focus="$2"
    
    echo -e "${C_INFO}[Analyzing document: $file_path]${C_RESET}"
    
    # Create a smart document analyzer prompt
    DOC_ANALYZER="Analyze this document for problem understanding.
Focus areas: $extraction_focus
Extract: facts, patterns, stakeholder mentions, system descriptions, pain points.
Output JSON: {insights: [], entities: [], relationships: []}"
    
    cat "$file_path" | claude -p "$DOC_ANALYZER"
}

# Visualization helper
visualize_mental_model() {
    local state="$1"
    echo "$state" | python3 -c "
import json
import sys

data = json.load(sys.stdin)
model = data.get('mental_model', {})

print('\n🧠 MENTAL MODEL VISUALIZATION')
print('=' * 60)

# Problem Topology
topology = model.get('problem_topology', {})
print(f\"Core Problem: {topology.get('core_problem', 'Unknown')}\")
print(f\"Surface Symptoms: {len(topology.get('problem_layers', {}).get('surface_symptoms', []))} identified\")
print(f\"Root Causes: {len(topology.get('problem_layers', {}).get('underlying_causes', []))} discovered\")

# Knowledge Graph
kg = model.get('knowledge_graph', {})
print(f\"\nKnowledge Graph: {len(kg.get('entities', []))} entities, {len(kg.get('relationships', []))} relationships\")

# Uncertainty
uncertainty = model.get('uncertainty_map', {})
print(f\"\nUncertainty Level: {len(uncertainty.get('known_unknowns', []))} known unknowns\")
print(f\"Active Assumptions: {len(uncertainty.get('assumptions', []))}\")

print('=' * 60)
"
}

# Main Navigation Loop
main() {
    clear
    echo -e "${C_PROMPT}🧭 Problem Space Navigator${C_RESET}"
    echo -e "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo -e "${C_INFO}I build deep mental models of problems through interviews, documents, and iterative testing."
    echo -e "Together we'll navigate from confusion to clarity to solution.${C_RESET}"
    echo ""
    echo -e "${C_PROMPT}What problem space would you like to explore?${C_RESET}"
    echo -n -e "${C_USER}➤ ${C_RESET}"
    read -r INITIAL_PROBLEM
    
    # Initialize with problem
    STATE=$(init_navigator)
    STATE=$(echo "$STATE" | python3 -c "
import json
import sys
state = json.load(sys.stdin)
state['mental_model']['problem_topology']['core_problem'] = '''$INITIAL_PROBLEM'''
state['conversation_history'].append({
    'type': 'initial',
    'content': '''$INITIAL_PROBLEM''',
    'insights': []
})
print(json.dumps(state))
")
    
    # Navigation loop
    ITERATION=0
    MAX_ITERATIONS=20
    
    while [ $ITERATION -lt $MAX_ITERATIONS ]; do
        ((ITERATION++))
        
        # Get next navigation action
        echo -e "\n${C_INFO}[Navigating problem space...]${C_RESET}"
        NAV_RESPONSE=$(echo "$STATE" | claude -p "$NAVIGATOR_PROMPT")
        CLEANED_RESPONSE=$(extract_json "$NAV_RESPONSE")
        
        # Validate response
        if ! echo "$CLEANED_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
            echo -e "${C_ERROR}Navigation error. Raw: $NAV_RESPONSE${C_RESET}"
            exit 1
        fi
        
        # Extract navigation data
        PHASE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin).get('current_phase','unknown'))")
        PROGRESS=$(echo "$CLEANED_RESPONSE" | python3 -c "import json,sys; print(f\"{json.load(sys.stdin).get('phase_progress',0):.0%}\")")
        ACTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin).get('next_action','unknown'))")
        
        # Display phase status
        echo -e "\n${C_SUCCESS}Phase: ${PHASE} (${PROGRESS} complete)${C_RESET}"
        visualize_mental_model "$CLEANED_RESPONSE"
        
        # Handle different actions
        case "$ACTION" in
            "interview")
                # Extract interview request
                TARGET=$(echo "$CLEANED_RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin)['interview_request']['target_profile'])")
                echo -e "\n${C_PROMPT}━━━ INTERVIEW REQUEST ━━━${C_RESET}"
                echo -e "${C_INFO}Target: $TARGET${C_RESET}"
                
                # Show dynamic questions
                echo -e "\n${C_PROMPT}Interview Questions:${C_RESET}"
                echo "$CLEANED_RESPONSE" | python3 -c "
import json,sys
data = json.load(sys.stdin)
for i, q in enumerate(data['interview_request']['dynamic_questions'], 1):
    print(f\"{i}. {q['question']}\")
"
                
                echo -e "\n${C_USER}Enter interview responses (or 'skip' to skip):${C_RESET}"
                echo -n -e "${C_USER}➤ ${C_RESET}"
                read -r INTERVIEW_RESPONSE
                
                if [ "$INTERVIEW_RESPONSE" != "skip" ]; then
                    # Process interview
                    STATE=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json,sys
data = json.load(sys.stdin)
data['updated_state']['conversation_history'].append({
    'type': 'interview',
    'content': {
        'target': '$TARGET',
        'responses': '''$INTERVIEW_RESPONSE'''
    },
    'insights': []
})
print(json.dumps(data['updated_state']))
")
                fi
                ;;
                
            "analyze_doc")
                # Document analysis request
                DOC_TYPE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin)['document_request']['document_type'])")
                echo -e "\n${C_PROMPT}━━━ DOCUMENT REQUEST ━━━${C_RESET}"
                echo -e "${C_INFO}Looking for: $DOC_TYPE${C_RESET}"
                echo -e "${C_USER}Enter document path (or 'skip'):${C_RESET}"
                echo -n -e "${C_USER}➤ ${C_RESET}"
                read -r DOC_PATH
                
                if [ "$DOC_PATH" != "skip" ] && [ -f "$DOC_PATH" ]; then
                    FOCUS=$(echo "$CLEANED_RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin)['document_request']['extraction_focus'])")
                    DOC_INSIGHTS=$(analyze_document "$DOC_PATH" "$FOCUS")
                    
                    STATE=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json,sys
data = json.load(sys.stdin)
data['updated_state']['conversation_history'].append({
    'type': 'document',
    'content': {
        'path': '$DOC_PATH',
        'analysis': json.loads('''$DOC_INSIGHTS''')
    },
    'insights': []
})
print(json.dumps(data['updated_state']))
")
                fi
                ;;
                
            "synthesize")
                # Show synthesis
                echo -e "\n${C_SUCCESS}━━━ SYNTHESIS ━━━${C_RESET}"
                echo "$CLEANED_RESPONSE" | python3 -c "
import json,sys
data = json.load(sys.stdin)
synth = data.get('synthesis_output', {})
print(f\"Problem Statement: {synth.get('problem_statement', '')}\")
print(f\"\nKey Insights:\")
for insight in synth.get('key_insights', []):
    print(f\"  • {insight}\")
print(f\"\nHypothesis: {synth.get('hypothesis', '')}\")
"
                echo -e "\n${C_USER}Press Enter to continue...${C_RESET}"
                read -r
                
                STATE=$(echo "$CLEANED_RESPONSE" | jq -r '.updated_state')
                ;;
                
            "generate_solution")
                # Show solution proposal
                echo -e "\n${C_SUCCESS}━━━ SOLUTION PROPOSAL ━━━${C_RESET}"
                echo "$CLEANED_RESPONSE" | python3 -c "
import json,sys
data = json.load(sys.stdin)
sol = data.get('solution_proposal', {})
arch = sol.get('solution_architecture', {})
print(f\"Approach: {arch.get('approach', '')}\")
print(f\"\nComponents:\")
for comp in arch.get('components', []):
    print(f\"  • {comp['name']}: {comp['purpose']}\")
print(f\"\nInnovation Points:\")
for point in arch.get('innovation_points', []):
    print(f\"  • {point}\")
"
                
                # Option to generate artifacts
                echo -e "\n${C_USER}Generate implementation artifacts? (y/n)${C_RESET}"
                read -r GENERATE_ARTIFACTS
                
                if [ "$GENERATE_ARTIFACTS" = "y" ]; then
                    # Generate actual code/configs
                    echo -e "${C_INFO}[Generating implementation artifacts...]${C_RESET}"
                    # This would call Claude to generate actual code based on the solution
                fi
                
                STATE=$(echo "$CLEANED_RESPONSE" | jq -r '.updated_state')
                ;;
                
            "test")
                # Testing phase
                echo -e "\n${C_PROMPT}━━━ CALIBRATION TEST ━━━${C_RESET}"
                TEST_TYPE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin)['calibration_request']['test_type'])")
                echo -e "${C_INFO}Test Type: $TEST_TYPE${C_RESET}"
                
                echo -e "${C_USER}Enter test results (or 'simulate' to simulate):${C_RESET}"
                echo -n -e "${C_USER}➤ ${C_RESET}"
                read -r TEST_RESULTS
                
                # Process test results and evolve model
                STATE=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json,sys
data = json.load(sys.stdin)
data['updated_state']['conversation_history'].append({
    'type': 'test',
    'content': {
        'test_type': '$TEST_TYPE',
        'results': '''$TEST_RESULTS'''
    },
    'insights': []
})
print(json.dumps(data['updated_state']))
")
                ;;
                
            "conclude")
                echo -e "\n${C_SUCCESS}━━━ NAVIGATION COMPLETE ━━━${C_RESET}"
                echo -e "${C_INFO}Mental model built through $ITERATION iterations${C_RESET}"
                
                # Save complete navigation
                TIMESTAMP=$(date +%Y%m%d_%H%M%S)
                FILENAME="problem_space_${TIMESTAMP}.json"
                echo "$CLEANED_RESPONSE" > "$FILENAME"
                echo -e "${C_INFO}Complete navigation saved to: $FILENAME${C_RESET}"
                
                # Generate final report
                echo -e "\n${C_PROMPT}Generating implementation package...${C_RESET}"
                # This would generate complete implementation based on the journey
                
                break
                ;;
                
            *)
                echo -e "${C_ERROR}Unknown action: $ACTION${C_RESET}"
                STATE=$(echo "$CLEANED_RESPONSE" | jq -r '.updated_state')
                ;;
        esac
    done
}

# Run main navigation
main "$@"