#!/bin/bash

# court_judgment_extractor.sh
# Extracts structured information from court judgment documents
# Built using the generic state machine template

# ============================================================================
# CONFIGURATION
# ============================================================================

# --- Color Definitions ---
C_PROMPT='\033[1;36m'  # Cyan for prompts
C_USER='\033[1;32m'    # Green for user input
C_INFO='\033[0;33m'    # Yellow for information
C_ERROR='\033[0;31m'   # Red for errors
C_SUCCESS='\033[0;32m' # Green for success
C_LEGAL='\033[0;35m'   # Magenta for legal terms
C_RESET='\033[0m'      # Reset to default

# --- Application Settings ---
APP_NAME="Court Judgment Document Extractor"
APP_VERSION="1.0.0"
SESSION_DIR="extractions/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$SESSION_DIR/extraction.log"
OUTPUT_DIR="$SESSION_DIR/output"

# Create directories
mkdir -p "$SESSION_DIR" "$OUTPUT_DIR"

# ============================================================================
# MAIN PROMPT - Legal Document Extraction AI
# ============================================================================

read -r -d '' SYSTEM_PROMPT << 'EOF'
You are an expert legal document analyzer specializing in extracting structured information from court judgments. Your role is to systematically identify and extract all relevant legal information into organized JSON format.

You will receive a JSON object representing the current extraction state and must respond with a JSON object specifying the next action.

Your capabilities:
1. **Document Analysis**: Identify document type, court level, and jurisdiction
2. **Entity Extraction**: Extract parties, judges, attorneys, and legal entities
3. **Legal Elements**: Identify claims, rulings, orders, and legal reasoning
4. **Temporal Extraction**: Extract all dates and deadlines
5. **Financial Extraction**: Identify monetary amounts, damages, and fees
6. **Citation Parsing**: Extract legal citations and references
7. **Hierarchical Structure**: Organize information by document sections

You MUST respond ONLY with a single JSON object.

Output structure:
{
  "analysis": {
    "current_situation": "What extraction stage we're at",
    "document_understanding": "Your analysis of the document type and structure",
    "confidence": 0.0 to 1.0
  },
  
  "next_action": "request_document|analyze_structure|extract_section|validate_data|preview_json|complete_extraction",
  
  "request_document": {
    "prompt": "Request for document input",
    "accepted_formats": ["text", "file_path", "paste"],
    "instructions": "How to provide the document"
  },
  (Include when next_action is "request_document")
  
  "analyze_structure": {
    "document_type": "judgment|order|motion|complaint|other",
    "court_level": "supreme|appellate|district|state|other",
    "jurisdiction": "Identified jurisdiction",
    "main_sections": ["List of document sections identified"],
    "extraction_strategy": "How to approach extraction"
  },
  (Include when next_action is "analyze_structure")
  
  "extract_section": {
    "section_name": "Current section being extracted",
    "extraction_type": "metadata|parties|claims|rulings|dates|amounts|citations",
    "extracted_data": {
      "field_name": "extracted_value",
      "confidence_score": 0.0 to 1.0
    },
    "remaining_sections": ["Sections still to process"]
  },
  (Include when next_action is "extract_section")
  
  "validate_data": {
    "validation_type": "cross_reference|consistency|completeness",
    "issues_found": ["List of validation issues"],
    "suggestions": ["How to resolve issues"]
  },
  (Include when next_action is "validate_data")
  
  "preview_json": {
    "extraction_summary": "Summary of what was extracted",
    "json_preview": {
      "case_metadata": {},
      "parties": {},
      "procedural_history": {},
      "claims_and_issues": {},
      "rulings_and_orders": {},
      "legal_reasoning": {},
      "financial_information": {},
      "citations": {},
      "key_dates": {}
    },
    "completeness_score": 0.0 to 1.0
  },
  (Include when next_action is "preview_json")
  
  "complete_extraction": {
    "final_json": {
      "extraction_metadata": {
        "extraction_date": "timestamp",
        "document_id": "unique_identifier",
        "confidence_scores": {}
      },
      "case_information": {
        "case_name": "Party v. Party",
        "case_number": "XX-XXXX",
        "court": "Court name",
        "date_filed": "YYYY-MM-DD",
        "date_decided": "YYYY-MM-DD"
      },
      "parties": {
        "plaintiffs": [{"name": "", "type": "", "representation": ""}],
        "defendants": [{"name": "", "type": "", "representation": ""}],
        "other_parties": []
      },
      "judges": [{"name": "", "role": ""}],
      "attorneys": [{"name": "", "bar_number": "", "representing": ""}],
      "claims": [{"claim_number": 1, "description": "", "legal_basis": ""}],
      "rulings": [{"issue": "", "ruling": "", "reasoning": ""}],
      "orders": [{"type": "", "description": "", "deadline": ""}],
      "monetary_awards": [{"type": "", "amount": 0, "recipient": "", "payor": ""}],
      "key_dates": [{"event": "", "date": "YYYY-MM-DD"}],
      "legal_citations": [{"citation": "", "context": ""}],
      "docket_entries": [{"date": "", "description": ""}]
    },
    "output_formats": ["json", "csv", "summary_report"]
  },
  (Include when next_action is "complete_extraction")
  
  "state_update": {
    "user_response": null,
    "extraction_history": [],
    "document_store": {
      "raw_text": {"value": null, "status": "empty|loaded", "metadata": {}},
      "document_type": {"value": null, "status": "empty|identified"},
      "sections_identified": {"value": [], "status": "empty|complete"},
      "extraction_progress": {"value": {}, "status": "empty|partial|complete"}
    },
    "extracted_data": {
      "case_metadata": {"data": {}, "confidence": 0.0, "status": "empty|extracted|validated"},
      "parties": {"data": {}, "confidence": 0.0, "status": "empty|extracted|validated"},
      "legal_elements": {"data": {}, "confidence": 0.0, "status": "empty|extracted|validated"},
      "temporal_data": {"data": {}, "confidence": 0.0, "status": "empty|extracted|validated"},
      "financial_data": {"data": {}, "confidence": 0.0, "status": "empty|extracted|validated"},
      "citations": {"data": {}, "confidence": 0.0, "status": "empty|extracted|validated"}
    },
    "extraction_state": {
      "current_phase": "initialization|document_loading|structure_analysis|extraction|validation|complete",
      "sections_processed": 0,
      "total_sections": 0,
      "overall_confidence": 0.0
    }
  }
}

Extraction Guidelines:
1. Always validate court document authenticity markers first
2. Extract parties in order of appearance with full legal names
3. Identify all monetary amounts with context (damages, fees, costs)
4. Extract dates in ISO format (YYYY-MM-DD) with event descriptions
5. Parse legal citations in standard format
6. Maintain relationships between entities (who represents whom)
7. Flag any ambiguous or unclear information for review
8. Preserve the hierarchical structure of legal reasoning

Special Considerations:
- Distinguish between majority and dissenting opinions
- Note any sealed or redacted information
- Extract footnotes separately but maintain references
- Identify and extract any attached exhibits or appendices
EOF

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log_both() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_file() {
    echo -e "$1" >> "$LOG_FILE"
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

validate_json() {
    echo "$1" | python3 -m json.tool > /dev/null 2>&1
}

# Function to read document from file
read_document_file() {
    local filepath="$1"
    if [ -f "$filepath" ]; then
        cat "$filepath"
    else
        echo "ERROR: File not found: $filepath"
        return 1
    fi
}

# Function to save extracted data
save_extraction() {
    local filename="$1"
    local content="$2"
    echo "$content" > "$OUTPUT_DIR/$filename"
    log_both "${C_SUCCESS}✓ Saved: $OUTPUT_DIR/$filename${C_RESET}"
}

# Function to format JSON nicely
format_json() {
    echo "$1" | python3 -m json.tool
}

# ============================================================================
# INITIALIZATION
# ============================================================================

clear
log_both "${C_PROMPT}⚖️  Court Judgment Document Extractor${C_RESET}"
log_both "${C_PROMPT}════════════════════════════════════════════════════════════════════${C_RESET}"
log_both ""
log_both "${C_INFO}This tool extracts structured information from court judgments into JSON format.${C_RESET}"
log_both ""
log_both "${C_INFO}Extraction includes:${C_RESET}"
log_both "${C_INFO}  • Case metadata (names, numbers, dates, court)${C_RESET}"
log_both "${C_INFO}  • All parties, judges, and attorneys${C_RESET}"
log_both "${C_INFO}  • Claims, rulings, and orders${C_RESET}"
log_both "${C_INFO}  • Financial amounts and key dates${C_RESET}"
log_both "${C_INFO}  • Legal citations and reasoning${C_RESET}"
log_both ""
log_both "${C_INFO}Session ID: $(basename $SESSION_DIR)${C_RESET}"
log_both ""

# Get initial input
log_both "${C_PROMPT}How would you like to provide the court judgment document?${C_RESET}"
log_both "${C_USER}Options: ${C_RESET}"
log_both "${C_USER}  1. Paste text directly${C_RESET}"
log_both "${C_USER}  2. Provide file path${C_RESET}"
log_both "${C_USER}  3. Load sample document${C_RESET}"
echo -n -e "${C_USER}➤ ${C_RESET}"
read -r INITIAL_INPUT

# ============================================================================
# INITIALIZE STATE
# ============================================================================

STATE=$(python3 -c "
import json
from datetime import datetime

initial_input = '''$INITIAL_INPUT'''

initial_state = {
    'user_response': initial_input,
    'extraction_history': [],
    'document_store': {
        'raw_text': {'value': None, 'status': 'empty', 'metadata': {}},
        'document_type': {'value': None, 'status': 'empty'},
        'sections_identified': {'value': [], 'status': 'empty'},
        'extraction_progress': {'value': {}, 'status': 'empty'}
    },
    'extracted_data': {
        'case_metadata': {'data': {}, 'confidence': 0.0, 'status': 'empty'},
        'parties': {'data': {}, 'confidence': 0.0, 'status': 'empty'},
        'legal_elements': {'data': {}, 'confidence': 0.0, 'status': 'empty'},
        'temporal_data': {'data': {}, 'confidence': 0.0, 'status': 'empty'},
        'financial_data': {'data': {}, 'confidence': 0.0, 'status': 'empty'},
        'citations': {'data': {}, 'confidence': 0.0, 'status': 'empty'}
    },
    'extraction_state': {
        'current_phase': 'initialization',
        'sections_processed': 0,
        'total_sections': 0,
        'overall_confidence': 0.0
    },
    'session_metadata': {
        'session_id': '$(basename $SESSION_DIR)',
        'start_time': datetime.now().isoformat(),
        'extraction_count': 0
    }
}

print(json.dumps(initial_state, indent=2))
")

# ============================================================================
# MAIN EXTRACTION LOOP
# ============================================================================

EXTRACTION_COUNT=0
CONTINUE_LOOP=true

while $CONTINUE_LOOP; do
    EXTRACTION_COUNT=$((EXTRACTION_COUNT + 1))
    
    # Send state to AI
    log_both "\n${C_INFO}[Analyzing document structure...]${C_RESET}"
    log_file "=== Extraction Step $EXTRACTION_COUNT ==="
    
    AI_RESPONSE=$(echo "$STATE" | claude -p "$SYSTEM_PROMPT" 2>&1)
    CLEANED_RESPONSE=$(extract_json "$AI_RESPONSE")
    
    # Validate response
    if ! validate_json "$CLEANED_RESPONSE"; then
        log_both "${C_ERROR}Error: Invalid response. Retrying...${C_RESET}"
        log_file "Invalid JSON: $AI_RESPONSE"
        continue
    fi
    
    # Extract action and metadata
    NEXT_ACTION=$(safe_json_get "$CLEANED_RESPONSE" "next_action" "unknown")
    CONFIDENCE=$(safe_json_get "$CLEANED_RESPONSE" "analysis.confidence" "0.0")
    
    log_both "${C_INFO}Step: $NEXT_ACTION | Confidence: $CONFIDENCE${C_RESET}"
    
    # Handle each action type
    case "$NEXT_ACTION" in
        "request_document")
            PROMPT=$(safe_json_get "$CLEANED_RESPONSE" "request_document.prompt")
            
            log_both ""
            log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both "${C_PROMPT}$PROMPT${C_RESET}"
            
            case "$INITIAL_INPUT" in
                "1")
                    log_both "${C_USER}Paste the court judgment text (press Ctrl+D when done):${C_RESET}"
                    DOCUMENT_TEXT=$(cat)
                    USER_RESPONSE="Document pasted successfully"
                    ;;
                "2")
                    log_both "${C_USER}Enter the file path:${C_RESET}"
                    echo -n -e "${C_USER}➤ ${C_RESET}"
                    read -r FILE_PATH
                    if [ -f "$FILE_PATH" ]; then
                        DOCUMENT_TEXT=$(cat "$FILE_PATH")
                        USER_RESPONSE="Document loaded from file"
                    else
                        log_both "${C_ERROR}File not found!${C_RESET}"
                        USER_RESPONSE="File not found"
                    fi
                    ;;
                "3")
                    # Load sample document
                    DOCUMENT_TEXT="UNITED STATES DISTRICT COURT
SOUTHERN DISTRICT OF NEW YORK

JANE DOE,
    Plaintiff,
    
v.                                  Case No. 22-CV-1234
    
ACME CORPORATION,
    Defendant.

MEMORANDUM OPINION AND ORDER

SMITH, District Judge:

This matter comes before the Court on Defendant's Motion for Summary Judgment. 
For the reasons stated below, the motion is GRANTED IN PART and DENIED IN PART.

I. BACKGROUND
Plaintiff Jane Doe filed this action on March 15, 2022, alleging employment 
discrimination under Title VII. Plaintiff seeks damages in the amount of $500,000.

II. RULING
The Court finds that Plaintiff has failed to establish a prima facie case of 
discrimination regarding the promotion claim. However, the retaliation claim 
presents genuine issues of material fact.

IT IS HEREBY ORDERED that Defendant's motion is GRANTED as to Count I and 
DENIED as to Count II. Trial shall commence on January 15, 2024.

Dated: November 30, 2023
/s/ John Smith
United States District Judge"
                    USER_RESPONSE="Sample document loaded"
                    ;;
            esac
            
            # Store document in state
            STATE=$(echo "$STATE" | python3 -c "
import json
import sys
state = json.load(sys.stdin)
state['document_store']['raw_text']['value'] = '''$DOCUMENT_TEXT'''
state['document_store']['raw_text']['status'] = 'loaded'
state['user_response'] = '$USER_RESPONSE'
print(json.dumps(state, indent=2))
")
            ;;
            
        "analyze_structure")
            DOC_TYPE=$(safe_json_get "$CLEANED_RESPONSE" "analyze_structure.document_type")
            COURT_LEVEL=$(safe_json_get "$CLEANED_RESPONSE" "analyze_structure.court_level")
            SECTIONS=$(safe_json_get "$CLEANED_RESPONSE" "analyze_structure.main_sections")
            
            log_both ""
            log_both "${C_LEGAL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both "${C_LEGAL}📋 Document Structure Analysis${C_RESET}"
            log_both "${C_LEGAL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both "${C_INFO}Type: $DOC_TYPE${C_RESET}"
            log_both "${C_INFO}Court: $COURT_LEVEL${C_RESET}"
            log_both "${C_INFO}Sections identified:${C_RESET}"
            
            echo "$SECTIONS" | python3 -c "
import json, sys
sections = json.loads(sys.stdin.read())
for i, section in enumerate(sections, 1):
    print(f'  {i}. {section}')
" 2>/dev/null
            
            USER_RESPONSE="Structure analyzed"
            ;;
            
        "extract_section")
            SECTION=$(safe_json_get "$CLEANED_RESPONSE" "extract_section.section_name")
            EXTRACT_TYPE=$(safe_json_get "$CLEANED_RESPONSE" "extract_section.extraction_type")
            
            log_both ""
            log_both "${C_LEGAL}🔍 Extracting: $SECTION${C_RESET}"
            log_both "${C_INFO}Type: $EXTRACT_TYPE${C_RESET}"
            
            # Show extraction progress
            REMAINING=$(safe_json_get "$CLEANED_RESPONSE" "extract_section.remaining_sections")
            echo "$REMAINING" | python3 -c "
import json, sys
try:
    remaining = json.loads(sys.stdin.read())
    if remaining:
        print(f'\\n${C_INFO}Remaining sections: {len(remaining)}${C_RESET}')
except:
    pass
" 2>/dev/null
            
            USER_RESPONSE="Section extracted"
            ;;
            
        "validate_data")
            VAL_TYPE=$(safe_json_get "$CLEANED_RESPONSE" "validate_data.validation_type")
            ISSUES=$(safe_json_get "$CLEANED_RESPONSE" "validate_data.issues_found")
            
            log_both ""
            log_both "${C_PROMPT}🔍 Validating: $VAL_TYPE${C_RESET}"
            
            if [ "$ISSUES" != "[]" ] && [ -n "$ISSUES" ]; then
                log_both "${C_ERROR}Issues found:${C_RESET}"
                echo "$ISSUES" | python3 -c "
import json, sys
issues = json.loads(sys.stdin.read())
for issue in issues:
    print(f'  ⚠️  {issue}')
" 2>/dev/null
            else
                log_both "${C_SUCCESS}✓ No issues found${C_RESET}"
            fi
            
            USER_RESPONSE="Validation complete"
            ;;
            
        "preview_json")
            SUMMARY=$(safe_json_get "$CLEANED_RESPONSE" "preview_json.extraction_summary")
            JSON_PREVIEW=$(safe_json_get "$CLEANED_RESPONSE" "preview_json.json_preview")
            COMPLETENESS=$(safe_json_get "$CLEANED_RESPONSE" "preview_json.completeness_score")
            
            log_both ""
            log_both "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both "${C_SUCCESS}📊 Extraction Preview${C_RESET}"
            log_both "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both ""
            log_both "${C_INFO}Summary: $SUMMARY${C_RESET}"
            log_both "${C_INFO}Completeness: $COMPLETENESS${C_RESET}"
            log_both ""
            
            # Format and display preview
            FORMATTED_JSON=$(echo "$JSON_PREVIEW" | python3 -m json.tool 2>/dev/null || echo "$JSON_PREVIEW")
            echo "$FORMATTED_JSON" | head -50
            
            if [ $(echo "$FORMATTED_JSON" | wc -l) -gt 50 ]; then
                log_both "${C_INFO}... (preview truncated)${C_RESET}"
            fi
            
            # Save preview
            save_extraction "preview.json" "$FORMATTED_JSON"
            
            log_both ""
            log_both "${C_USER}Continue to finalize extraction? (yes/no/edit)${C_RESET}"
            echo -n -e "${C_USER}➤ ${C_RESET}"
            read -r USER_RESPONSE
            ;;
            
        "complete_extraction")
            FINAL_JSON=$(safe_json_get "$CLEANED_RESPONSE" "complete_extraction.final_json")
            
            log_both ""
            log_both "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            log_both "${C_SUCCESS}✅ Extraction Complete!${C_RESET}"
            log_both "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            
            # Format final JSON
            FORMATTED_FINAL=$(echo "$FINAL_JSON" | python3 -m json.tool)
            
            # Save in multiple formats
            save_extraction "extracted_data.json" "$FORMATTED_FINAL"
            
            # Generate summary report
            SUMMARY_REPORT=$(echo "$FINAL_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)

case_info = data.get('case_information', {})
parties = data.get('parties', {})
monetary = data.get('monetary_awards', [])

print('CASE SUMMARY REPORT')
print('==================')
print(f\"Case: {case_info.get('case_name', 'N/A')}\")
print(f\"Number: {case_info.get('case_number', 'N/A')}\")
print(f\"Court: {case_info.get('court', 'N/A')}\")
print(f\"Filed: {case_info.get('date_filed', 'N/A')}\")
print(f\"Decided: {case_info.get('date_decided', 'N/A')}\")
print()
print('PARTIES:')
for p in parties.get('plaintiffs', []):
    print(f\"  Plaintiff: {p.get('name', 'N/A')}\")
for d in parties.get('defendants', []):
    print(f\"  Defendant: {d.get('name', 'N/A')}\")
print()
if monetary:
    print('MONETARY AWARDS:')
    total = sum(m.get('amount', 0) for m in monetary)
    print(f\"  Total: ${total:,.2f}\")
")
            
            save_extraction "summary_report.txt" "$SUMMARY_REPORT"
            
            # Generate CSV of key data
            CSV_DATA=$(echo "$FINAL_JSON" | python3 -c "
import json, csv, sys
from io import StringIO

data = json.load(sys.stdin)
output = StringIO()
writer = csv.writer(output)

# Write case info
writer.writerow(['Field', 'Value'])
case_info = data.get('case_information', {})
for key, value in case_info.items():
    writer.writerow([key.replace('_', ' ').title(), value])

print(output.getvalue())
")
            
            save_extraction "case_data.csv" "$CSV_DATA"
            
            log_both ""
            log_both "${C_INFO}Files created:${C_RESET}"
            log_both "${C_SUCCESS}  ✓ extracted_data.json - Complete structured data${C_RESET}"
            log_both "${C_SUCCESS}  ✓ summary_report.txt - Human-readable summary${C_RESET}"
            log_both "${C_SUCCESS}  ✓ case_data.csv - Key data in CSV format${C_RESET}"
            log_both ""
            log_both "${C_INFO}All files saved in: $OUTPUT_DIR${C_RESET}"
            
            # Save final state
            echo "$CLEANED_RESPONSE" > "$SESSION_DIR/final_state.json"
            
            CONTINUE_LOOP=false
            ;;
            
        *)
            log_both "${C_ERROR}Unexpected action: $NEXT_ACTION${C_RESET}"
            USER_RESPONSE="Please continue"
            ;;
    esac
    
    # Update state for next iteration
    if $CONTINUE_LOOP; then
        STATE=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json
import sys

data = json.load(sys.stdin)
user_response = '''${USER_RESPONSE}'''

# Get state update
new_state = data.get('state_update', {})
new_state['user_response'] = user_response

# Update extraction count
if 'session_metadata' not in new_state:
    new_state['session_metadata'] = {}
new_state['session_metadata']['extraction_count'] = $EXTRACTION_COUNT

# Add to history
if 'extraction_history' not in new_state:
    new_state['extraction_history'] = []

new_state['extraction_history'].append({
    'step': $EXTRACTION_COUNT,
    'action': '$NEXT_ACTION',
    'confidence': $CONFIDENCE
})

print(json.dumps(new_state, indent=2))
")
    fi
done

log_both ""
log_both "${C_PROMPT}Thank you for using the Court Judgment Document Extractor!${C_RESET}"
log_both "${C_INFO}Session complete. Extraction ID: $(basename $SESSION_DIR)${C_RESET}"