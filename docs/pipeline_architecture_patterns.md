# Pipeline Architecture Patterns

## Overview

Pipeline architectures enable complex workflows by chaining Claude instances together, where each stage transforms data for the next. This pattern is powerful for breaking down complex tasks into manageable, specialized components.

## Linear Pipeline Pattern

Each stage transforms the previous output in sequence.

```python
class ClaudePipeline:
    """Each stage transforms the previous output"""
    
    STAGES = [
        "Extract code blocks. Output JSON: {code: str, language: str, purpose: str}",
        "Analyze complexity. Input: {code}. Output JSON: {complexity: int, hotspots: []}",
        "Generate tests. Input: {code, complexity}. Output JSON: {tests: [str], coverage: float}",
        "Create docs. Input: {code, tests}. Output JSON: {docstring: str, examples: []}"
    ]
    
    async def process(self, input_file):
        data = {"code": open(input_file).read()}
        
        for prompt in self.STAGES:
            proc = await asyncio.create_subprocess_exec(
                'claude', '-p', prompt,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE
            )
            
            stdout, _ = await proc.communicate(json.dumps(data).encode())
            data = json.loads(stdout.decode())
            
        return data
```

### Bash Implementation

```bash
# Linear pipeline with explicit stages
cat input.py | \
claude -p "Extract functions. Output JSON: {functions: [{name: str, code: str}]}" | \
claude -p "Analyze each function. Output JSON: {functions: [{name: str, complexity: int}]}" | \
claude -p "Generate test cases. Output JSON: {tests: [{function: str, test_code: str}]}" | \
claude -p "Create documentation. Output JSON: {docs: [{function: str, docstring: str}]}" \
> output.json
```

## Fan-out/Fan-in Pattern

Parallel analysis with result aggregation.

```python
class ClaudeFanOut:
    ANALYZERS = {
        'security': "Find security issues. Output JSON: {vulnerabilities: [{severity: str, description: str}]}",
        'performance': "Find performance issues. Output JSON: {bottlenecks: [{impact: str, location: str}]}",
        'style': "Find style issues. Output JSON: {violations: [{rule: str, line: int}]}",
        'bugs': "Find potential bugs. Output JSON: {bugs: [{type: str, confidence: float}]}"
    }
    
    async def analyze(self, code):
        tasks = []
        for name, prompt in self.ANALYZERS.items():
            tasks.append(self._analyze_with(name, prompt, code))
        
        results = await asyncio.gather(*tasks)
        
        # Fan-in: Aggregate results
        aggregator = await self._create_claude(
            "Merge analysis results. Output JSON: {critical: [], warnings: [], suggestions: []}"
        )
        return await aggregator.process(results)
```

### Bash Implementation

```bash
# Fan-out to multiple analyzers
code_file="app.py"

# Run analyzers in parallel
{
    claude -p "Security analysis. Output JSON: {issues: []}" < "$code_file" > security.json &
    claude -p "Performance analysis. Output JSON: {bottlenecks: []}" < "$code_file" > perf.json &
    claude -p "Style check. Output JSON: {violations: []}" < "$code_file" > style.json &
    claude -p "Bug detection. Output JSON: {bugs: []}" < "$code_file" > bugs.json &
    wait
}

# Fan-in: Merge results
claude -p "Merge all analysis results into unified report" security.json perf.json style.json bugs.json
```

## Recursive Pipeline Pattern

Claude instances spawning more Claude instances based on discoveries.

```python
class RecursiveAnalyzer:
    async def analyze_directory(self, path):
        explorer = Claude("""
        Explore directory. Output JSON: {
            type: 'file'|'directory',
            path: str,
            should_analyze: bool,
            should_recurse: bool,
            analysis_prompt: str
        }
        """)
        
        for item in os.listdir(path):
            result = await explorer.process(item)
            
            if result['should_analyze']:
                # Spawn specialized analyzer based on Claude's decision
                analyzer = Claude(result['analysis_prompt'])
                analysis = await analyzer.process_file(item)
                
            if result['should_recurse'] and result['type'] == 'directory':
                # Recursive call
                await self.analyze_directory(os.path.join(path, item))
```

## Map-Reduce Pattern

Distributed processing with hierarchical reduction.

```python
class ClaudeMapReduce:
    """Distributed processing with Claude workers"""
    
    async def map_reduce(self, data_chunks, map_prompt, reduce_prompt):
        # Map phase - parallel Claude instances
        map_tasks = []
        for i, chunk in enumerate(data_chunks):
            mapper = Claude(f"{map_prompt} Worker ID: {i}")
            map_tasks.append(mapper.process(chunk))
        
        map_results = await asyncio.gather(*map_tasks)
        
        # Reduce phase - hierarchical reduction
        while len(map_results) > 1:
            reduce_tasks = []
            for i in range(0, len(map_results), 2):
                reducer = Claude(reduce_prompt)
                chunk = map_results[i:i+2]
                reduce_tasks.append(reducer.process(chunk))
            
            map_results = await asyncio.gather(*reduce_tasks)
        
        return map_results[0]

# Example usage
analyzer = ClaudeMapReduce()
result = await analyzer.map_reduce(
    code_files,
    map_prompt="Count function calls. Output JSON: {counts: {function_name: count}}",
    reduce_prompt="Merge counts. Output JSON: {counts: {function_name: total_count}}"
)
```

### Bash Map-Reduce

```bash
# Split large file into chunks
split -l 1000 large_file.txt chunk_

# Map phase: Process each chunk in parallel
for chunk in chunk_*; do
    claude -p "Extract keywords. Output JSON: {keywords: {word: count}}" < "$chunk" > "${chunk}.json" &
done
wait

# Reduce phase: Merge results hierarchically
while [ $(ls *.json | wc -l) -gt 1 ]; do
    # Process pairs of files
    for f1 in *.json; do
        f2=$(ls *.json | grep -v "^$f1$" | head -1)
        if [ -n "$f2" ]; then
            claude -p "Merge keyword counts" "$f1" "$f2" > "merged_$(basename $f1 .json)_$(basename $f2 .json).json"
            rm "$f1" "$f2"
        fi
    done
done
```

## Conditional Pipeline Pattern

Dynamic pipeline paths based on intermediate results.

```python
class ConditionalPipeline:
    def __init__(self):
        self.router = Claude("""
        Analyze input and choose pipeline path.
        Output JSON: {
            complexity: 'simple'|'medium'|'complex',
            pipeline: [str],  # List of prompts to execute
            parallel_ok: bool
        }
        """)
    
    async def process(self, input_data):
        # Determine pipeline path
        route = await self.router.process(input_data)
        
        if route['parallel_ok']:
            # Execute pipeline stages in parallel
            tasks = [Claude(prompt).process(input_data) 
                    for prompt in route['pipeline']]
            results = await asyncio.gather(*tasks)
        else:
            # Execute sequentially
            data = input_data
            results = []
            for prompt in route['pipeline']:
                data = await Claude(prompt).process(data)
                results.append(data)
        
        return results
```

## Multi-Stage Code Generation Pipeline

Complete example of sophisticated pipeline for code generation.

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

## Pipeline Optimization Patterns

### Caching Intermediate Results

```bash
# Cache pipeline stages
cache_dir="/tmp/claude_cache"
mkdir -p "$cache_dir"

# Function to run cached Claude
cached_claude() {
    local prompt="$1"
    local input="$2"
    local cache_key=$(echo "$prompt:$input" | md5sum | cut -d' ' -f1)
    local cache_file="$cache_dir/$cache_key.json"
    
    if [ -f "$cache_file" ]; then
        cat "$cache_file"
    else
        result=$(echo "$input" | claude -p "$prompt")
        echo "$result" > "$cache_file"
        echo "$result"
    fi
}

# Use in pipeline
cat input.txt | \
cached_claude "Stage 1 analysis" "$(cat)" | \
cached_claude "Stage 2 transform" "$(cat)" | \
cached_claude "Stage 3 output" "$(cat)"
```

### Pipeline Monitoring

```python
class MonitoredPipeline:
    def __init__(self):
        self.metrics = {
            'stage_times': defaultdict(list),
            'stage_errors': defaultdict(int),
            'throughput': []
        }
    
    async def run_stage(self, stage_name, prompt, data):
        start_time = time.time()
        try:
            result = await Claude(prompt).process(data)
            self.metrics['stage_times'][stage_name].append(time.time() - start_time)
            return result
        except Exception as e:
            self.metrics['stage_errors'][stage_name] += 1
            raise
    
    async def get_metrics_summary(self):
        summary_prompt = """
        Analyze pipeline metrics.
        Input: {metrics}
        Output JSON: {
            bottleneck_stage: str,
            optimization_suggestions: [],
            health_score: float
        }
        """
        return await Claude(summary_prompt).process(self.metrics)
```

## Best Practices

1. **Design stages to be independent** - Each stage should work without knowledge of others
2. **Use JSON for inter-stage communication** - Ensures structured data flow
3. **Handle errors at each stage** - Don't let one failure break the entire pipeline
4. **Monitor performance** - Track which stages are bottlenecks
5. **Cache when appropriate** - Avoid reprocessing identical inputs
6. **Document stage interfaces** - Clear input/output specifications
7. **Test stages independently** - Each stage should be unit testable
8. **Consider parallelism** - Many pipelines can benefit from parallel execution
9. **Plan for scaling** - Design pipelines that can distribute across machines
10. **Version your prompts** - Pipeline behavior changes with prompt changes