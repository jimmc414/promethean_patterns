#!/bin/bash
# Translates original patterns to working Claude prompts

translate_pattern() {
    local pattern="$1"
    local input="$2"
    
    # Remove the complex conditional syntax and explain it
    if [[ "$pattern" =~ "?" ]]; then
        echo "Output JSON evaluating the condition in the pattern"
    elif [[ "$pattern" =~ "..." ]]; then
        echo "Output JSON filling in contextual data where ... appears"
    elif [[ "$pattern" =~ ".map" ]] || [[ "$pattern" =~ ".filter" ]]; then
        echo "Output JSON with the array transformation described"
    else
        echo "Output JSON: $pattern"
    fi
}

# Example usage
original='{n:5,big:n>10?"yes":"no"}'
translated=$(translate_pattern "$original" "5")
echo "Original: $original"
echo "Translated: $translated"
