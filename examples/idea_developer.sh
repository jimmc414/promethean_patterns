#!/bin/bash
# Interactive Idea Developer - Implements the Q&A workflow

SESSION_ID=$(uuidgen)
CONTEXT_FILE="/tmp/idea_context_$SESSION_ID.json"
echo '{"idea":"","requirements":[],"qa_history":[]}' > "$CONTEXT_FILE"

# Colors for better UX
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Interactive Idea Developer${NC}"
echo -e "${BLUE}=============================${NC}"
echo

# Phase 1: Gather initial idea
echo -e "${GREEN}What's your idea?${NC}"
read -r user_idea

# Update context
jq --arg idea "$user_idea" '.idea = $idea' "$CONTEXT_FILE" > "$CONTEXT_FILE.tmp" && mv "$CONTEXT_FILE.tmp" "$CONTEXT_FILE"

# Phase 2: Q&A Loop
while true; do
    # Get Claude's questions based on current context
    questions=$(claude -p "You are gathering requirements for a software project. 
    Context: $(cat "$CONTEXT_FILE")
    
    Output JSON: {
        understanding_level: 0.0-1.0,
        missing_info: [],
        questions: ['specific question 1', 'specific question 2', ...],
        ready_for_requirements: boolean
    }" <<< "$user_idea")
    
    understanding=$(echo "$questions" | jq -r '.understanding_level')
    ready=$(echo "$questions" | jq -r '.ready_for_requirements')
    
    echo -e "\n${YELLOW}Understanding level: $understanding${NC}"
    
    if [ "$ready" = "true" ]; then
        echo -e "${GREEN}✓ I have enough information to proceed!${NC}"
        break
    fi
    
    # Ask questions
    echo "$questions" | jq -r '.questions[]' | while IFS= read -r question; do
        echo -e "\n${BLUE}Q: $question${NC}"
        read -r answer
        
        # Store Q&A
        jq --arg q "$question" --arg a "$answer" \
            '.qa_history += [{"q": $q, "a": $a}]' \
            "$CONTEXT_FILE" > "$CONTEXT_FILE.tmp" && mv "$CONTEXT_FILE.tmp" "$CONTEXT_FILE"
    done
done

echo -e "\n${GREEN}Generating requirements...${NC}"

# Phase 3: Generate requirements.md
claude -p "Based on this context, generate formal requirements.
Context: $(cat "$CONTEXT_FILE")

Output JSON: {
    functional_requirements: [
        {id: 'FR1', SHALL: '...', SHALL_NOT: '...'},
        {id: 'FR2', MUST: '...', MUST_NOT: '...'}
    ],
    non_functional_requirements: [
        {id: 'NFR1', SHALL: '...', rationale: '...'}
    ]
}" | jq -r '
"# Requirements Document\n\n" +
"## Functional Requirements\n\n" +
(.functional_requirements[] | 
    "### \(.id)\n" +
    if .SHALL then "- SHALL: \(.SHALL)\n" else "" end +
    if .SHALL_NOT then "- SHALL NOT: \(.SHALL_NOT)\n" else "" end +
    if .MUST then "- MUST: \(.MUST)\n" else "" end +
    if .MUST_NOT then "- MUST NOT: \(.MUST_NOT)\n" else "" end +
    "\n"
) +
"\n## Non-Functional Requirements\n\n" +
(.non_functional_requirements[] |
    "### \(.id)\n" +
    "- SHALL: \(.SHALL)\n" +
    if .rationale then "- Rationale: \(.rationale)\n" else "" end +
    "\n"
)' > requirements.md

echo -e "${GREEN}✓ Created requirements.md${NC}"

# Phase 4: Generate architecture.md
echo -e "\n${GREEN}Generating architecture...${NC}"

claude -p "Based on these requirements, design the architecture.
Context: $(cat "$CONTEXT_FILE")
Requirements: $(cat requirements.md)

Output JSON: {
    overview: '...',
    technology_stack: [
        {layer: '...', technology: '...', rationale: '...'}
    ],
    components: [
        {name: '...', responsibility: '...', interfaces: []}
    ],
    data_flow: [
        {from: '...', to: '...', data: '...', protocol: '...'}
    ],
    key_decisions: [
        {decision: '...', rationale: '...', alternatives_considered: []}
    ]
}" | jq -r '
"# Architecture Document\n\n" +
"## Overview\n\n\(.overview)\n\n" +
"## Technology Stack\n\n" +
(.technology_stack[] | "- **\(.layer)**: \(.technology) - \(.rationale)\n") +
"\n## Components\n\n" +
(.components[] | 
    "### \(.name)\n" +
    "**Responsibility**: \(.responsibility)\n" +
    "**Interfaces**: \(.interfaces | join(", "))\n\n"
) +
"\n## Data Flow\n\n" +
(.data_flow[] | "- \(.from) → \(.to): \(.data) via \(.protocol)\n") +
"\n## Key Architectural Decisions\n\n" +
(.key_decisions[] |
    "### \(.decision)\n" +
    "**Rationale**: \(.rationale)\n" +
    "**Alternatives**: \(.alternatives_considered | join(", "))\n\n"
)' > architecture.md

echo -e "${GREEN}✓ Created architecture.md${NC}"

# Phase 5: Generate implementation.md
echo -e "\n${GREEN}Generating implementation plan...${NC}"

claude -p "Create a detailed implementation guide.
Context: $(cat "$CONTEXT_FILE")
Requirements: $(cat requirements.md)
Architecture: $(cat architecture.md)

Output JSON: {
    setup_instructions: {
        prerequisites: [],
        steps: []
    },
    modules: [
        {
            file_path: '...',
            purpose: '...',
            key_functions: [],
            dependencies: [],
            tests_needed: []
        }
    ],
    implementation_order: [],
    acceptance_criteria: []
}" | jq -r '
"# Implementation Guide\n\n" +
"## Setup Instructions\n\n" +
"### Prerequisites\n" +
(.setup_instructions.prerequisites[] | "- \(.)\n") +
"\n### Setup Steps\n" +
(.setup_instructions.steps[] | "\(.)\n") +
"\n## Modules\n\n" +
(.modules[] |
    "### \(.file_path)\n" +
    "**Purpose**: \(.purpose)\n" +
    "**Key Functions**:\n" + (.key_functions[] | "- \(.)\n") +
    "**Dependencies**: \(.dependencies | join(", "))\n" +
    "**Tests**: \(.tests_needed | join(", "))\n\n"
) +
"\n## Implementation Order\n\n" +
(.implementation_order[] | "1. \(.)\n") +
"\n## Acceptance Criteria\n\n" +
(.acceptance_criteria[] | "- [ ] \(.)\n")' > implementation.md

echo -e "${GREEN}✓ Created implementation.md${NC}"

# Phase 6: Review and confirm
echo -e "\n${BLUE}📋 Generated Documents:${NC}"
echo "- requirements.md"
echo "- architecture.md" 
echo "- implementation.md"
echo
read -p "Would you like to review before building? (y/n): " review

if [ "$review" = "y" ]; then
    echo -e "\n${YELLOW}=== REQUIREMENTS ===${NC}"
    head -20 requirements.md
    echo "..."
    echo -e "\n${YELLOW}=== ARCHITECTURE ===${NC}"
    head -20 architecture.md
    echo "..."
    echo -e "\n${YELLOW}=== IMPLEMENTATION ===${NC}"
    head -20 implementation.md
    echo "..."
fi

read -p $'\nProceed with building the project? (y/n): ' build

if [ "$build" = "y" ]; then
    echo -e "\n${GREEN}🔨 Building project...${NC}"
    
    # Generate build script
    claude -p "Generate build commands based on the implementation plan.
    Implementation: $(cat implementation.md)
    
    Output JSON: {
        setup_commands: [],
        file_creation: [{path: '...', content: '...'}],
        test_commands: []
    }" | jq -r '.setup_commands[]' | while read -r cmd; do
        echo "$ $cmd"
        eval "$cmd"
    done
    
    echo -e "\n${GREEN}✅ Project setup complete!${NC}"
    echo "Check the generated requirements.md, architecture.md, and implementation.md"
else
    echo -e "\n${YELLOW}Project files generated but not built. You can build manually using implementation.md${NC}"
fi

# Cleanup
rm -f "$CONTEXT_FILE"