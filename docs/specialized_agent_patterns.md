# Specialized Agent Patterns

## Overview

Specialized agent patterns create Claude instances with specific roles and behaviors, enabling sophisticated multi-agent systems for complex tasks.

## Conversational Agent Pattern

Multi-Claude conversations with specialized roles and managed context.

```python
class ClaudeConversationManager:
    """Multi-Claude conversation with specialized roles"""
    
    def __init__(self):
        self.agents = {
            'researcher': Claude("""
                You research information.
                Output JSON: {findings: [], questions_for_user: [], next_agent: str}
            """),
            'analyzer': Claude("""
                You analyze research.
                Output JSON: {analysis: str, confidence: float, next_agent: str}
            """),
            'critic': Claude("""
                You critique analysis.
                Output JSON: {critiques: [], suggestions: [], next_agent: str}
            """)
        }
        self.history = []
    
    async def process_query(self, query):
        current_agent = 'researcher'
        context = {"query": query, "history": self.history}
        
        while current_agent:
            result = await self.agents[current_agent].process(context)
            self.history.append({"agent": current_agent, "output": result})
            
            context['last_result'] = result
            current_agent = result.get('next_agent')
        
        return self.history[-1]['output']
```

### Example: Technical Discussion System

```python
class TechnicalDiscussion:
    def __init__(self):
        self.moderator = Claude("""
            You moderate technical discussions.
            Decide who should speak next based on the conversation.
            Output JSON: {
                summary: str,
                next_speaker: "architect" | "developer" | "tester" | "user" | null,
                discussion_phase: "exploring" | "designing" | "concluding"
            }
        """)
        
        self.participants = {
            'architect': Claude("You focus on system design and patterns."),
            'developer': Claude("You focus on implementation details."),
            'tester': Claude("You focus on edge cases and testing."),
            'user': Claude("You represent end-user perspectives.")
        }
```

## Self-Healing System Pattern

Claude instances that detect and fix issues autonomously.

```python
class ClaudeSelfHealer:
    """Claude instances that detect and fix issues"""
    
    def __init__(self):
        self.monitor = Claude("""
            Monitor system health.
            Output JSON: {
                status: 'healthy'|'degraded'|'failing',
                issues: [{component: str, error: str}],
                suggested_fix: str
            }
        """)
        
        self.fixer = Claude("""
            Fix system issues.
            Input: {issue: str, suggested_fix: str}
            Output JSON: {
                action_taken: str,
                success: bool,
                rollback_command: str
            }
        """)
    
    async def health_check_loop(self):
        while True:
            health = await self.monitor.process(get_system_metrics())
            
            if health['status'] != 'healthy':
                for issue in health['issues']:
                    fix_result = await self.fixer.process(issue)
                    
                    if not fix_result['success']:
                        # Spawn Claude to figure out why fix failed
                        debugger = Claude("Debug failed fix. Output JSON: {root_cause: str, alternative_fix: str}")
                        debug_info = await debugger.process({
                            "issue": issue,
                            "failed_fix": fix_result
                        })
            
            await asyncio.sleep(60)
```

### Example: Database Connection Pool Manager

```python
class ConnectionPoolHealer:
    def __init__(self):
        self.health_checker = Claude("""
            Analyze connection pool metrics.
            Input: {active: int, idle: int, waiting: int, errors: []}
            Output JSON: {
                health: "good" | "stressed" | "critical",
                issues: [],
                recommended_actions: []
            }
        """)
        
        self.healer = Claude("""
            Fix connection pool issues.
            Input: {issue: str, metrics: obj}
            Output JSON: {
                action: "increase_pool" | "kill_idle" | "reset_connections",
                parameters: obj,
                expected_improvement: str
            }
        """)
```

## Code Generation Pipeline Pattern

Multi-stage code generation with validation and refinement.

```python
class ClaudeCodeGenerator:
    """Multi-stage code generation with validation"""
    
    STAGES = {
        'architect': """
            Design system architecture.
            Input: {requirements: str}
            Output JSON: {
                components: [{name: str, responsibility: str, interfaces: []}],
                data_flow: [{from: str, to: str, data_type: str}]
            }
        """,
        
        'coder': """
            Generate code for component.
            Input: {component: obj, architecture: obj}
            Output JSON: {
                filename: str,
                code: str,
                tests_needed: [str],
                dependencies: [str]
            }
        """,
        
        'tester': """
            Generate tests.
            Input: {code: str, test_spec: str}
            Output JSON: {
                test_code: str,
                coverage_estimate: float,
                edge_cases: [str]
            }
        """,
        
        'reviewer': """
            Review generated code.
            Input: {code: str, tests: str}
            Output JSON: {
                approved: bool,
                issues: [{severity: str, description: str, fix: str}],
                suggestions: [str]
            }
        """
    }
    
    async def generate_system(self, requirements):
        # Stage 1: Architecture
        architect = Claude(self.STAGES['architect'])
        architecture = await architect.process({"requirements": requirements})
        
        # Stage 2: Parallel code generation
        code_tasks = []
        for component in architecture['components']:
            coder = Claude(self.STAGES['coder'])
            code_tasks.append(coder.process({
                "component": component,
                "architecture": architecture
            }))
        
        code_results = await asyncio.gather(*code_tasks)
        
        # Stage 3: Test generation
        test_tasks = []
        for code_result in code_results:
            for test_spec in code_result['tests_needed']:
                tester = Claude(self.STAGES['tester'])
                test_tasks.append(tester.process({
                    "code": code_result['code'],
                    "test_spec": test_spec
                }))
        
        test_results = await asyncio.gather(*test_tasks)
        
        # Stage 4: Review
        reviewer = Claude(self.STAGES['reviewer'])
        review = await reviewer.process({
            "code": [r['code'] for r in code_results],
            "tests": [r['test_code'] for r in test_results]
        })
        
        return {
            "architecture": architecture,
            "code": code_results,
            "tests": test_results,
            "review": review
        }
```

## Documentation Generation System

Automated documentation with multiple specialized writers.

```python
class ClaudeDocumentor:
    """Self-documenting codebase"""
    
    def __init__(self):
        self.analyzers = {
            'api_docs': Claude("""
                Document APIs.
                Input: {code: str, type: "rest" | "graphql" | "rpc"}
                Output JSON: {
                    endpoint: str,
                    description: str,
                    parameters: [{name: str, type: str, required: bool}],
                    responses: [{code: int, description: str, schema: obj}],
                    examples: [{title: str, request: str, response: str}]
                }
            """),
            
            'architecture_docs': Claude("""
                Document system architecture.
                Input: {components: [], interactions: []}
                Output JSON: {
                    overview: str,
                    components: [{name: str, purpose: str, details: str}],
                    diagrams: [{type: "sequence" | "component" | "flow", description: str, mermaid: str}]
                }
            """),
            
            'tutorial_writer': Claude("""
                Write tutorials.
                Input: {topic: str, target_audience: str, code_examples: []}
                Output JSON: {
                    title: str,
                    prerequisites: [],
                    steps: [{title: str, explanation: str, code: str, notes: []}],
                    troubleshooting: [{issue: str, solution: str}]
                }
            """),
            
            'readme_generator': Claude("""
                Generate README files.
                Input: {project_info: obj, features: [], setup: str}
                Output JSON: {
                    badges: [],
                    description: str,
                    features: [{title: str, description: str}],
                    installation: str,
                    usage: str,
                    contributing: str
                }
            """)
        }
```

## Refactoring Assistant Pattern

Intelligent code refactoring with multiple specialized agents.

```python
class RefactoringAssistant:
    def __init__(self):
        self.smell_detector = Claude("""
            Detect code smells.
            Output JSON: {
                smells: [{
                    type: "long_method" | "duplicate_code" | "large_class" | etc,
                    location: str,
                    severity: "low" | "medium" | "high",
                    description: str
                }]
            }
        """)
        
        self.refactorer = Claude("""
            Propose refactoring.
            Input: {smell: obj, code: str}
            Output JSON: {
                technique: str,
                before: str,
                after: str,
                benefits: [],
                risks: []
            }
        """)
        
        self.validator = Claude("""
            Validate refactoring maintains behavior.
            Input: {original: str, refactored: str}
            Output JSON: {
                behavior_preserved: bool,
                semantic_changes: [],
                suggested_tests: []
            }
        """)
```

## Learning System Pattern

Claude instances that improve over time.

```python
class AdaptiveClaude:
    """Claude that improves its own prompts"""
    
    def __init__(self):
        self.prompt_version = 1
        self.current_prompt = "Initial prompt"
        self.performance_history = []
        
        self.prompt_optimizer = Claude("""
            Improve prompt based on results.
            Input: {
                current_prompt: str,
                results: [{input: str, output: str, success: bool}],
                success_rate: float
            }
            Output JSON: {
                improved_prompt: str,
                changes: [],
                expected_improvement: float
            }
        """)
        
        self.meta_evaluator = Claude("""
            Evaluate if the system is actually improving.
            Input: {performance_history: [], current_metrics: obj}
            Output JSON: {
                is_improving: bool,
                bottlenecks: [],
                recommendations: []
            }
        """)
    
    async def process_with_learning(self, input_data):
        # Use current prompt
        result = await Claude(self.current_prompt).process(input_data)
        
        # Track performance
        success = self.evaluate_result(result)
        self.performance_history.append({
            "version": self.prompt_version,
            "success": success
        })
        
        # Periodically optimize
        if len(self.performance_history) % 10 == 0:
            await self.optimize_prompt()
        
        return result
    
    async def optimize_prompt(self):
        recent_results = self.performance_history[-10:]
        success_rate = sum(r["success"] for r in recent_results) / len(recent_results)
        
        improvement = await self.prompt_optimizer.process({
            "current_prompt": self.current_prompt,
            "results": recent_results,
            "success_rate": success_rate
        })
        
        self.current_prompt = improvement["improved_prompt"]
        self.prompt_version += 1
```

## Debugging Assistant Pattern

Multi-agent debugging system.

```python
class ClaudeDebugger:
    """Interactive debugging with Claude"""
    
    def __init__(self):
        self.claude = Claude("""
            You are a debugger assistant.
            Input: {error: str, context: obj, stack_trace: str}
            Output JSON: {
                likely_cause: str,
                fix_suggestions: [str],
                debug_commands: [str],
                need_more_info: bool,
                info_needed: [str]
            }
        """)
        
        self.specialized_debuggers = {
            'memory': Claude("Analyze memory issues. Find leaks and optimize usage."),
            'performance': Claude("Analyze performance bottlenecks."),
            'concurrency': Claude("Debug race conditions and deadlocks."),
            'network': Claude("Debug network and API issues.")
        }
    
    async def debug_exception(self, exc_info):
        result = await self.claude.process({
            "error": str(exc_info[1]),
            "context": get_locals_from_traceback(exc_info[2]),
            "stack_trace": format_traceback(exc_info)
        })
        
        if result['need_more_info']:
            # Spawn specialized debuggers
            for info in result['info_needed']:
                if info in self.specialized_debuggers:
                    specialist = self.specialized_debuggers[info]
                    specialized_analysis = await specialist.process(exc_info)
                    # Merge results...
        
        return result
```

## Best Practices for Specialized Agents

1. **Clear role definition** - Each agent should have a well-defined purpose
2. **Structured communication** - Use JSON schemas for inter-agent messages
3. **Specialization over generalization** - Many focused agents > few general ones
4. **Graceful handoffs** - Agents should clearly indicate when to involve others
5. **Context preservation** - Maintain conversation history and state
6. **Performance monitoring** - Track each agent's effectiveness
7. **Fallback strategies** - Handle cases where specialized agents fail
8. **Testing in isolation** - Each agent should be independently testable
9. **Documentation** - Document each agent's capabilities and limitations
10. **Evolution strategies** - Plan for how agents will improve over time