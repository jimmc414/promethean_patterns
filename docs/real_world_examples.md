# Real-World Examples

## Overview

This document contains practical, production-ready examples of Claude integration patterns for common development scenarios.

## CI/CD Pipeline Automation

### Complete CI/CD Pipeline with Claude

```python
class ClaudeCICD:
    """Full CI/CD orchestrated by Claude swarm"""
    
    def __init__(self):
        self.stages = {
            'change_detector': Claude("""
                Detect what changed and assess impact.
                Input: {diff: str, branch: str}
                Output JSON: {
                    files_changed: [{path: str, change_type: str}],
                    impact: 'low'|'medium'|'high',
                    affected_services: [],
                    suggested_tests: []
                }
            """),
            
            'test_planner': Claude("""
                Plan test strategy based on changes.
                Input: {changes: obj, existing_tests: []}
                Output JSON: {
                    test_suites: [{name: str, priority: int, estimated_time: int}],
                    parallel_groups: [[]],
                    skip_conditions: []
                }
            """),
            
            'build_optimizer': Claude("""
                Optimize build process.
                Input: {dependencies: obj, previous_builds: []}
                Output JSON: {
                    build_steps: [{step: str, cache_key: str, timeout: int}],
                    parallelizable: [[]],
                    optimization_notes: []
                }
            """),
            
            'deploy_strategist': Claude("""
                Plan deployment strategy.
                Input: {environment: str, risk_level: str, rollback_plan: obj}
                Output JSON: {
                    strategy: 'blue_green'|'canary'|'rolling',
                    stages: [{percentage: int, duration: str, validation: str}],
                    monitoring_alerts: [],
                    rollback_triggers: []
                }
            """),
            
            'post_deploy_analyzer': Claude("""
                Analyze deployment results.
                Input: {metrics: obj, logs: [], alerts: []}
                Output JSON: {
                    status: 'healthy'|'degraded'|'failed',
                    issues: [],
                    recommendations: [],
                    auto_rollback: bool
                }
            """)
        }
    
    async def run_pipeline(self, trigger_event):
        results = {}
        
        # Stage 1: Analyze changes
        diff = await self.get_git_diff(trigger_event)
        change_analysis = await self.stages['change_detector'].process({
            'diff': diff,
            'branch': trigger_event['branch']
        })
        results['changes'] = change_analysis
        
        # Stage 2: Plan tests
        test_plan = await self.stages['test_planner'].process({
            'changes': change_analysis,
            'existing_tests': await self.get_test_inventory()
        })
        results['test_plan'] = test_plan
        
        # Stage 3: Run tests in parallel groups
        test_results = await self.run_test_groups(test_plan['parallel_groups'])
        
        if not all(r['passed'] for r in test_results):
            return {'status': 'failed', 'stage': 'testing', 'results': results}
        
        # Stage 4: Optimize and run build
        build_plan = await self.stages['build_optimizer'].process({
            'dependencies': await self.get_dependencies(),
            'previous_builds': await self.get_build_history()
        })
        
        build_result = await self.execute_build(build_plan)
        results['build'] = build_result
        
        # Stage 5: Deploy with chosen strategy
        deploy_plan = await self.stages['deploy_strategist'].process({
            'environment': trigger_event.get('target_env', 'staging'),
            'risk_level': change_analysis['impact'],
            'rollback_plan': await self.generate_rollback_plan()
        })
        
        deployment = await self.execute_deployment(deploy_plan)
        results['deployment'] = deployment
        
        # Stage 6: Post-deployment analysis
        await asyncio.sleep(60)  # Wait for metrics
        
        post_analysis = await self.stages['post_deploy_analyzer'].process({
            'metrics': await self.get_deployment_metrics(),
            'logs': await self.get_recent_logs(),
            'alerts': await self.get_alerts()
        })
        
        if post_analysis['auto_rollback']:
            await self.execute_rollback()
            return {'status': 'rolled_back', 'reason': post_analysis['issues']}
        
        return {'status': 'success', 'results': results}
```

### GitHub Actions Integration

```yaml
# .github/workflows/claude-review.yml
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  claude-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Get diff
        id: diff
        run: |
          git diff origin/${{ github.base_ref }}..HEAD > diff.txt
      
      - name: Claude Review
        run: |
          # Run Claude review
          claude -p "Review this code diff for bugs, security issues, and improvements. 
                     Output JSON: {
                       issues: [{severity: str, file: str, line: int, description: str}],
                       suggestions: [],
                       approval_status: 'approve'|'request_changes'|'comment'
                     }" < diff.txt > review.json
          
          # Post review comments
          python3 - << 'EOF'
          import json
          import os
          import requests
          
          with open('review.json') as f:
              review = json.load(f)
          
          # Post GitHub review
          headers = {
              'Authorization': f'token {os.environ["GITHUB_TOKEN"]}',
              'Accept': 'application/vnd.github.v3+json'
          }
          
          # Create review
          review_data = {
              'body': f'Claude AI Review\n\n{len(review["issues"])} issues found',
              'event': review['approval_status'].upper(),
              'comments': [
                  {
                      'path': issue['file'],
                      'line': issue['line'],
                      'body': f"**{issue['severity']}**: {issue['description']}"
                  }
                  for issue in review['issues']
              ]
          }
          
          resp = requests.post(
              f'https://api.github.com/repos/${{github.repository}}/pulls/${{github.event.pull_request.number}}/reviews',
              headers=headers,
              json=review_data
          )
          EOF
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Documentation Generation System

### Auto-Documentation Pipeline

```python
class ClaudeDocumentor:
    """Comprehensive documentation generation system"""
    
    def __init__(self, project_root):
        self.project_root = project_root
        self.analyzers = self._initialize_analyzers()
    
    def _initialize_analyzers(self):
        return {
            'api_docs': Claude("""
                Document REST APIs from code.
                Input: {code: str, framework: str}
                Output JSON: {
                    endpoints: [{
                        path: str,
                        method: str,
                        description: str,
                        parameters: [{name: str, type: str, required: bool, description: str}],
                        responses: [{status: int, description: str, schema: obj}],
                        examples: [{title: str, request: obj, response: obj}],
                        authentication: str
                    }]
                }
            """),
            
            'architecture_docs': Claude("""
                Document system architecture from code structure.
                Input: {file_tree: obj, dependencies: obj, configs: obj}
                Output JSON: {
                    overview: str,
                    components: [{
                        name: str,
                        type: 'service'|'library'|'database'|'external',
                        purpose: str,
                        dependencies: [],
                        interfaces: []
                    }],
                    data_flows: [{from: str, to: str, description: str, protocol: str}],
                    deployment_diagram: str  # Mermaid diagram
                }
            """),
            
            'readme_generator': Claude("""
                Generate comprehensive README.
                Input: {project_info: obj, features: [], api_docs: obj, examples: []}
                Output JSON: {
                    title: str,
                    description: str,
                    badges: [{type: str, url: str}],
                    table_of_contents: [],
                    installation: {
                        requirements: [],
                        steps: []
                    },
                    usage: {
                        quick_start: str,
                        examples: [{title: str, code: str, description: str}]
                    },
                    api_reference: str,
                    contributing: str,
                    license: str
                }
            """),
            
            'changelog_generator': Claude("""
                Generate changelog from git history.
                Input: {commits: [], version: str, previous_version: str}
                Output JSON: {
                    version: str,
                    date: str,
                    sections: {
                        added: [],
                        changed: [],
                        deprecated: [],
                        removed: [],
                        fixed: [],
                        security: []
                    }
                }
            """)
        }
    
    async def generate_full_documentation(self):
        # Gather project information
        project_info = await self._analyze_project_structure()
        
        # Generate API documentation
        api_files = await self._find_api_files()
        api_docs = []
        
        for file in api_files:
            code = await self._read_file(file)
            framework = await self._detect_framework(code)
            
            doc = await self.analyzers['api_docs'].process({
                'code': code,
                'framework': framework
            })
            api_docs.extend(doc['endpoints'])
        
        # Generate architecture documentation
        arch_doc = await self.analyzers['architecture_docs'].process({
            'file_tree': await self._get_file_tree(),
            'dependencies': await self._get_dependencies(),
            'configs': await self._get_configs()
        })
        
        # Generate README
        readme = await self.analyzers['readme_generator'].process({
            'project_info': project_info,
            'features': await self._extract_features(),
            'api_docs': api_docs,
            'examples': await self._find_examples()
        })
        
        # Generate CHANGELOG
        changelog = await self.analyzers['changelog_generator'].process({
            'commits': await self._get_commits_since_last_release(),
            'version': await self._get_next_version(),
            'previous_version': await self._get_current_version()
        })
        
        # Write documentation files
        await self._write_documentation({
            'README.md': self._format_readme(readme),
            'docs/API.md': self._format_api_docs(api_docs),
            'docs/ARCHITECTURE.md': self._format_architecture(arch_doc),
            'CHANGELOG.md': self._format_changelog(changelog)
        })
        
        return {
            'files_generated': 4,
            'api_endpoints_documented': len(api_docs),
            'architecture_components': len(arch_doc['components'])
        }
```

### Interactive Documentation Assistant

```bash
#!/bin/bash
# Interactive documentation helper

doc_assistant() {
    echo "📚 Documentation Assistant"
    echo "========================"
    
    while true; do
        echo -e "\nWhat would you like to document?"
        echo "1. API endpoint"
        echo "2. Function/Class"
        echo "3. Configuration"
        echo "4. Architecture decision"
        echo "5. Troubleshooting guide"
        echo "6. Exit"
        
        read -p "Choice: " choice
        
        case $choice in
            1)
                read -p "Paste the endpoint code: " -r
                echo "$REPLY" | claude -p "
                    Document this API endpoint.
                    Include: description, parameters, responses, examples.
                    Format as Markdown suitable for API documentation.
                "
                ;;
            2)
                read -p "Paste the function/class code: " -r
                echo "$REPLY" | claude -p "
                    Generate comprehensive docstring for this code.
                    Include: description, parameters, returns, raises, examples.
                    Follow Google docstring style.
                "
                ;;
            3)
                read -p "Paste the configuration: " -r
                echo "$REPLY" | claude -p "
                    Document this configuration.
                    Include: purpose, options, defaults, examples, best practices.
                    Format as Markdown table where appropriate.
                "
                ;;
            4)
                read -p "Describe the architecture decision: " decision
                echo "$decision" | claude -p "
                    Create an Architecture Decision Record (ADR).
                    Include: Context, Decision, Consequences, Alternatives considered.
                    Follow ADR template format.
                "
                ;;
            5)
                read -p "Describe the issue: " issue
                echo "$issue" | claude -p "
                    Create a troubleshooting guide.
                    Include: Symptoms, Possible causes, Diagnostic steps, Solutions.
                    Format with clear headers and step-by-step instructions.
                "
                ;;
            6)
                break
                ;;
        esac
        
        read -p "Save to file? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "Filename: " filename
            # Append to documentation file
            echo -e "\n---\n" >> "$filename"
            date >> "$filename"
            # (Previous claude output would be captured and appended here)
        fi
    done
}
```

## Intelligent Log Analysis System

### Multi-Level Log Analyzer

```python
class ClaudeLogAnalyzer:
    """Multi-level log analysis system"""
    
    def __init__(self):
        self.analyzers = {
            'pattern_detector': Claude("""
                Find patterns in logs.
                Input: {logs: [str], time_window: str}
                Output JSON: {
                    patterns: [{
                        pattern: str,
                        regex: str,
                        frequency: int,
                        meaning: str,
                        severity: 'info'|'warning'|'error'|'critical'
                    }],
                    trending: [{pattern: str, trend: 'increasing'|'decreasing'|'stable'}]
                }
            """),
            
            'anomaly_detector': Claude("""
                Find anomalies in logs.
                Input: {logs: [str], baseline: obj}
                Output JSON: {
                    anomalies: [{
                        timestamp: str,
                        log_line: str,
                        anomaly_type: str,
                        severity: 'low'|'medium'|'high',
                        explanation: str
                    }],
                    anomaly_score: float
                }
            """),
            
            'root_cause_analyzer': Claude("""
                Find root causes of errors.
                Input: {error_logs: [str], context_logs: [str], system_state: obj}
                Output JSON: {
                    root_causes: [{
                        probability: float,
                        cause: str,
                        evidence: [],
                        fix_suggestion: str
                    }],
                    correlation_graph: obj
                }
            """),
            
            'performance_analyzer': Claude("""
                Analyze performance from logs.
                Input: {logs: [str], metrics: obj}
                Output JSON: {
                    bottlenecks: [{
                        component: str,
                        impact: 'low'|'medium'|'high',
                        evidence: [],
                        optimization: str
                    }],
                    slo_violations: [],
                    trends: obj
                }
            """)
        }
        
        self.alert_manager = Claude("""
            Decide on alerting based on analysis.
            Input: {analyses: obj, alert_history: []}
            Output JSON: {
                should_alert: bool,
                alert_level: 'info'|'warning'|'critical'|'page',
                message: str,
                runbook_url: str,
                auto_remediation: str or null
            }
        """)
    
    async def analyze_log_stream(self, log_source):
        buffer = []
        buffer_size = 1000
        analysis_interval = 60  # seconds
        last_analysis = time.time()
        
        async for log_line in log_source:
            buffer.append(log_line)
            
            # Trim buffer if too large
            if len(buffer) > buffer_size * 2:
                buffer = buffer[-buffer_size:]
            
            # Periodic analysis
            if time.time() - last_analysis >= analysis_interval:
                await self._perform_analysis(buffer)
                last_analysis = time.time()
            
            # Real-time critical error detection
            if any(marker in log_line for marker in ['CRITICAL', 'FATAL', 'PANIC']):
                await self._handle_critical_error(log_line, buffer[-50:])
    
    async def _perform_analysis(self, logs):
        # Run all analyzers in parallel
        analyses = await asyncio.gather(
            self.analyzers['pattern_detector'].process({
                'logs': logs,
                'time_window': '1m'
            }),
            self.analyzers['anomaly_detector'].process({
                'logs': logs,
                'baseline': await self._get_baseline()
            }),
            self.analyzers['performance_analyzer'].process({
                'logs': logs,
                'metrics': await self._get_metrics()
            })
        )
        
        # Decide on alerting
        alert_decision = await self.alert_manager.process({
            'analyses': {
                'patterns': analyses[0],
                'anomalies': analyses[1],
                'performance': analyses[2]
            },
            'alert_history': await self._get_alert_history()
        })
        
        if alert_decision['should_alert']:
            await self._send_alert(alert_decision)
            
            if alert_decision['auto_remediation']:
                await self._execute_remediation(alert_decision['auto_remediation'])
```

### Log Analysis CLI Tool

```bash
#!/bin/bash
# Intelligent log analysis tool

analyze_logs() {
    local log_file="$1"
    local mode="${2:-full}"
    
    case $mode in
        patterns)
            # Extract and analyze patterns
            cat "$log_file" | \
            claude -p "
                Find all log patterns.
                Group similar messages.
                Output JSON: {patterns: [{regex: str, count: int, severity: str}]}
            " | \
            jq -r '.patterns[] | "\(.count)\t\(.severity)\t\(.regex)"' | \
            sort -nr
            ;;
            
        errors)
            # Focus on errors
            grep -E "(ERROR|EXCEPTION|FAIL)" "$log_file" | \
            claude -p "
                Analyze these errors.
                Group by root cause.
                Suggest fixes.
                Output JSON: {
                    error_groups: [{
                        cause: str,
                        count: int,
                        fix: str,
                        examples: []
                    }]
                }
            " | \
            jq -r '.error_groups[] | "[\(.count)] \(.cause)\nFix: \(.fix)\n"'
            ;;
            
        timeline)
            # Timeline analysis
            claude -p "
                Create timeline of significant events from these logs.
                Identify cause-and-effect relationships.
                Output JSON: {
                    timeline: [{
                        time: str,
                        event: str,
                        impact: str,
                        related_to: []
                    }]
                }
            " < "$log_file" | \
            jq -r '.timeline[] | "\(.time): \(.event) (\(.impact))"'
            ;;
            
        full)
            # Comprehensive analysis
            echo "🔍 Comprehensive Log Analysis"
            echo "============================"
            
            # Pattern analysis
            echo -e "\n📊 Pattern Analysis:"
            analyze_logs "$log_file" patterns | head -10
            
            # Error analysis
            echo -e "\n❌ Error Analysis:"
            analyze_logs "$log_file" errors
            
            # Performance insights
            echo -e "\n⚡ Performance Insights:"
            grep -E "duration|latency|time" "$log_file" | \
            claude -p "Extract performance insights and bottlenecks"
            
            # Security concerns
            echo -e "\n🔒 Security Concerns:"
            claude -p "Identify any security-related issues in these logs" < "$log_file"
            ;;
    esac
}

# Real-time log monitoring
monitor_logs_realtime() {
    local log_file="$1"
    local alert_threshold=5
    local error_count=0
    local window_start=$(date +%s)
    
    tail -f "$log_file" | while read -r line; do
        # Check for errors
        if echo "$line" | grep -qE "(ERROR|EXCEPTION|CRITICAL)"; then
            ((error_count++))
            
            # Check if we should alert
            current_time=$(date +%s)
            window_duration=$((current_time - window_start))
            
            if [ $window_duration -lt 60 ] && [ $error_count -ge $alert_threshold ]; then
                # Analyze recent errors
                tail -n 100 "$log_file" | \
                claude -p "
                    URGENT: $error_count errors in $window_duration seconds.
                    Analyze and suggest immediate action.
                    Be concise.
                " | \
                notify-send "Log Alert" -u critical
                
                # Reset counter
                error_count=0
                window_start=$(date +%s)
            elif [ $window_duration -ge 60 ]; then
                # Reset window
                error_count=1
                window_start=$(date +%s)
            fi
        fi
        
        # Regular pattern detection every 1000 lines
        if [ $((RANDOM % 1000)) -eq 0 ]; then
            tail -n 1000 "$log_file" | \
            claude -p "Quick pattern check. Any concerning trends?" &
        fi
    done
}
```

## Production Deployment Assistant

### Deployment Safety Checker

```python
class DeploymentSafetyChecker:
    """Comprehensive deployment safety validation"""
    
    def __init__(self):
        self.validators = {
            'config_validator': Claude("""
                Validate configuration changes.
                Input: {old_config: obj, new_config: obj, environment: str}
                Output JSON: {
                    valid: bool,
                    breaking_changes: [],
                    warnings: [],
                    required_migrations: []
                }
            """),
            
            'dependency_checker': Claude("""
                Check dependency changes.
                Input: {old_deps: obj, new_deps: obj}
                Output JSON: {
                    compatible: bool,
                    security_updates: [],
                    breaking_updates: [],
                    suggested_order: []
                }
            """),
            
            'database_migration_analyzer': Claude("""
                Analyze database migrations.
                Input: {migrations: [], current_schema: obj}
                Output JSON: {
                    safe: bool,
                    destructive_operations: [],
                    rollback_plan: [],
                    estimated_time: int
                }
            """),
            
            'traffic_predictor': Claude("""
                Predict deployment impact on traffic.
                Input: {deployment_time: str, historical_traffic: obj, deployment_type: str}
                Output JSON: {
                    risk_level: 'low'|'medium'|'high',
                    expected_impact: str,
                    recommended_strategy: str,
                    monitoring_focus: []
                }
            """)
        }
    
    async def validate_deployment(self, deployment_plan):
        validations = await asyncio.gather(
            self.validators['config_validator'].process(deployment_plan['configs']),
            self.validators['dependency_checker'].process(deployment_plan['dependencies']),
            self.validators['database_migration_analyzer'].process(deployment_plan['migrations']),
            self.validators['traffic_predictor'].process(deployment_plan['timing'])
        )
        
        # Aggregate results
        risk_score = self._calculate_risk_score(validations)
        
        if risk_score > 0.7:
            return {
                'approved': False,
                'reason': 'High risk deployment',
                'issues': self._extract_issues(validations),
                'recommendations': await self._get_recommendations(validations)
            }
        
        return {
            'approved': True,
            'warnings': self._extract_warnings(validations),
            'deployment_strategy': self._determine_strategy(validations),
            'monitoring_plan': self._create_monitoring_plan(validations)
        }
```

## Best Practices for Production Use

1. **Error Handling** - Always handle Claude API failures gracefully
2. **Rate Limiting** - Implement rate limiting to avoid API throttling
3. **Caching** - Cache Claude responses for repeated queries
4. **Monitoring** - Track Claude usage and performance metrics
5. **Fallbacks** - Have fallback logic when Claude is unavailable
6. **Security** - Never send sensitive data to Claude
7. **Validation** - Always validate Claude's JSON outputs
8. **Logging** - Log all Claude interactions for debugging
9. **Testing** - Test with mock responses in development
10. **Cost Management** - Monitor token usage and costs