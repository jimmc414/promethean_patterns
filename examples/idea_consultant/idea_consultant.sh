#!/bin/bash
# Recursive Inquisitor Pattern - Startup Idea Consultant
# This is a complete, working implementation of the Recursive Inquisitor pattern
# It demonstrates how to iteratively refine a vague idea into a structured plan

set -euo pipefail

# Configuration
MAX_ITERATIONS=10
LLM_COMMAND="${LLM_COMMAND:-claude -p}"

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize state template
STATE_TEMPLATE='{
  "user_response_for_this_turn": null,
  "idea_canvas": {
    "problem": {"value": null, "status": "empty", "confidence": 0},
    "solution": {"value": null, "status": "empty", "confidence": 0},
    "target_audience": {"value": null, "status": "empty", "confidence": 0},
    "unique_value": {"value": null, "status": "empty", "confidence": 0},
    "monetization": {"value": null, "status": "empty", "confidence": 0},
    "competition": {"value": null, "status": "empty", "confidence": 0}
  },
  "consultant_analysis_log": [],
  "questions_asked": 0,
  "iteration": 0
}'

# Master prompt for the Recursive Inquisitor
PROMPT='You are an expert startup consultant implementing the Recursive Inquisitor pattern.

Your goal is to transform a vague startup idea into a comprehensive, well-structured business concept by asking targeted questions. You must analyze the current state of the idea canvas and identify the most critical missing or weak element to address next.

INSTRUCTIONS:
1. Analyze the idea_canvas to identify the weakest or most important missing element
2. Consider the relationships between canvas elements
3. Formulate a single, focused question that will yield the most valuable information
4. Update the canvas with any new insights from the user response
5. Decide whether the canvas is complete enough to conclude

DECISION CRITERIA:
- Conclude when all canvas elements have status "refined" or "solid"
- Conclude when confidence scores average above 80%
- Conclude if the user seems unable to provide more detail
- Never exceed 10 questions total

RESPONSE FORMAT:
You must respond with valid JSON in exactly this format:
{
  "next_action": "ask" | "conclude",
  "analysis": {
    "weakest_element": "element name",
    "reasoning": "why this element needs attention",
    "canvas_completeness": 0-100
  },
  "question_for_user": {
    "question_text": "your focused question",
    "question_reasoning": "why this question will help",
    "expected_insight": "what you hope to learn"
  },
  "updated_state": {
    ...complete updated state object...
  },
  "refined_pitch": {
    "summary": "executive summary",
    "problem": "clear problem statement",
    "solution": "proposed solution",
    "market": "target market analysis",
    "business_model": "how it makes money",
    "competitive_advantage": "why it will succeed",
    "next_steps": ["step1", "step2", "step3"]
  }
}

CURRENT STATE:'

# Function to display the current canvas state
display_canvas() {
  local state="$1"
  echo -e "\n${BLUE}═══ Current Idea Canvas ═══${NC}"
  echo "$state" | jq -r '.idea_canvas | to_entries[] | 
    "\(.key | ascii_upcase | .[0:15] | . + (" " * (15 - length))): \(.value.value // "empty") [\(.value.status)]"'
  echo -e "${BLUE}═════════════════════════${NC}\n"
}

# Function to validate JSON response
validate_json() {
  local json="$1"
  if ! echo "$json" | jq -e '.next_action' > /dev/null 2>&1; then
    return 1
  fi
  return 0
}

# Welcome message
clear
echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Startup Idea Consultant - Promethean    ║${NC}"
echo -e "${GREEN}║   Recursive Inquisitor Pattern Demo       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}\n"

echo "I'll help you refine your startup idea through targeted questions."
echo "Let's transform your initial concept into a comprehensive business plan."
echo -e "\n${YELLOW}What's your startup idea? (Be as vague or specific as you like)${NC}"
read -r SEED_IDEA

# Initialize state with seed idea
STATE=$(echo "$STATE_TEMPLATE" | jq ".user_response_for_this_turn = \"$SEED_IDEA\" | .iteration = 1")

# Main refinement loop
ITERATION=0
while [ $ITERATION -lt $MAX_ITERATIONS ]; do
  ((ITERATION++))
  
  # Display current canvas state
  display_canvas "$STATE"
  
  echo -e "${BLUE}Analyzing your idea (iteration $ITERATION)...${NC}"
  
  # Prepare full prompt with current state
  FULL_PROMPT="$PROMPT
$(echo "$STATE" | jq -c .)"
  
  # Call LLM
  RESPONSE=$(echo "$FULL_PROMPT" | $LLM_COMMAND 2>/dev/null)
  
  # Validate response
  if ! validate_json "$RESPONSE"; then
    echo -e "${RED}Error: Invalid response from consultant. Retrying...${NC}"
    sleep 2
    continue
  fi
  
  # Extract action
  ACTION=$(echo "$RESPONSE" | jq -r '.next_action')
  
  if [ "$ACTION" = "ask" ]; then
    # Extract question details
    QUESTION=$(echo "$RESPONSE" | jq -r '.question_for_user.question_text')
    REASONING=$(echo "$RESPONSE" | jq -r '.question_for_user.question_reasoning')
    WEAKEST=$(echo "$RESPONSE" | jq -r '.analysis.weakest_element')
    COMPLETENESS=$(echo "$RESPONSE" | jq -r '.analysis.canvas_completeness')
    
    # Display analysis
    echo -e "\n${BLUE}📊 Analysis:${NC}"
    echo "   • Weakest element: $WEAKEST"
    echo "   • Canvas completeness: ${COMPLETENESS}%"
    echo "   • Reasoning: $REASONING"
    
    # Ask question
    echo -e "\n${YELLOW}❓ $QUESTION${NC}"
    read -r USER_ANSWER
    
    # Update state for next iteration
    STATE=$(echo "$RESPONSE" | jq ".updated_state.user_response_for_this_turn = \"$USER_ANSWER\" | .updated_state.iteration = $((ITERATION + 1)) | .updated_state.questions_asked = $ITERATION | .updated_state")
    
  elif [ "$ACTION" = "conclude" ]; then
    # Display final canvas
    echo -e "\n${GREEN}✅ Refinement complete!${NC}"
    display_canvas "$STATE"
    
    # Extract and display refined pitch
    echo -e "\n${GREEN}═══ Your Refined Startup Pitch ═══${NC}\n"
    
    PITCH=$(echo "$RESPONSE" | jq '.refined_pitch')
    
    echo -e "${GREEN}EXECUTIVE SUMMARY:${NC}"
    echo "$PITCH" | jq -r '.summary'
    
    echo -e "\n${GREEN}PROBLEM:${NC}"
    echo "$PITCH" | jq -r '.problem'
    
    echo -e "\n${GREEN}SOLUTION:${NC}"
    echo "$PITCH" | jq -r '.solution'
    
    echo -e "\n${GREEN}TARGET MARKET:${NC}"
    echo "$PITCH" | jq -r '.market'
    
    echo -e "\n${GREEN}BUSINESS MODEL:${NC}"
    echo "$PITCH" | jq -r '.business_model'
    
    echo -e "\n${GREEN}COMPETITIVE ADVANTAGE:${NC}"
    echo "$PITCH" | jq -r '.competitive_advantage'
    
    echo -e "\n${GREEN}NEXT STEPS:${NC}"
    echo "$PITCH" | jq -r '.next_steps[]' | while read -r step; do
      echo "   → $step"
    done
    
    # Save results
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_FILE="startup_idea_${TIMESTAMP}.json"
    echo "$RESPONSE" | jq '.' > "$OUTPUT_FILE"
    echo -e "\n${BLUE}📄 Full analysis saved to: $OUTPUT_FILE${NC}"
    
    exit 0
  fi
done

echo -e "${YELLOW}Maximum iterations reached. Saving current state...${NC}"
echo "$STATE" | jq '.' > "startup_idea_incomplete_$(date +%Y%m%d_%H%M%S).json"