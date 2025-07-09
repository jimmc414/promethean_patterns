#!/bin/bash
# Pattern Migration Tool - Converts original syntax to working Claude patterns

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Migration rules database
declare -A MIGRATION_RULES=(
    # Conditionals
    ['condition\?true:false']='condition is true then "true" else "false"'
    ['(\w+)>(\d+)\?"([^"]+)":"([^"]+)"']='$1 is greater than $2 then "$3" else "$4"'
    ['(\w+)<(\d+)\?"([^"]+)":"([^"]+)"']='$1 is less than $2 then "$3" else "$4"'
    ['(\w+)==(\w+)\?"([^"]+)":"([^"]+)"']='$1 equals $2 then "$3" else "$4"'
    
    # Arrays
    ['\[\.\.\.(\w+),"([^"]+)"\]']='array containing $1 elements plus "$2"'
    ['\[\.\.\.(\w+),\.\.\.(\w+)\]']='array combining $1 and $2 elements'
    ['\.map\((\w+)=>(.+)\)']='array with each element transformed by $2'
    ['\.filter\((\w+)=>(.+)\)']='array filtered where $2'
    ['\.reduce\((.+)\)']='array reduced by $1'
    
    # Object methods
    ['(\w+)\.toLowerCase\(\)']='$1 converted to lowercase'
    ['(\w+)\.toUpperCase\(\)']='$1 converted to uppercase'
    ['(\w+)\.split\("([^"]+)"\)']='$1 split by "$2"'
    ['(\w+)\.join\("([^"]+)"\)']='$1 joined with "$2"'
    ['(\w+)\.length']='length of $1'
    
    # Ellipsis
    ['\.\.\.']='containing the input'
    ['{(\w+):\.\.\.}']='{"$1":"value from input"}'
    
    # If conditions
    ['if (\w+)=="(\w+)":{([^}]+)}']='if $1 is "$2" then include $3'
    ['if (\w+)>(\d+):{([^}]+)}']='if $1 is greater than $2 then include $3'
    ['if (\w+)<(\d+):{([^}]+)}']='if $1 is less than $2 then include $3'
)

# Migration log
MIGRATION_LOG="migration_log_$(date +%Y%m%d_%H%M%S).md"

# Initialize log
cat > "$MIGRATION_LOG" << EOF
# Pattern Migration Log

Generated: $(date)

## Migration Summary

EOF

# Function to migrate a single pattern
migrate_pattern() {
    local original="$1"
    local migrated="$original"
    local rules_applied=0
    
    echo -e "\n${BLUE}Original Pattern:${NC}"
    echo "$original"
    
    # Apply migration rules
    for rule in "${!MIGRATION_RULES[@]}"; do
        if [[ "$migrated" =~ $rule ]]; then
            local replacement="${MIGRATION_RULES[$rule]}"
            # Perform substitution (simplified - in real use would need proper regex replacement)
            echo -e "${YELLOW}Applying rule:${NC} $rule -> $replacement"
            rules_applied=$((rules_applied + 1))
            
            # For demonstration, we'll show the conceptual transformation
            migrated="Output JSON where $replacement"
        fi
    done
    
    if [ $rules_applied -eq 0 ]; then
        # No rules matched, try generic transformation
        echo -e "${YELLOW}No specific rules matched, applying generic transformation${NC}"
        migrated="Output JSON: $original"
    fi
    
    echo -e "${GREEN}Migrated Pattern:${NC}"
    echo "$migrated"
    
    # Log migration
    cat >> "$MIGRATION_LOG" << EOF

### Migration #$(grep -c "^###" "$MIGRATION_LOG" || echo "1")

**Original:**
\`\`\`
$original
\`\`\`

**Migrated:**
\`\`\`
$migrated
\`\`\`

**Rules Applied:** $rules_applied

EOF
    
    return $rules_applied
}

# Function to migrate a file
migrate_file() {
    local input_file="$1"
    local output_file="${input_file%.md}_migrated.md"
    
    echo -e "${BLUE}=== Migrating file: $input_file ===${NC}"
    
    # Create output file
    cat > "$output_file" << EOF
# Migrated Patterns from $input_file

Generated: $(date)

## Migrated Examples

EOF
    
    # Process each code block
    local in_code_block=false
    local pattern_buffer=""
    local line_num=0
    
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        if [[ "$line" =~ ^\`\`\`bash ]]; then
            in_code_block=true
            pattern_buffer=""
        elif [[ "$line" =~ ^\`\`\` ]] && [ "$in_code_block" = true ]; then
            in_code_block=false
            
            # Process the pattern
            if [[ "$pattern_buffer" =~ claude\ -p ]]; then
                # Extract the pattern
                pattern=$(echo "$pattern_buffer" | grep -oP "(?<=claude -p ').*?(?=')" | head -1)
                if [ -n "$pattern" ]; then
                    echo -e "\n${CYAN}Processing pattern from line ~$line_num${NC}"
                    migrated=$(migrate_pattern "$pattern")
                    
                    # Write to output file
                    cat >> "$output_file" << EOF

### Example from line ~$line_num

Original:
\`\`\`bash
$pattern_buffer
\`\`\`

Migrated:
\`\`\`bash
$(echo "$pattern_buffer" | sed "s|claude -p '.*'|claude -p '$migrated'|")
\`\`\`

EOF
                fi
            fi
        elif [ "$in_code_block" = true ]; then
            pattern_buffer+="$line"$'\n'
        fi
    done < "$input_file"
    
    echo -e "${GREEN}Migration complete! Output: $output_file${NC}"
}

# Interactive pattern migrator
interactive_migrate() {
    echo -e "${BLUE}=== Interactive Pattern Migrator ===${NC}"
    echo "Enter patterns to migrate (or 'quit' to exit):"
    
    while true; do
        echo -e "\n${YELLOW}Enter pattern:${NC}"
        read -r pattern
        
        [ "$pattern" = "quit" ] && break
        
        migrate_pattern "$pattern"
        
        echo -e "\n${YELLOW}Test the migrated pattern? (y/n)${NC}"
        read -r test_it
        
        if [ "$test_it" = "y" ]; then
            echo "Enter test input:"
            read -r test_input
            echo -e "\n${BLUE}Testing...${NC}"
            result=$(echo "$test_input" | timeout 10 claude -p "$migrated" --output-format json 2>&1 | jq -r '.result' 2>/dev/null || echo "Failed")
            echo -e "${GREEN}Result:${NC} $result"
        fi
    done
}

# Batch migration from patterns
batch_migrate() {
    local patterns_file="$1"
    
    echo -e "${BLUE}=== Batch Migration from $patterns_file ===${NC}"
    
    while IFS= read -r pattern; do
        [ -z "$pattern" ] && continue
        [[ "$pattern" =~ ^# ]] && continue
        
        echo -e "\n${CYAN}---${NC}"
        migrate_pattern "$pattern"
    done < "$patterns_file"
}

# Create example patterns file
create_examples() {
    cat > "example_patterns_to_migrate.txt" << 'EOF'
# Example patterns to migrate
{n:5,big:n>10?"yes":"no"}
{items:[...base,"new"]}
{data:...,next:"analyze"}
{email:...,valid:email.includes("@")}
values.map(v=>v*2)
{if error:{alert:true},else:{proceed:true}}
{type:"user",schema:type=="user"?{name:str}:{}}
arr.filter(x=>x>5)
str.toLowerCase()
{count:3,items:count>0?["a","b","c"]:[]}
EOF
    
    echo "Created example_patterns_to_migrate.txt"
}

# Main menu
show_menu() {
    echo -e "\n${BLUE}=== Claude Pattern Migration Tool ===${NC}"
    echo "1. Migrate single pattern (interactive)"
    echo "2. Migrate patterns from file"
    echo "3. Migrate markdown file"
    echo "4. Create example patterns file"
    echo "5. Show migration rules"
    echo "6. Exit"
    echo -e "${YELLOW}Choose option:${NC}"
}

# Show migration rules
show_rules() {
    echo -e "\n${BLUE}=== Migration Rules ===${NC}"
    for rule in "${!MIGRATION_RULES[@]}"; do
        echo -e "${YELLOW}Pattern:${NC} $rule"
        echo -e "${GREEN}Becomes:${NC} ${MIGRATION_RULES[$rule]}"
        echo
    done
}

# Main script
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -i, --interactive    Interactive mode"
    echo "  -f, --file FILE      Migrate patterns from file"
    echo "  -m, --markdown FILE  Migrate markdown file"
    echo "  -e, --examples       Create example patterns file"
    echo "  -r, --rules          Show migration rules"
    exit 0
fi

# Handle command line arguments
case "$1" in
    -i|--interactive)
        interactive_migrate
        ;;
    -f|--file)
        [ -z "$2" ] && echo "Error: File required" && exit 1
        batch_migrate "$2"
        ;;
    -m|--markdown)
        [ -z "$2" ] && echo "Error: Markdown file required" && exit 1
        migrate_file "$2"
        ;;
    -e|--examples)
        create_examples
        ;;
    -r|--rules)
        show_rules
        ;;
    *)
        # Interactive menu
        while true; do
            show_menu
            read -r choice
            
            case $choice in
                1) interactive_migrate ;;
                2) 
                    echo "Enter patterns file path:"
                    read -r file
                    [ -f "$file" ] && batch_migrate "$file" || echo "File not found"
                    ;;
                3)
                    echo "Enter markdown file path:"
                    read -r file
                    [ -f "$file" ] && migrate_file "$file" || echo "File not found"
                    ;;
                4) create_examples ;;
                5) show_rules ;;
                6) break ;;
                *) echo "Invalid option" ;;
            esac
        done
        ;;
esac

echo -e "\n${GREEN}Migration log saved to: $MIGRATION_LOG${NC}"