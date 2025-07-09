# Control Flow and Utility Patterns

## Overview

Control flow patterns manage execution paths, error handling, and resource management in Claude-based systems.

## Conditional Execution Pattern

Claude decides which execution paths to take.

```python
# Claude decides which other Claudes to run
orchestrator_prompt = """
Analyze task and decide execution path.
Input: {task: str, context: obj}
Output JSON: {
    strategy: 'simple'|'complex'|'recursive',
    if_simple: {claude_prompt: str},
    if_complex: {claude_prompts: [str], execution_order: 'parallel'|'sequential'},
    if_recursive: {base_prompt: str, recursion_prompt: str, max_depth: int}
}
"""
```

### Bash Implementation

```bash
# Conditional execution based on Claude's decision
analyze_file() {
    local file=$1
    
    # Claude decides complexity
    complexity=$(claude -p "Assess file complexity. Output JSON: {level: 'simple'|'complex'}" < "$file" | jq -r .level)
    
    case $complexity in
        "simple")
            claude -p "Quick analysis" < "$file"
            ;;
        "complex")
            # Parallel deep analysis
            {
                claude -p "Security scan" < "$file" > security.json &
                claude -p "Performance analysis" < "$file" > perf.json &
                claude -p "Code quality check" < "$file" > quality.json &
                wait
            }
            # Merge results
            claude -p "Merge analyses" security.json perf.json quality.json
            ;;
    esac
}
```

## Circuit Breaker Pattern

Prevent cascade failures in Claude networks.

```python
class ClaudeCircuitBreaker:
    """Prevent cascade failures in Claude networks"""
    
    def __init__(self, failure_threshold=3):
        self.failure_threshold = failure_threshold
        self.failure_counts = defaultdict(int)
        self.circuit_state = defaultdict(lambda: 'closed')
        
        self.monitor = Claude("""
            Monitor failures and decide circuit state.
            Input: {failures: int, recent_errors: []}
            Output JSON: {
                should_open_circuit: bool,
                retry_after_seconds: int,
                fallback_prompt: str
            }
        """)
    
    async def call_claude(self, prompt, input_data):
        circuit_key = hash(prompt)
        
        if self.circuit_state[circuit_key] == 'open':
            # Use fallback
            fallback = await self.get_fallback(prompt)
            return await Claude(fallback).process(input_data)
        
        try:
            result = await Claude(prompt).process(input_data)
            self.failure_counts[circuit_key] = 0  # Reset on success
            return result
            
        except Exception as e:
            self.failure_counts[circuit_key] += 1
            
            if self.failure_counts[circuit_key] >= self.failure_threshold:
                # Ask monitor Claude about opening circuit
                decision = await self.monitor.process({
                    "failures": self.failure_counts[circuit_key],
                    "recent_errors": self.get_recent_errors(circuit_key)
                })
                
                if decision['should_open_circuit']:
                    self.circuit_state[circuit_key] = 'open'
                    # Schedule circuit close
                    asyncio.create_task(
                        self.close_circuit_after(circuit_key, decision['retry_after_seconds'])
                    )
            
            raise
```

## Rate Limiting Pattern

Intelligent rate limiting with Claude decisions.

```python
class ClaudeRateLimiter:
    """Intelligent rate limiting with Claude decisions"""
    
    def __init__(self):
        self.limiter = Claude("""
            Decide on rate limiting.
            Input: {current_load: float, queue_size: int, priority: str}
            Output JSON: {
                allow: bool,
                delay_ms: int,
                reason: str,
                suggest_batch: bool
            }
        """)
        
        self.load_metrics = {
            'requests_per_second': 0,
            'queue_size': 0,
            'avg_response_time': 0
        }
    
    async def should_allow(self, request_priority='normal'):
        decision = await self.limiter.process({
            "current_load": self.load_metrics['requests_per_second'],
            "queue_size": self.load_metrics['queue_size'],
            "priority": request_priority
        })
        
        if decision['allow']:
            if decision['delay_ms'] > 0:
                await asyncio.sleep(decision['delay_ms'] / 1000)
            return True
        
        return False
```

## Error Recovery Pattern

Sophisticated error handling with Claude-guided recovery.

```python
async def resilient_claude_call(prompt, input_data, max_retries=3):
    for attempt in range(max_retries):
        try:
            return await Claude(prompt).process(input_data)
        except json.JSONDecodeError:
            # Claude didn't output valid JSON, refine prompt
            prompt = f"{prompt}\nIMPORTANT: Output ONLY valid JSON"
        except Exception as e:
            # Let Claude debug itself
            debugger = Claude("Fix this error. Output JSON: {fixed_prompt: str}")
            result = await debugger.process({"error": str(e), "prompt": prompt})
            prompt = result['fixed_prompt']
```

### Advanced Error Recovery

```python
class SmartErrorRecovery:
    def __init__(self):
        self.error_analyst = Claude("""
            Analyze error and suggest recovery strategy.
            Input: {error: str, context: obj, attempts: int}
            Output JSON: {
                error_type: str,
                recovery_strategy: "retry" | "fallback" | "escalate" | "abort",
                modifications: {
                    prompt_changes: str,
                    input_transforms: str,
                    alternative_approach: str
                }
            }
        """)
    
    async def execute_with_recovery(self, claude_prompt, input_data):
        attempts = 0
        last_error = None
        
        while attempts < 5:
            try:
                return await Claude(claude_prompt).process(input_data)
                
            except Exception as e:
                last_error = e
                attempts += 1
                
                # Get recovery strategy
                strategy = await self.error_analyst.process({
                    "error": str(e),
                    "context": {"prompt": claude_prompt, "input": input_data},
                    "attempts": attempts
                })
                
                if strategy['recovery_strategy'] == 'retry':
                    await asyncio.sleep(2 ** attempts)  # Exponential backoff
                    
                elif strategy['recovery_strategy'] == 'fallback':
                    claude_prompt = strategy['modifications']['alternative_approach']
                    
                elif strategy['recovery_strategy'] == 'escalate':
                    # Notify human or higher-level system
                    raise EscalationRequired(str(e))
                    
                elif strategy['recovery_strategy'] == 'abort':
                    raise last_error
```

## Resource Management Patterns

### Connection Pooling

```python
class ClaudePool:
    """Manage a pool of Claude instances"""
    
    def __init__(self, size=10):
        self.pool = asyncio.Queue(maxsize=size)
        self.pool_manager = Claude("""
            Manage Claude instance pool.
            Input: {active: int, waiting: int, avg_wait_time: float}
            Output JSON: {
                action: "expand" | "shrink" | "maintain",
                target_size: int,
                priority_adjustments: obj
            }
        """)
        
        # Initialize pool
        for _ in range(size):
            self.pool.put_nowait(self._create_claude())
    
    async def acquire(self, priority='normal'):
        # Get instance from pool
        claude = await self.pool.get()
        return claude
    
    async def release(self, claude):
        # Return instance to pool
        await self.pool.put(claude)
    
    @contextlib.asynccontextmanager
    async def get_claude(self, priority='normal'):
        claude = await self.acquire(priority)
        try:
            yield claude
        finally:
            await self.release(claude)
```

## Monitoring and Observability Patterns

### Performance Monitoring

```python
class ClaudeMetricsCollector:
    """Claude instances that understand their own performance"""
    
    def __init__(self):
        self.monitor = Claude("""
            Analyze execution metrics.
            Input: {execution_time: float, tokens_used: int, error_rate: float}
            Output JSON: {
                performance_rating: 'good'|'degraded'|'poor',
                bottleneck: str,
                optimization_suggestions: []
            }
        """)
        
        self.metrics = defaultdict(list)
    
    async def track_execution(self, claude_name, func):
        start_time = time.time()
        tokens_before = get_token_count()
        
        try:
            result = await func()
            success = True
        except Exception as e:
            success = False
            result = None
        
        execution_time = time.time() - start_time
        tokens_used = get_token_count() - tokens_before
        
        self.metrics[claude_name].append({
            'execution_time': execution_time,
            'tokens_used': tokens_used,
            'success': success,
            'timestamp': time.time()
        })
        
        # Periodic analysis
        if len(self.metrics[claude_name]) % 100 == 0:
            await self.analyze_performance(claude_name)
        
        if not success:
            raise
        return result
```

### Distributed Tracing

```python
class ClaudeTracer:
    """Trace execution through Claude networks"""
    
    def __init__(self):
        self.trace_analyzer = Claude("""
            Analyze distributed trace.
            Input: {spans: [{claude_id: str, duration_ms: float, parent_id: str}]}
            Output JSON: {
                critical_path: [str],
                bottlenecks: [str],
                parallelization_opportunities: []
            }
        """)
        
        self.current_traces = {}
    
    @contextlib.contextmanager
    def trace_span(self, claude_id, parent_id=None):
        trace_id = str(uuid.uuid4())
        span = {
            'claude_id': claude_id,
            'parent_id': parent_id,
            'start_time': time.time(),
            'trace_id': trace_id
        }
        
        self.current_traces[trace_id] = span
        
        try:
            yield trace_id
        finally:
            span['end_time'] = time.time()
            span['duration_ms'] = (span['end_time'] - span['start_time']) * 1000
```

## Caching Patterns

### Intelligent Cache Management

```python
class ClaudeCache:
    def __init__(self):
        self.cache = {}
        self.cache_manager = Claude("""
            Decide caching strategy.
            Input: {query: str, frequency: int, last_used: float, size: int}
            Output JSON: {
                should_cache: bool,
                ttl_seconds: int,
                cache_key_transform: str
            }
        """)
    
    async def get_or_compute(self, prompt, input_data):
        cache_key = self._compute_key(prompt, input_data)
        
        # Check cache
        if cache_key in self.cache:
            entry = self.cache[cache_key]
            if time.time() < entry['expires']:
                return entry['value']
        
        # Compute result
        result = await Claude(prompt).process(input_data)
        
        # Decide whether to cache
        cache_decision = await self.cache_manager.process({
            "query": prompt,
            "frequency": self._get_query_frequency(prompt),
            "last_used": time.time(),
            "size": len(json.dumps(result))
        })
        
        if cache_decision['should_cache']:
            self.cache[cache_key] = {
                'value': result,
                'expires': time.time() + cache_decision['ttl_seconds']
            }
        
        return result
```

## Batch Processing Patterns

### Dynamic Batching

```python
class DynamicBatcher:
    def __init__(self):
        self.batch_optimizer = Claude("""
            Optimize batch size based on metrics.
            Input: {current_size: int, processing_time: float, error_rate: float}
            Output JSON: {
                optimal_size: int,
                reason: str
            }
        """)
        
        self.current_batch_size = 10
        self.pending_items = []
    
    async def add_item(self, item):
        self.pending_items.append(item)
        
        if len(self.pending_items) >= self.current_batch_size:
            await self.process_batch()
    
    async def process_batch(self):
        batch = self.pending_items[:self.current_batch_size]
        self.pending_items = self.pending_items[self.current_batch_size:]
        
        start_time = time.time()
        errors = 0
        
        try:
            # Process batch
            results = await Claude("Process batch").process(batch)
        except:
            errors += 1
        
        # Optimize batch size
        optimization = await self.batch_optimizer.process({
            "current_size": self.current_batch_size,
            "processing_time": time.time() - start_time,
            "error_rate": errors / len(batch)
        })
        
        self.current_batch_size = optimization['optimal_size']
```

## Best Practices

1. **Fail fast, recover smart** - Quick failure detection with intelligent recovery
2. **Monitor everything** - Track performance, errors, and resource usage
3. **Cache intelligently** - Let Claude decide what's worth caching
4. **Batch when beneficial** - Dynamic batching based on system load
5. **Circuit breakers everywhere** - Prevent cascade failures
6. **Rate limit gracefully** - Priority-based rate limiting
7. **Trace execution paths** - Understand bottlenecks in Claude networks
8. **Resource pools** - Manage Claude instances efficiently
9. **Timeout everything** - Never wait forever
10. **Document failure modes** - Clear documentation of how systems fail and recover