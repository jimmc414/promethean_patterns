# Comprehensive JSON Pattern Test Plan

## Overview
Testing all examples from claude-p_custom_json_examples.md with systematic documentation and iteration.

## Test Strategy
1. Test each example with `--output-format json` for structured results
2. Document expected vs actual behavior
3. Create adjusted versions for patterns that don't work as expected
4. Measure performance and identify bottlenecks
5. Develop best practices based on findings

## Test Categories

### 1. Ellipsis (...) Expansion Testing (Lines 3-13)
- Test 1.1: Basic ellipsis expansion
- Test 1.2: Nested ellipsis
- Test 1.3: Pipeline ellipsis propagation

### 2. Array Behavior Testing (Lines 14-25)
- Test 2.1: Empty vs populated arrays with conditionals
- Test 2.2: Array spreading with ellipsis
- Test 2.3: Array filtering logic

### 3. Pipe (|) Alternatives Testing (Lines 26-38)
- Test 3.1: Enum selection with loop
- Test 3.2: Branching paths with conditions
- Test 3.3: Pipeline with alternatives

### 4. State Machine Pipeline (Lines 41-53)
- Test 4.1: Simple state transitions
- Test 4.2: State loops with iteration

### 5. Accumulator Pattern (Lines 54-66)
- Test 5.1: Building up data through pipeline
- Test 5.2: Conditional accumulation

### 6. Transformation Pipeline (Lines 67-80)
- Test 6.1: Data transformation chain
- Test 6.2: Type conversion pipeline

### 7. Validation Pipeline (Lines 81-93)
- Test 7.1: Multi-stage validation
- Test 7.2: Cascading validations

### 8. Dynamic Schema Building (Lines 94-103)
- Test 8.1: Schema based on input type
- Test 8.2: Nested schema generation

### 9. Error Handling Pipeline (Lines 104-117)
- Test 9.1: Error propagation
- Test 9.2: Recovery pipeline

### 10. Map-Reduce Pattern (Lines 118-129)
- Test 10.1: Map phase with array operations
- Test 10.2: Parallel-style processing

### 11. Conditional Field Inclusion (Lines 130-139)
- Test 11.1: Role-based field inclusion
- Test 11.2: Level-based dynamic objects

### 12. Recursive-like Patterns (Lines 140-151)
- Test 12.1: Simulated recursion
- Test 12.2: Nested expansion

### 13. Smart Pipeline Routing (Lines 152-163)
- Test 13.1: Decision-based routing
- Test 13.2: Multi-path convergence

### 14. Special Characters (Lines 164-171)
- Test 14.1: JSON special character handling
- Test 14.2: Array vs string behavior

### 15. Complete Test Suite (Lines 172-194)
- Test 15.1: Full test aggregation pipeline

### 16. Fun Creative Examples (Lines 195-212)
- Test 16.1: Emoji state machine
- Test 16.2: Mini game logic
- Test 16.3: Code generator pipeline

## Test Execution Plan

1. Create test runner script
2. Execute each test with timeout handling
3. Capture results in structured format
4. Generate summary report with pass/fail/timeout statistics
5. Create adjusted examples for failed tests
6. Document learnings and best practices