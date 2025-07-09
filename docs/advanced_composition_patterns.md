# Advanced Composition Patterns

## Overview

Advanced composition patterns enable sophisticated multi-Claude architectures including state machines, event-driven systems, and complex orchestration patterns.

## State Machine Pattern

Claude instances managing state transitions and spawning workers based on state changes.

```python
class ClaudeStateMachine:
    """Claude instances managing state transitions"""
    
    def __init__(self):
        self.state = "initial"
        self.claude = Claude("""
        You are a state machine controller.
        Current state: {state}
        Input event: {event}
        Output JSON: {
            next_state: str,
            actions: [str],
            output: any,
            spawn_workers: [{prompt: str, input: any}]
        }
        """)
    
    async def transition(self, event):
        result = await self.claude.process({
            "state": self.state,
            "event": event
        })
        
        self.state = result['next_state']
        
        # Spawn any workers Claude requested
        for worker_spec in result.get('spawn_workers', []):
            worker = Claude(worker_spec['prompt'])
            asyncio.create_task(worker.process(worker_spec['input']))
        
        return result
```

### Example: Build System State Machine

```python
class BuildStateMachine:
    STATES = {
        'idle': ['build_requested', 'schedule_requested'],
        'building': ['build_success', 'build_failure', 'cancel'],
        'testing': ['tests_passed', 'tests_failed'],
        'deploying': ['deploy_success', 'deploy_failure'],
        'failed': ['retry', 'investigate']
    }
    
    def __init__(self):
        self.fsm = ClaudeStateMachine()
        self.fsm.claude = Claude(f"""
        Build system state machine.
        Valid transitions: {json.dumps(self.STATES)}
        Current state: {{state}}
        Event: {{event}}
        Output JSON: {{
            next_state: str,
            actions: ["notify", "log", "cleanup", etc],
            spawn_workers: [{{
                prompt: "Worker instructions",
                input: {{relevant: "data"}}
            }}]
        }}
        """)
```

## Event-Driven Architecture Pattern

Claude instances communicating via events in a publish-subscribe model.

```python
class ClaudeEventBus:
    """Claude instances communicating via events"""
    
    def __init__(self):
        self.subscribers = defaultdict(list)
        self.event_queue = asyncio.Queue()
        
    def create_subscriber(self, event_types, prompt):
        claude = Claude(prompt + " Output JSON: {emit_events: [{type: str, data: any}], result: any}")
        
        for event_type in event_types:
            self.subscribers[event_type].append(claude)
        
        return claude
    
    async def emit(self, event_type, data):
        await self.event_queue.put({"type": event_type, "data": data})
    
    async def process_events(self):
        while True:
            event = await self.event_queue.get()
            
            # Fan out to all subscribers
            tasks = []
            for claude in self.subscribers[event['type']]:
                tasks.append(claude.process(event))
            
            results = await asyncio.gather(*tasks)
            
            # Process any new events emitted
            for result in results:
                for new_event in result.get('emit_events', []):
                    await self.emit(new_event['type'], new_event['data'])

# Example: Self-organizing code review system
bus = ClaudeEventBus()

bus.create_subscriber(['code_changed'], """
    When code changes, decide what to review.
    Input: {type: 'code_changed', data: {file: str, diff: str}}
""")

bus.create_subscriber(['review_needed'], """
    Perform code review.
    Input: {type: 'review_needed', data: {file: str, focus: str}}
""")

bus.create_subscriber(['issue_found'], """
    Decide how to fix issue.
    Input: {type: 'issue_found', data: {issue: str, severity: str}}
""")
```

### Bash Event Bus Implementation

```bash
#!/bin/bash
# Simple event bus using named pipes

EVENT_DIR="/tmp/claude_events"
mkdir -p "$EVENT_DIR"

# Create event subscriber
create_subscriber() {
    local event_type=$1
    local handler_prompt=$2
    local pipe="$EVENT_DIR/${event_type}_pipe"
    
    mkfifo "$pipe" 2>/dev/null || true
    
    # Run subscriber in background
    while true; do
        if read -r event_data < "$pipe"; then
            # Process event and emit new events
            result=$(echo "$event_data" | claude -p "$handler_prompt")
            
            # Extract and emit new events
            echo "$result" | jq -r '.emit_events[]? | "\(.type)|\(.data)"' | \
            while IFS='|' read -r new_type new_data; do
                emit_event "$new_type" "$new_data"
            done
        fi
    done &
}

# Emit event
emit_event() {
    local event_type=$1
    local event_data=$2
    local pipe="$EVENT_DIR/${event_type}_pipe"
    
    if [ -p "$pipe" ]; then
        echo "$event_data" > "$pipe"
    fi
}

# Example usage
create_subscriber "file_changed" "Analyze file change and decide actions"
create_subscriber "test_needed" "Generate appropriate tests"
create_subscriber "deploy_ready" "Prepare deployment configuration"
```

## Actor Model Pattern

Claude instances as independent actors with message passing.

```python
class ClaudeActor:
    def __init__(self, name, prompt):
        self.name = name
        self.mailbox = asyncio.Queue()
        self.prompt = prompt
        self.claude = Claude(f"""
        You are actor '{name}'.
        {prompt}
        For each message, output JSON: {{
            response: any,
            send_to: [{{actor: str, message: any}}]
        }}
        """)
    
    async def send(self, message):
        await self.mailbox.put(message)
    
    async def run(self, actor_system):
        while True:
            message = await self.mailbox.get()
            result = await self.claude.process(message)
            
            # Send messages to other actors
            for msg in result.get('send_to', []):
                target = actor_system.get_actor(msg['actor'])
                if target:
                    await target.send(msg['message'])

class ActorSystem:
    def __init__(self):
        self.actors = {}
    
    def create_actor(self, name, prompt):
        actor = ClaudeActor(name, prompt)
        self.actors[name] = actor
        asyncio.create_task(actor.run(self))
        return actor
    
    def get_actor(self, name):
        return self.actors.get(name)

# Example: Microservices simulation
system = ActorSystem()

system.create_actor("api_gateway", """
    Route requests to appropriate services.
    Forward responses back to clients.
""")

system.create_actor("auth_service", """
    Validate tokens and permissions.
    Cache auth decisions.
""")

system.create_actor("data_service", """
    Handle CRUD operations.
    Validate data integrity.
""")
```

## Saga Pattern

Distributed transaction coordination with compensation.

```python
class ClaudeSaga:
    """Coordinate distributed transactions with compensation"""
    
    def __init__(self):
        self.coordinator = Claude("""
        Coordinate multi-step transaction.
        Input: {steps_completed: [], current_step: str, error: str}
        Output JSON: {
            next_action: "continue" | "compensate" | "retry" | "abort",
            next_step: str,
            compensation_steps: []
        }
        """)
        
        self.steps = {}
        self.compensations = {}
    
    def define_step(self, name, forward_prompt, compensation_prompt):
        self.steps[name] = Claude(forward_prompt)
        self.compensations[name] = Claude(compensation_prompt)
    
    async def execute(self, initial_data):
        completed_steps = []
        current_data = initial_data
        
        try:
            for step_name, step_claude in self.steps.items():
                result = await step_claude.process(current_data)
                completed_steps.append({
                    "step": step_name,
                    "result": result
                })
                current_data = result
                
        except Exception as e:
            # Coordinate compensation
            decision = await self.coordinator.process({
                "steps_completed": completed_steps,
                "current_step": step_name,
                "error": str(e)
            })
            
            if decision['next_action'] == 'compensate':
                await self._compensate(completed_steps, decision['compensation_steps'])
            
            raise

# Example: Order processing saga
saga = ClaudeSaga()

saga.define_step("validate_order",
    forward_prompt="Validate order details. Output JSON: {valid: bool, order_id: str}",
    compensation_prompt="Cancel order validation. Mark order as invalid."
)

saga.define_step("reserve_inventory",
    forward_prompt="Reserve items. Output JSON: {reserved: bool, reservation_id: str}",
    compensation_prompt="Release inventory reservation."
)

saga.define_step("charge_payment",
    forward_prompt="Process payment. Output JSON: {charged: bool, transaction_id: str}",
    compensation_prompt="Refund payment."
)
```

## Hierarchical Task Network Pattern

Breaking down complex tasks into subtasks hierarchically.

```python
class ClaudeHTN:
    """Hierarchical Task Network planner"""
    
    def __init__(self):
        self.planner = Claude("""
        Break down task hierarchically.
        Input: {task: str, context: obj}
        Output JSON: {
            subtasks: [{
                name: str,
                type: "primitive" | "compound",
                dependencies: [str],
                estimated_complexity: int
            }],
            execution_order: [str]
        }
        """)
        
        self.executor = Claude("""
        Execute primitive task.
        Input: {task: str, context: obj}
        Output JSON: {result: any, side_effects: []}
        """)
    
    async def solve(self, task, context={}):
        plan = await self.planner.process({
            "task": task,
            "context": context
        })
        
        results = {}
        
        for task_name in plan['execution_order']:
            task_def = next(t for t in plan['subtasks'] if t['name'] == task_name)
            
            if task_def['type'] == 'primitive':
                # Execute directly
                results[task_name] = await self.executor.process({
                    "task": task_name,
                    "context": {**context, **results}
                })
            else:
                # Recursive decomposition
                results[task_name] = await self.solve(task_name, {**context, **results})
        
        return results
```

## Blackboard Pattern

Shared knowledge space with specialized expert Claudes.

```python
class ClaudeBlackboard:
    """Multiple experts collaborating via shared blackboard"""
    
    def __init__(self):
        self.blackboard = {
            "problem": None,
            "hypotheses": [],
            "evidence": [],
            "solution": None
        }
        self.experts = []
    
    def add_expert(self, name, expertise, prompt):
        expert = Claude(f"""
        You are a {expertise} expert named {name}.
        {prompt}
        Examine blackboard state and contribute.
        Output JSON: {{
            contribution_type: "hypothesis" | "evidence" | "refinement" | "solution",
            contribution: any,
            confidence: float,
            triggers_expert: str  # Name another expert who should look
        }}
        """)
        self.experts.append({
            "name": name,
            "expertise": expertise,
            "claude": expert
        })
    
    async def solve(self, problem):
        self.blackboard["problem"] = problem
        iterations = 0
        max_iterations = 20
        
        while self.blackboard["solution"] is None and iterations < max_iterations:
            # Each expert examines the blackboard
            for expert in self.experts:
                result = await expert["claude"].process(self.blackboard)
                
                # Update blackboard based on contribution
                if result["contribution_type"] == "hypothesis":
                    self.blackboard["hypotheses"].append({
                        "expert": expert["name"],
                        "hypothesis": result["contribution"],
                        "confidence": result["confidence"]
                    })
                elif result["contribution_type"] == "solution":
                    self.blackboard["solution"] = result["contribution"]
                    break
                
                # Trigger specific expert if requested
                if result.get("triggers_expert"):
                    # Move triggered expert to front of queue
                    triggered = next((e for e in self.experts 
                                    if e["name"] == result["triggers_expert"]), None)
                    if triggered:
                        self.experts.remove(triggered)
                        self.experts.insert(0, triggered)
            
            iterations += 1
        
        return self.blackboard["solution"]

# Example: Debugging system
debugger = ClaudeBlackboard()

debugger.add_expert("symptom_analyzer", "error patterns",
    "Identify symptoms and patterns in the error.")

debugger.add_expert("code_archaeologist", "code history",
    "Find when the issue was introduced.")

debugger.add_expert("solution_architect", "fixes",
    "Propose and validate solutions.")
```

## Orchestra Conductor Pattern

Central coordinator managing specialized Claude instances.

```python
class ClaudeOrchestra:
    """Central conductor coordinating specialized musicians (Claudes)"""
    
    def __init__(self):
        self.conductor = Claude("""
        You are an orchestra conductor coordinating specialists.
        Input: {task: str, available_specialists: [str], context: obj}
        Output JSON: {
            execution_plan: [{
                specialist: str,
                instruction: str,
                depends_on: [str],
                parallel_ok: bool
            }],
            success_criteria: str
        }
        """)
        
        self.specialists = {}
    
    def add_specialist(self, name, capability):
        self.specialists[name] = Claude(f"""
        You are a specialist in {capability}.
        Follow instructions precisely.
        Output JSON: {{result: any, quality: float, notes: str}}
        """)
    
    async def perform(self, task, context={}):
        # Conductor creates execution plan
        plan = await self.conductor.process({
            "task": task,
            "available_specialists": list(self.specialists.keys()),
            "context": context
        })
        
        results = {}
        
        # Execute plan
        for step in plan['execution_plan']:
            # Wait for dependencies
            while not all(dep in results for dep in step['depends_on']):
                await asyncio.sleep(0.1)
            
            specialist = self.specialists[step['specialist']]
            result = await specialist.process({
                "instruction": step['instruction'],
                "context": context,
                "prior_results": {k: results[k] for k in step['depends_on']}
            })
            
            results[step['specialist']] = result
        
        return results
```

## Best Practices

1. **Clear communication protocols** - Define JSON schemas for inter-Claude communication
2. **Error handling at every level** - Distributed systems fail in complex ways
3. **Idempotent operations** - Allow safe retries
4. **Monitoring and observability** - Track the health of your Claude network
5. **Graceful degradation** - System should handle individual Claude failures
6. **Version your prompts** - Treat prompts as code with proper versioning
7. **Test compositions** - Unit test individual Claudes, integration test compositions
8. **Document interaction patterns** - Make it clear how Claudes communicate
9. **Set timeouts** - Prevent hanging on unresponsive Claudes
10. **Use circuit breakers** - Prevent cascade failures in Claude networks