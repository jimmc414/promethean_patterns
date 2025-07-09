#!/bin/bash

# dspy_implementation_builder.sh
# Advanced DSPy Implementation Builder with Sub-Agents
# Builds, tests, and runs actual DSPy implementations

# --- Color Definitions ---
C_PROMPT='\033[1;36m' # Cyan for main agent
C_USER='\033[1;32m'   # Green for user input
C_INFO='\033[0;33m'   # Yellow for info
C_CODE='\033[0;35m'   # Magenta for code
C_ERROR='\033[0;31m'  # Red for errors
C_SUCCESS='\033[0;32m' # Green for success
C_AGENT='\033[1;34m'  # Blue for sub-agents
C_RESET='\033[0m'     # Reset color

# Create project directory
PROJECT_DIR="dspy_projects/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$PROJECT_DIR"/{src,tests,data,outputs}
PROJECT_LOG="$PROJECT_DIR/build.log"

# Function to log to file and display
log_both() {
    echo -e "$1" | tee -a "$PROJECT_LOG"
}

# Main orchestrator prompt with ULTRATHINK and sub-agents
read -r -d '' PROMPT << 'EOF'
You are the Master DSPy Implementation Builder with ULTRATHINK capabilities. You orchestrate a team of specialized sub-agents to build, test, and deploy actual DSPy implementations.

IMPORTANT: Apply ULTRATHINK reasoning - deeply analyze requirements, consider multiple approaches, and think through edge cases before implementation.

Your sub-agents are:
1. **Architecture Agent** - Designs system architecture and module structure
2. **Code Generation Agent** - Writes actual Python/DSPy code
3. **Testing Agent** - Creates and runs tests
4. **Optimization Agent** - Implements DSPy optimizers
5. **Deployment Agent** - Packages and prepares for production

You will be given a JSON object representing the entire build state. Your task is to:

1. **ULTRATHINK Analysis**: Deeply analyze the user's requirements, considering:
   - Multiple implementation approaches
   - Potential challenges and solutions
   - Optimization opportunities
   - Edge cases and error handling

2. **Delegate to Sub-Agents**: Assign specific tasks to specialized agents

3. **Build Real Implementations**: Create actual, runnable DSPy code

4. **Test and Validate**: Ensure everything works correctly

5. **Optimize and Deploy**: Apply DSPy optimization techniques

You MUST respond ONLY with a single JSON object.

Output structure:
{
  "ultrathink_analysis": {
    "requirement_understanding": "Deep analysis of what user wants",
    "considered_approaches": ["List of different ways to solve this"],
    "selected_approach": "The best approach and why",
    "potential_challenges": ["Anticipated issues"],
    "optimization_opportunities": ["Ways to optimize with DSPy"]
  },
  
  "current_phase": "analyzing|architecting|implementing|testing|optimizing|deploying|complete",
  "confidence_level": 0.0 to 1.0,
  
  "next_action": "delegate_task" | "show_implementation" | "run_test" | "apply_optimization" | "request_input" | "complete_build",
  
  "agent_delegation": {
    "target_agent": "architecture|code_generation|testing|optimization|deployment",
    "task_description": "Specific task for the sub-agent",
    "required_output": "What the sub-agent should produce",
    "context": "Relevant context for the sub-agent"
  },
  (Include agent_delegation when next_action is "delegate_task")
  
  "implementation_details": {
    "component_name": "Name of component being built",
    "description": "What this component does",
    "code": "Complete Python/DSPy code",
    "dependencies": ["Required packages"],
    "usage_example": "How to use this component",
    "file_path": "Where to save this code"
  },
  (Include implementation_details when next_action is "show_implementation")
  
  "test_execution": {
    "test_name": "Name of test",
    "test_code": "Test implementation",
    "run_command": "Command to execute test",
    "expected_behavior": "What should happen",
    "validation_criteria": "How to verify success"
  },
  (Include test_execution when next_action is "run_test")
  
  "optimization_config": {
    "optimizer_type": "BootstrapFewShot|MIPROv2|COPRO|Ensemble",
    "target_module": "Module to optimize",
    "metric_code": "Metric implementation",
    "training_data": "Training examples format",
    "optimization_code": "Complete optimization code"
  },
  (Include optimization_config when next_action is "apply_optimization")
  
  "user_request": {
    "question": "Specific question for user",
    "context": "Why this information is needed",
    "examples": ["Helpful examples"],
    "default_option": "Suggested default if applicable"
  },
  (Include user_request when next_action is "request_input")
  
  "final_build": {
    "project_summary": "What was built",
    "main_file": "Primary entry point",
    "run_instructions": ["Step by step instructions to run"],
    "configuration_needed": ["Any setup required"],
    "example_usage": "Complete example of using the system",
    "next_steps": ["Suggestions for extending the system"]
  },
  (Include final_build when next_action is "complete_build")
  
  "updated_state": {
    "user_response_for_this_turn": null,
    "build_history": ["array of build steps completed"],
    "project_structure": {
      "modules_created": ["List of DSPy modules built"],
      "signatures_defined": ["List of signatures created"],
      "optimizers_configured": ["Optimization strategies applied"],
      "tests_written": ["Test files created"],
      "data_prepared": ["Data files generated"]
    },
    "implementation_state": {
      "core_functionality": {"status": "not_started|in_progress|complete", "details": {}},
      "testing_suite": {"status": "not_started|in_progress|complete", "details": {}},
      "optimization": {"status": "not_started|in_progress|complete", "details": {}},
      "documentation": {"status": "not_started|in_progress|complete", "details": {}},
      "deployment": {"status": "not_started|in_progress|complete", "details": {}}
    },
    "code_repository": {
      "signatures": {},
      "modules": {},
      "optimizers": {},
      "utilities": {},
      "tests": {}
    },
    "ultrathink_insights": ["Deep insights gained during analysis"],
    "sub_agent_reports": {}
  }
}

Sub-Agent Behaviors:

ARCHITECTURE AGENT:
- Analyzes requirements and designs modular structure
- Identifies needed signatures, modules, and data flow
- Creates system diagrams (in text/ASCII)
- Defines interfaces between components

CODE GENERATION AGENT:
- Writes complete, runnable Python/DSPy code
- Follows best practices and DSPy patterns
- Includes comprehensive error handling
- Adds helpful comments and docstrings

TESTING AGENT:
- Creates unit tests for each component
- Designs integration tests for the system
- Implements DSPy-specific test patterns
- Validates optimization results

OPTIMIZATION AGENT:
- Selects appropriate DSPy optimizers
- Implements custom metrics
- Prepares training data
- Applies and validates optimizations

DEPLOYMENT AGENT:
- Packages the complete solution
- Creates requirements.txt
- Writes deployment instructions
- Prepares production configurations

ULTRATHINK Principles:
1. Consider multiple solutions before choosing
2. Think through edge cases and failure modes
3. Design for extensibility and maintenance
4. Optimize for both performance and usability
5. Ensure robustness through comprehensive testing

Implementation Guidelines:
- All code must be complete and runnable
- Include proper imports and dependencies
- Handle errors gracefully
- Provide clear usage examples
- Follow DSPy best practices
EOF

# Function to extract JSON
extract_json() {
    local response="$1"
    if [[ "$response" == *'```json'* ]]; then
        echo "$response" | sed -n '/```json/,/```/p' | sed '1d;$d'
    else
        echo "$response"
    fi
}

# Function to create Python file
create_python_file() {
    local filepath="$1"
    local content="$2"
    echo "$content" > "$filepath"
    log_both "${C_SUCCESS}✓ Created: $filepath${C_RESET}"
}

# Function to run Python code
run_python() {
    local filepath="$1"
    local description="$2"
    log_both "${C_INFO}🏃 Running: $description${C_RESET}"
    cd "$PROJECT_DIR" && python3 "$filepath" 2>&1 | tee -a "$PROJECT_LOG"
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        log_both "${C_SUCCESS}✓ Success${C_RESET}"
    else
        log_both "${C_ERROR}✗ Failed with exit code: $exit_code${C_RESET}"
    fi
    return $exit_code
}

# 1. WELCOME MESSAGE
clear
log_both "${C_PROMPT}🏗️  DSPy Implementation Builder (with ULTRATHINK™)${C_RESET}"
log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
log_both "${C_INFO}I'll help you build complete, production-ready DSPy implementations!"
log_both ""
log_both "Capabilities:"
log_both "  • Build complex DSPy systems with multiple modules"
log_both "  • Create and run comprehensive test suites"
log_both "  • Apply optimization techniques (BootstrapFewShot, MIPROv2, etc.)"
log_both "  • Generate production-ready code with best practices"
log_both "  • Provide complete deployment packages"
log_both ""
log_both "Project directory: $PROJECT_DIR${C_RESET}"
log_both ""

# Detailed prompts for each example
DETAILED_PROMPT_1="Build a legal document extraction system that extracts case information, parties, dates, rulings, and key facts from court documents. The system should include: specialized signatures for legal entities (case metadata including case numbers, court names, filing dates, docket numbers), party extraction (plaintiffs, defendants, attorneys, judges, law firms), temporal information (filing dates, hearing dates, decision dates, deadlines), legal elements (claims, rulings, orders, motions, citations), monetary values (damages, settlements, fees, fines), and legal reasoning (key facts, holdings, rationale, precedents). Implement hierarchical extraction moving from document to sections to specific elements, with confidence scoring for each extraction, citation parsing for legal references, validation modules to ensure legal accuracy, and the ability to handle different court document types (complaints, motions, orders, judgments)."

DETAILED_PROMPT_2="Build a multi-stage research assistant that decomposes complex questions into sub-questions, performs targeted retrieval for each sub-question, synthesizes findings into comprehensive answers, and generates follow-up questions for deeper exploration. The system should include: question analysis module (identify question type, complexity level, required expertise domains, implicit assumptions), decomposition engine using ChainOfThought (break into atomic sub-questions, identify dependencies between questions, prioritize based on importance, detect when decomposition is complete), retrieval system with multiple strategies (dense retrieval for semantic search, sparse retrieval for keyword matching, hybrid approaches for best results, source diversity requirements), reranking and relevance scoring (relevance to original question, credibility assessment, recency weighting, contradiction detection), synthesis module with advanced features (claim extraction with evidence chains, confidence scoring based on source agreement, fact verification against multiple sources, narrative generation with smooth transitions), knowledge gap analysis (identify missing information, suggest specific searches, highlight low-confidence areas, recommend expert consultation points), and output generation in multiple formats (executive summary, detailed technical report, citation graph visualization, interactive Q&A format)."

DETAILED_PROMPT_3="Build a code review system that analyzes Python code for bugs, performance issues, and style violations, suggests improvements using Chain-of-Thought reasoning, and generates optimized versions with explanations. The system should include: static analysis engine (AST parsing for deep code understanding, control flow analysis, data flow tracking, type inference and checking), bug detection modules (syntax errors with fix suggestions, logic bugs including off-by-one errors, null pointer dereferences, race conditions in concurrent code, resource leaks and memory issues, exception handling problems), performance analyzer (time complexity analysis with Big O notation, space complexity evaluation, database query optimization, caching opportunities, algorithmic improvements), style and maintainability checker (PEP8 compliance with auto-fix, naming convention analysis, code duplication detection, cyclomatic complexity scoring, documentation coverage), security scanner (SQL injection vulnerabilities, XSS and CSRF risks, insecure cryptography usage, authentication/authorization flaws, dependency vulnerability checks), refactoring engine (extract method suggestions, design pattern applications, SOLID principle violations, code smell detection and fixes), test coverage analyzer (identify untested code paths, suggest test cases for edge cases, mutation testing recommendations, integration test gaps), and code generation features (optimized version with explanations, before/after comparisons, performance benchmarks, migration scripts for large refactors)."

DETAILED_PROMPT_4="Build a financial document analyzer that extracts key metrics from earnings reports, identifies trends across quarters, generates investment insights, and produces risk assessments with confidence scores. The system should include: document parsing engine (handle PDFs, HTML, XBRL formats, table extraction with structure preservation, footnote and annotation processing, multi-language support), financial metric extraction (income statement items: revenue, gross profit, operating income, net income, EPS; balance sheet items: assets, liabilities, equity, working capital; cash flow items: operating, investing, financing activities; ratios: P/E, debt-to-equity, ROE, current ratio, profit margins), trend analysis module (YoY and QoQ growth calculations, seasonality detection and adjustment, moving averages and momentum indicators, anomaly detection using statistical methods, peer comparison and industry benchmarks), sentiment analysis for qualitative sections (management discussion tone analysis, forward guidance extraction, risk factor changes, strategic initiative tracking, conference call transcript analysis), advanced analytics (segment performance breakdown, geographic revenue analysis, product line profitability, customer concentration risks, supply chain dependencies), investment signal generation (buy/hold/sell recommendations with reasoning, price target calculations, scenario analysis and sensitivity testing, portfolio impact assessment, risk-adjusted return projections), risk assessment framework (market risk: beta, volatility, correlation analysis; credit risk: debt coverage, default probability; operational risk: efficiency ratios, cost structure; regulatory risk: compliance mentions, legal proceedings; ESG risk: environmental, social, governance factors), and report generation (executive dashboard with key metrics, detailed analyst-style reports, regulatory filing summaries, custom alerts for significant changes, API endpoints for systematic trading)."

# Function to show example prompts
show_examples() {
    log_both ""
    log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    log_both "${C_PROMPT}📚 Example DSPy Implementation Prompts${C_RESET}"
    log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    log_both ""
    
    log_both "${C_SUCCESS}1. Legal Document Extraction System${C_RESET}"
    log_both "${C_INFO}   Build a legal document extraction system that extracts case information, parties,"
    log_both "   dates, rulings, and key facts from court documents. The system should extract:"
    log_both "   • Case metadata: case numbers, court names, filing dates, docket numbers"
    log_both "   • Parties involved: plaintiffs, defendants, attorneys, judges, law firms"
    log_both "   • Key dates: filing date, hearing dates, decision dates, deadlines"
    log_both "   • Legal elements: claims, rulings, orders, motions, citations"
    log_both "   • Monetary amounts: damages, settlements, fees, fines"
    log_both "   • Legal reasoning: key facts, holdings, rationale, precedents cited"
    log_both "   Using hierarchical extraction, confidence scoring, and citation parsing${C_RESET}"
    log_both ""
    
    log_both "${C_SUCCESS}2. Multi-Stage Research Assistant${C_RESET}"
    log_both "${C_INFO}   Build a multi-stage research assistant that decomposes complex questions,"
    log_both "   performs targeted retrieval for each sub-question, synthesizes findings,"
    log_both "   and generates comprehensive reports. Features include:"
    log_both "   • Question decomposition with dependency tracking"
    log_both "   • Hybrid retrieval (dense + sparse) with reranking"
    log_both "   • Multi-source synthesis with confidence scoring"
    log_both "   • Knowledge gap analysis and contradiction detection"
    log_both "   • Multiple output formats (summary, technical, interactive)${C_RESET}"
    log_both ""
    
    log_both "${C_SUCCESS}3. Code Review and Optimization Agent${C_RESET}"
    log_both "${C_INFO}   Build a code review system that analyzes Python code for bugs, performance"
    log_both "   issues, and style violations. Comprehensive features:"
    log_both "   • AST-based static analysis and type checking"
    log_both "   • Bug detection (logic errors, race conditions, memory leaks)"
    log_both "   • Performance analysis with complexity calculations"
    log_both "   • Security scanning for vulnerabilities"
    log_both "   • Automated refactoring with design pattern suggestions"
    log_both "   • Test coverage analysis and test case generation${C_RESET}"
    log_both ""
    
    log_both "${C_SUCCESS}4. Financial Report Analysis Pipeline${C_RESET}"
    log_both "${C_INFO}   Build a financial document analyzer that extracts key metrics from earnings"
    log_both "   reports and generates investment insights. Includes:"
    log_both "   • Multi-format parsing (PDF, HTML, XBRL) with table extraction"
    log_both "   • Comprehensive metric extraction (P&L, balance sheet, cash flow)"
    log_both "   • Trend analysis with anomaly detection and peer comparison"
    log_both "   • Sentiment analysis of management discussion and guidance"
    log_both "   • Risk assessment (market, credit, operational, regulatory, ESG)"
    log_both "   • Investment signals with scenario analysis${C_RESET}"
    log_both ""
    
    log_both "${C_PROMPT}Copy and paste any of these prompts, or describe your own DSPy project!${C_RESET}"
    log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    log_both ""
}

log_both "${C_PROMPT}What DSPy system would you like to build?${C_RESET}"
log_both "${C_INFO}Type 'examples' to see detailed project prompts, or describe your own idea${C_RESET}"
echo -n -e "${C_USER}➤ ${C_RESET}"
read -r INITIAL_INPUT

# Check if user wants to see examples
if [[ "$INITIAL_INPUT" == "examples" ]] || [[ "$INITIAL_INPUT" == "example" ]]; then
    show_examples
    log_both "${C_PROMPT}Now, what would you like to build? (Enter 1-4 for an example, or your own idea)${C_RESET}"
    echo -n -e "${C_USER}➤ ${C_RESET}"
    read -r INITIAL_INPUT
    
    # Map number selections to detailed prompts
    case "$INITIAL_INPUT" in
        "1")
            INITIAL_INPUT="$DETAILED_PROMPT_1"
            log_both "${C_SUCCESS}Selected: Legal Document Extraction System${C_RESET}"
            ;;
        "2")
            INITIAL_INPUT="$DETAILED_PROMPT_2"
            log_both "${C_SUCCESS}Selected: Multi-Stage Research Assistant${C_RESET}"
            ;;
        "3")
            INITIAL_INPUT="$DETAILED_PROMPT_3"
            log_both "${C_SUCCESS}Selected: Code Review and Optimization Agent${C_RESET}"
            ;;
        "4")
            INITIAL_INPUT="$DETAILED_PROMPT_4"
            log_both "${C_SUCCESS}Selected: Financial Report Analysis Pipeline${C_RESET}"
            ;;
    esac
fi

# Log user input
echo "➤ $INITIAL_INPUT" >> "$PROJECT_LOG"

# Validate input
if [ -z "$INITIAL_INPUT" ]; then
    log_both "${C_ERROR}No input provided. Exiting...${C_RESET}"
    exit 1
fi

# 2. INITIALIZE THE STATE
STATE=$(python3 -c "
import json
import sys

initial_input = '''$INITIAL_INPUT'''

initial_state = {
    'user_response_for_this_turn': initial_input,
    'build_history': [],
    'project_structure': {
        'modules_created': [],
        'signatures_defined': [],
        'optimizers_configured': [],
        'tests_written': [],
        'data_prepared': []
    },
    'implementation_state': {
        'core_functionality': {'status': 'not_started', 'details': {}},
        'testing_suite': {'status': 'not_started', 'details': {}},
        'optimization': {'status': 'not_started', 'details': {}},
        'documentation': {'status': 'not_started', 'details': {}},
        'deployment': {'status': 'not_started', 'details': {}}
    },
    'code_repository': {
        'signatures': {},
        'modules': {},
        'optimizers': {},
        'utilities': {},
        'tests': {}
    },
    'ultrathink_insights': [],
    'sub_agent_reports': {}
}

print(json.dumps(initial_state))
")

# Build loop variables
BUILD_COUNT=0
CURRENT_PHASE="analyzing"

# Create setup.py
cat > "$PROJECT_DIR/setup.py" << 'EOSETUP'
from setuptools import setup, find_packages

setup(
    name="dspy_implementation",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "dspy-ai>=2.4.0",
        "openai>=1.0.0",
        "numpy>=1.24.0",
        "pytest>=7.0.0",
    ],
)
EOSETUP

# Create __init__.py files
touch "$PROJECT_DIR/src/__init__.py"
touch "$PROJECT_DIR/tests/__init__.py"

# 3. THE BUILD LOOP
while true; do
    # Call Claude with the current state
    log_both "\n${C_INFO}[ULTRATHINK: Analyzing and planning next action...]${C_RESET}"
    CLAUDE_RESPONSE=$(echo "$STATE" | claude -p "$PROMPT" 2>&1)
    
    # Extract JSON
    CLEANED_RESPONSE=$(extract_json "$CLAUDE_RESPONSE")
    
    # Basic validation
    if ! echo "$CLEANED_RESPONSE" | python3 -m json.tool > /dev/null 2>&1; then
        log_both "${C_ERROR}🔥 Error processing response. Retrying...${C_RESET}"
        echo "ERROR: $CLAUDE_RESPONSE" >> "$PROJECT_LOG"
        continue
    fi
    
    # Extract current phase
    CURRENT_PHASE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('current_phase', 'unknown'))" 2>/dev/null || echo "unknown")
    CONFIDENCE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(f\"{json.load(sys.stdin).get('confidence_level', 0):.1%}\")" 2>/dev/null || echo "0%")
    
    # Show ULTRATHINK analysis if available
    ULTRATHINK=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
ultra = data.get('ultrathink_analysis', {})
if ultra:
    print('\\n🧠 ULTRATHINK Analysis:')
    print(f'  Understanding: {ultra.get(\"requirement_understanding\", \"\")}')
    approaches = ultra.get('considered_approaches', [])
    if approaches:
        print('  Considered approaches:')
        for i, approach in enumerate(approaches, 1):
            print(f'    {i}. {approach}')
    print(f'  Selected: {ultra.get(\"selected_approach\", \"\")}')
" 2>/dev/null)
    
    if [ -n "$ULTRATHINK" ]; then
        log_both "${C_AGENT}$ULTRATHINK${C_RESET}"
    fi
    
    # Extract next action
    NEXT_ACTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('next_action', ''))")
    
    log_both "${C_INFO}Phase: $CURRENT_PHASE | Confidence: $CONFIDENCE | Action: $NEXT_ACTION${C_RESET}"
    
    if [ "$NEXT_ACTION" = "delegate_task" ]; then
        # Sub-agent delegation
        TARGET_AGENT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('agent_delegation', {}).get('target_agent', ''))")
        TASK_DESC=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('agent_delegation', {}).get('task_description', ''))")
        
        log_both ""
        log_both "${C_AGENT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_AGENT}🤖 Delegating to: ${TARGET_AGENT^^} AGENT${C_RESET}"
        log_both "${C_AGENT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_INFO}Task: $TASK_DESC${C_RESET}"
        log_both ""
        log_both "${C_USER}Press Enter to continue with sub-agent task...${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r USER_RESPONSE
        echo "➤ $USER_RESPONSE" >> "$PROJECT_LOG"
        
    elif [ "$NEXT_ACTION" = "show_implementation" ]; then
        # Show and save implementation
        BUILD_COUNT=$((BUILD_COUNT + 1))
        
        COMPONENT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('implementation_details', {}).get('component_name', ''))")
        DESC=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('implementation_details', {}).get('description', ''))")
        CODE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('implementation_details', {}).get('code', ''))")
        FILEPATH=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('implementation_details', {}).get('file_path', ''))")
        USAGE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('implementation_details', {}).get('usage_example', ''))")
        
        log_both ""
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_PROMPT}💻 Implementation: $COMPONENT${C_RESET}"
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_INFO}Description: $DESC${C_RESET}"
        log_both ""
        log_both "${C_CODE}Code:${C_RESET}"
        echo "$CODE" | head -30 | tee -a "$PROJECT_LOG"
        if [ $(echo "$CODE" | wc -l) -gt 30 ]; then
            log_both "${C_INFO}... (truncated for display, full code saved to file)${C_RESET}"
        fi
        
        # Save the code
        FULL_PATH="$PROJECT_DIR/$FILEPATH"
        create_python_file "$FULL_PATH" "$CODE"
        
        log_both ""
        log_both "${C_INFO}Usage example:${C_RESET}"
        log_both "$USAGE"
        
        # Show dependencies if any
        DEPS=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
deps = data.get('implementation_details', {}).get('dependencies', [])
if deps:
    print('\\nDependencies:')
    for dep in deps:
        print(f'  • {dep}')
" 2>/dev/null)
        
        if [ -n "$DEPS" ]; then
            log_both "${C_INFO}$DEPS${C_RESET}"
        fi
        
        log_both ""
        log_both "${C_USER}Ready to continue? (Press Enter or type feedback)${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r USER_RESPONSE
        echo "➤ $USER_RESPONSE" >> "$PROJECT_LOG"
        
    elif [ "$NEXT_ACTION" = "run_test" ]; then
        # Run tests
        TEST_NAME=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('test_execution', {}).get('test_name', ''))")
        TEST_CODE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('test_execution', {}).get('test_code', ''))")
        RUN_CMD=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('test_execution', {}).get('run_command', ''))")
        EXPECTED=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('test_execution', {}).get('expected_behavior', ''))")
        
        log_both ""
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_PROMPT}🧪 Test: $TEST_NAME${C_RESET}"
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_INFO}Expected behavior: $EXPECTED${C_RESET}"
        log_both ""
        
        # Save test code
        TEST_FILE="$PROJECT_DIR/tests/test_${TEST_NAME// /_}.py"
        create_python_file "$TEST_FILE" "$TEST_CODE"
        
        log_both "${C_INFO}Run command: $RUN_CMD${C_RESET}"
        log_both ""
        log_both "${C_USER}Run this test? (y/n)${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r RUN_CONFIRM
        echo "➤ $RUN_CONFIRM" >> "$PROJECT_LOG"
        
        if [[ "$RUN_CONFIRM" =~ ^[Yy] ]]; then
            cd "$PROJECT_DIR" && eval "$RUN_CMD" 2>&1 | tee -a "$PROJECT_LOG"
        fi
        
        USER_RESPONSE="Test execution completed"
        
    elif [ "$NEXT_ACTION" = "apply_optimization" ]; then
        # Apply DSPy optimization
        OPT_TYPE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('optimization_config', {}).get('optimizer_type', ''))")
        TARGET=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('optimization_config', {}).get('target_module', ''))")
        OPT_CODE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('optimization_config', {}).get('optimization_code', ''))")
        
        log_both ""
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_PROMPT}🚀 Optimization: $OPT_TYPE${C_RESET}"
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_INFO}Target module: $TARGET${C_RESET}"
        log_both ""
        
        # Save optimization code
        OPT_FILE="$PROJECT_DIR/src/optimization.py"
        create_python_file "$OPT_FILE" "$OPT_CODE"
        
        log_both "${C_USER}Apply optimization? (y/n)${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r OPT_CONFIRM
        echo "➤ $OPT_CONFIRM" >> "$PROJECT_LOG"
        
        if [[ "$OPT_CONFIRM" =~ ^[Yy] ]]; then
            run_python "src/optimization.py" "Optimization process"
        fi
        
        USER_RESPONSE="Optimization completed"
        
    elif [ "$NEXT_ACTION" = "request_input" ]; then
        # Request user input
        QUESTION=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('user_request', {}).get('question', ''))")
        CONTEXT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('user_request', {}).get('context', ''))")
        DEFAULT=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('user_request', {}).get('default_option', ''))")
        
        log_both ""
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_INFO}Context: $CONTEXT${C_RESET}"
        log_both ""
        log_both "${C_PROMPT}❓ $QUESTION${C_RESET}"
        
        # Show examples if available
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
examples = data.get('user_request', {}).get('examples', [])
if examples:
    print('\\nExamples:')
    for ex in examples:
        print(f'  • {ex}')
" | tee -a "$PROJECT_LOG"
        
        if [ -n "$DEFAULT" ]; then
            log_both "${C_INFO}Default: $DEFAULT${C_RESET}"
        fi
        
        log_both ""
        log_both "${C_USER}Your response:${C_RESET}"
        echo -n -e "${C_USER}➤ ${C_RESET}"
        read -r USER_RESPONSE
        echo "➤ $USER_RESPONSE" >> "$PROJECT_LOG"
        
    elif [ "$NEXT_ACTION" = "complete_build" ]; then
        # Complete the build
        SUMMARY=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('final_build', {}).get('project_summary', ''))")
        MAIN_FILE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('final_build', {}).get('main_file', ''))")
        EXAMPLE=$(echo "$CLEANED_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin).get('final_build', {}).get('example_usage', ''))")
        
        log_both ""
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both "${C_PROMPT}🎉 Build Complete!${C_RESET}"
        log_both "${C_PROMPT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
        log_both ""
        log_both "${C_INFO}📦 Project: $SUMMARY${C_RESET}"
        log_both "${C_INFO}📁 Location: $PROJECT_DIR${C_RESET}"
        log_both "${C_INFO}🚀 Main file: $MAIN_FILE${C_RESET}"
        log_both ""
        
        # Show run instructions
        log_both "${C_SUCCESS}To run your DSPy implementation:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
instructions = data.get('final_build', {}).get('run_instructions', [])
for i, step in enumerate(instructions, 1):
    print(f'  {i}. {step}')
" | tee -a "$PROJECT_LOG"
        
        log_both ""
        log_both "${C_INFO}Example usage:${C_RESET}"
        log_both "${C_CODE}$EXAMPLE${C_RESET}"
        
        # Create run script
        cat > "$PROJECT_DIR/run.sh" << 'EORUN'
#!/bin/bash
cd "$(dirname "$0")"
python3 -m pip install -e . --quiet
python3 src/main.py "$@"
EORUN
        chmod +x "$PROJECT_DIR/run.sh"
        
        log_both ""
        log_both "${C_SUCCESS}✓ Created run.sh for easy execution${C_RESET}"
        
        # Show next steps
        log_both ""
        log_both "${C_INFO}Next steps:${C_RESET}"
        echo "$CLEANED_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
steps = data.get('final_build', {}).get('next_steps', [])
for step in steps:
    print(f'  • {step}')
" | tee -a "$PROJECT_LOG"
        
        # Save final state
        echo "$CLEANED_RESPONSE" > "$PROJECT_DIR/build_state.json"
        
        log_both ""
        log_both "${C_INFO}Build artifacts: $BUILD_COUNT components${C_RESET}"
        log_both "${C_INFO}Full build log: $PROJECT_LOG${C_RESET}"
        
        break # Exit the loop
    else
        log_both "${C_ERROR}🔥 Unknown action: '$NEXT_ACTION'. Continuing...${C_RESET}"
        USER_RESPONSE="Please continue"
    fi
    
    # Update state for next iteration
    if [ "$NEXT_ACTION" != "complete_build" ]; then
        STATE=$(echo "$CLEANED_RESPONSE" | python3 -c "
import json
import sys

data = json.load(sys.stdin)
user_response = '''$USER_RESPONSE'''

# Update the state with the user's response
data['updated_state']['user_response_for_this_turn'] = user_response

print(json.dumps(data['updated_state']))
")
    fi
done

log_both ""
log_both "${C_PROMPT}Thank you for building with DSPy! Your implementation is ready to use! 🚀${C_RESET}"