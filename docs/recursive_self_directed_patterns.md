# Recursive and Self-Directed Patterns

## Overview

Recursive and self-directed patterns enable Claude to control its own execution flow, make decisions about next steps, and solve complex problems through iterative refinement.

## Basic Self-Directed Workflow

The `next_file` or `next_action` pattern allows Claude to control workflow progression.

```python
prompt = """You are a code reviewer. 
For each file you review, output JSON: 
{
  file_reviewed: "current filename",
  issues_found: ["list", "of", "issues"],  
  next_file: "next file to review or null if done"
}
"""

# Claude might output:
{"file_reviewed": "app.py", "issues_found": ["Missing docstring"], "next_file": "models.py"}
{"file_reviewed": "models.py", "issues_found": [], "next_file": "views.py"}
{"file_reviewed": "views.py", "issues_found": ["Hardcoded URL"], "next_file": null}
```

## Recursive Analysis Pattern

Claude decides when to go deeper vs. when to stop.

```bash
#!/bin/bash
# Recursive root cause analyzer

analyze_recursively() {
    local issue="$1"
    local depth="${2:-0}"
    local max_depth=5
    
    if [ $depth -ge $max_depth ]; then
        echo "Maximum depth reached"
        return
    fi
    
    result=$(echo "$issue" | claude -p "
        Analyze this issue.
        Output JSON: {
            root_cause_found: bool,
            explanation: str,
            deeper_question: str or null,
            confidence: float
        }
    ")
    
    root_cause_found=$(echo "$result" | jq -r '.root_cause_found')
    deeper_question=$(echo "$result" | jq -r '.deeper_question')
    
    echo "Depth $depth: $result"
    
    if [ "$root_cause_found" = "false" ] && [ "$deeper_question" != "null" ]; then
        # Recurse deeper
        analyze_recursively "$deeper_question" $((depth + 1))
    fi
}

# Start analysis
analyze_recursively "Application crashes on startup"
```

## The Root Cause Analyzer Example

Complete implementation showing recursive prompting with termination conditions.

```bash
#!/bin/bash
# Root Cause Analyzer - Recursively drills down to find root causes

find_root_cause() {
    local problem="$1"
    local max_depth=7
    local current_depth=0
    
    echo "🔍 Starting root cause analysis for: $problem"
    echo "================================================"
    
    while [ $current_depth -lt $max_depth ]; do
        # Claude analyzes and decides whether to continue
        analysis=$(echo "$problem" | claude -p "
You are a root cause analyzer. Analyze this problem and determine if we've found the root cause.

Problem: <problem>

Output JSON:
{
  'current_understanding': 'explanation of what we know so far',
  'is_root_cause': boolean (true if this is the fundamental root cause),
  'confidence': 0.0-1.0,
  'reasoning': 'why you think this is/isn't the root cause',
  'next_question': 'deeper question to ask if not root cause, null if done'
}
")
        
        # Parse Claude's response
        is_root=$(echo "$analysis" | jq -r '.is_root_cause')
        confidence=$(echo "$analysis" | jq -r '.confidence')
        understanding=$(echo "$analysis" | jq -r '.current_understanding')
        reasoning=$(echo "$analysis" | jq -r '.reasoning')
        next_question=$(echo "$analysis" | jq -r '.next_question')
        
        echo ""
        echo "🔎 Level $((current_depth + 1)) Analysis:"
        echo "Understanding: $understanding"
        echo "Root cause found: $is_root (confidence: $confidence)"
        echo "Reasoning: $reasoning"
        
        # Check if we've found the root cause
        if [ "$is_root" = "true" ] || [ "$next_question" = "null" ]; then
            echo ""
            echo "✅ ROOT CAUSE IDENTIFIED!"
            echo "========================"
            echo "$understanding"
            break
        fi
        
        # Continue drilling down
        echo "Next question: $next_question"
        echo "---"
        
        problem="$next_question"
        ((current_depth++))
    done
    
    if [ $current_depth -eq $max_depth ]; then
        echo ""
        echo "⚠️  Maximum analysis depth reached"
    fi
}

# Example usage
find_root_cause "The database queries are running slowly"
```

## Interactive Idea Consultant Pattern

Complex recursive refinement with user interaction.

```bash
#!/bin/bash
# Startup Idea Consultant - Recursively refines and challenges ideas

consult_on_idea() {
    local idea="$1"
    local iteration=0
    local max_iterations=10
    
    echo "🚀 Startup Idea Consultant"
    echo "========================="
    echo "Initial idea: $idea"
    echo ""
    
    while [ $iteration -lt $max_iterations ]; do
        # Claude analyzes the idea
        analysis=$(echo "$idea" | claude -p "
You are a startup consultant. Analyze this idea and provide insights.

Idea: <idea>

Output JSON:
{
  'strengths': ['list of strong points'],
  'weaknesses': ['list of weak points'],
  'market_fit': 'assessment of product-market fit',
  'suggestion': 'one specific way to improve the idea',
  'refined_idea': 'the idea incorporating the suggestion',
  'confidence_score': 0.0-1.0,
  'is_ready': boolean (true if idea is solid enough to pursue),
  'pivot_suggestion': 'alternative direction if needed'
}
")
        
        # Parse response
        strengths=$(echo "$analysis" | jq -r '.strengths[]' | sed 's/^/  ✓ /')
        weaknesses=$(echo "$analysis" | jq -r '.weaknesses[]' | sed 's/^/  ✗ /')
        suggestion=$(echo "$analysis" | jq -r '.suggestion')
        refined_idea=$(echo "$analysis" | jq -r '.refined_idea')
        is_ready=$(echo "$analysis" | jq -r '.is_ready')
        confidence=$(echo "$analysis" | jq -r '.confidence_score')
        
        echo "Iteration $((iteration + 1)):"
        echo "-------------"
        echo "Strengths:"
        echo "$strengths"
        echo ""
        echo "Weaknesses:"
        echo "$weaknesses"
        echo ""
        echo "Suggestion: $suggestion"
        echo "Confidence: $confidence"
        echo ""
        
        if [ "$is_ready" = "true" ]; then
            echo "✅ Your idea is ready to pursue!"
            echo "Final refined idea: $refined_idea"
            break
        fi
        
        # Ask user whether to continue
        echo "Refined idea: $refined_idea"
        echo ""
        read -p "Accept refinement? (y/n/quit): " response
        
        case $response in
            y|Y)
                idea="$refined_idea"
                ;;
            n|N)
                read -p "Enter your own refinement: " idea
                ;;
            quit|q)
                break
                ;;
        esac
        
        ((iteration++))
        echo ""
    done
}

# Run the consultant
consult_on_idea "An app for finding nearby coffee shops"
```

## Self-Organizing Task Queue Pattern

Claude manages its own work queue.

```python
class SelfOrganizingQueue:
    def __init__(self):
        self.queue_manager = Claude("""
            Manage task queue intelligently.
            Input: {
                current_queue: [{task: str, priority: int, dependencies: []}],
                completed_tasks: [str],
                system_load: float
            }
            Output JSON: {
                next_task: str or null,
                reorder_queue: bool,
                new_order: [] if reorder_queue,
                spawn_parallel: [str],
                defer_tasks: [str],
                reason: str
            }
        """)
        
        self.task_queue = []
        self.completed = []
    
    async def get_next_task(self):
        decision = await self.queue_manager.process({
            "current_queue": self.task_queue,
            "completed_tasks": self.completed,
            "system_load": self.get_system_load()
        })
        
        if decision['reorder_queue']:
            self.task_queue = decision['new_order']
        
        if decision['spawn_parallel']:
            # Create parallel workers
            for task in decision['spawn_parallel']:
                asyncio.create_task(self.process_task(task))
        
        return decision['next_task']
```

## Multi-Agent Recursive Pattern

Multiple Claude instances recursively creating and coordinating with each other.

```python
class RecursiveMultiAgent:
    def __init__(self):
        self.coordinator = Claude("""
            Coordinate multi-agent problem solving.
            Input: {problem: str, agents_available: [], depth: int}
            Output JSON: {
                strategy: "divide" | "delegate" | "solve" | "escalate",
                if_divide: {
                    subproblems: [{problem: str, assigned_agent: str}]
                },
                if_delegate: {
                    agent_to_create: {role: str, prompt: str}
                },
                if_solve: {
                    solution: str
                },
                if_escalate: {
                    reason: str,
                    needs: str
                }
            }
        """)
        
        self.agents = {}
        self.solutions = {}
    
    async def solve_problem(self, problem, depth=0):
        if depth > 5:  # Max recursion depth
            return {"error": "Max depth reached"}
        
        # Coordinator decides strategy
        strategy = await self.coordinator.process({
            "problem": problem,
            "agents_available": list(self.agents.keys()),
            "depth": depth
        })
        
        if strategy['strategy'] == 'divide':
            # Recursively solve subproblems
            subtasks = []
            for subproblem in strategy['if_divide']['subproblems']:
                subtasks.append(
                    self.solve_problem(subproblem['problem'], depth + 1)
                )
            
            sub_solutions = await asyncio.gather(*subtasks)
            
            # Combine solutions
            combiner = Claude("Combine sub-solutions into cohesive solution")
            return await combiner.process(sub_solutions)
        
        elif strategy['strategy'] == 'delegate':
            # Create new specialized agent
            spec = strategy['if_delegate']['agent_to_create']
            new_agent = Claude(spec['prompt'])
            self.agents[spec['role']] = new_agent
            
            # Recurse with new agent available
            return await self.solve_problem(problem, depth)
        
        elif strategy['strategy'] == 'solve':
            return strategy['if_solve']['solution']
```

## Code Archaeology Pattern

Recursively exploring codebases to understand patterns and history.

```python
class CodeArchaeologist:
    def __init__(self):
        self.explorer = Claude("""
            Explore code artifact and decide what to investigate next.
            Input: {
                current_file: str,
                discovery: str,
                investigated: [],
                goal: str
            }
            Output JSON: {
                insight: str,
                goal_progress: float,
                next_investigations: [{
                    type: "file" | "pattern" | "history",
                    target: str,
                    reason: str
                }],
                done: bool
            }
        """)
    
    async def investigate(self, starting_point, goal):
        investigated = []
        discoveries = []
        
        to_investigate = [{"type": "file", "target": starting_point}]
        
        while to_investigate and len(investigated) < 50:
            current = to_investigate.pop(0)
            
            # Perform investigation based on type
            if current['type'] == 'file':
                discovery = await self.analyze_file(current['target'])
            elif current['type'] == 'pattern':
                discovery = await self.search_pattern(current['target'])
            elif current['type'] == 'history':
                discovery = await self.analyze_history(current['target'])
            
            # Let Claude decide what to do next
            result = await self.explorer.process({
                "current_file": current['target'],
                "discovery": discovery,
                "investigated": investigated,
                "goal": goal
            })
            
            discoveries.append(result['insight'])
            investigated.append(current)
            
            if result['done'] or result['goal_progress'] > 0.9:
                break
            
            # Add new investigations
            to_investigate.extend(result['next_investigations'])
        
        return {
            "discoveries": discoveries,
            "final_insight": await self.synthesize_discoveries(discoveries)
        }
```

## AST-Based Recursive Analysis

Recursively analyzing code structure.

```bash
# AST-based recursive analyzer
analyze_ast() {
    local file="$1"
    local focus="${2:-all}"
    
    # Initial AST extraction
    ast=$(python -m ast_analyzer "$file")
    
    # Recursive analysis
    result=$(echo "$ast" | claude -p "
        Analyze AST node.
        Current focus: $focus
        Output JSON: {
            node_type: str,
            analysis: str,
            interesting_children: [{
                path: str,
                reason: str,
                priority: int
            }],
            continue_depth: bool
        }
    ")
    
    # Process interesting children
    children=$(echo "$result" | jq -r '.interesting_children[]')
    for child in $children; do
        child_path=$(echo "$child" | jq -r '.path')
        analyze_ast "$file" "$child_path"
    done
}
```

## Best Practices for Recursive Patterns

1. **Always set depth limits** - Prevent infinite recursion
2. **Track visited states** - Avoid analyzing the same thing twice
3. **Clear termination conditions** - Claude should know when to stop
4. **Progress tracking** - Monitor advancement toward goals
5. **Resource awareness** - Consider token/API limits in deep recursion
6. **State preservation** - Maintain context across recursive calls
7. **Error boundaries** - Handle failures at each recursion level
8. **Async when possible** - Parallelize independent recursive branches
9. **Result aggregation** - Plan how to combine recursive results
10. **User controls** - Allow interruption of long recursive processes

## Common Pitfalls and Solutions

### Infinite Loops
```python
# Bad: No termination
while True:
    result = claude.process("Analyze deeper")
    
# Good: Clear termination
depth = 0
while depth < MAX_DEPTH and not result['done']:
    result = claude.process(f"Analyze deeper. Depth: {depth}")
    depth += 1
```

### State Explosion
```python
# Bad: Exponential growth
for item in items:
    for subitem in analyze(item):
        for subsubitem in analyze(subitem):  # Explosive growth
            
# Good: Bounded exploration
priority_queue = PriorityQueue(maxsize=100)
while not priority_queue.empty():
    item = priority_queue.get()
    # Process with priority limits
```

### Context Loss
```python
# Bad: Losing context
def recurse(item):
    result = claude.process(item)  # No context
    
# Good: Maintaining context
def recurse(item, context):
    result = claude.process({
        "item": item,
        "context": context,
        "depth": context['depth']
    })
```