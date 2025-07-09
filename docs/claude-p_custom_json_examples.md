  Testing JSON Structure Behaviors

  1. Ellipsis (...) Expansion Testing

  # Test how ... fills in content
  echo "hello" | claude -p '{greeting:...,expand:{more:...,data:[...]}}'

  # Test nested ellipsis
  echo "a" | claude -p '{input:...,process:{transform:...,results:[...],meta:{...}}}'

  # Pipeline test - see how ... propagates
  echo "test" | claude -p '{data:...,next:"analyze"}' | claude -p '{prev:...,analyzed:{findings:[...]}}'

  2. Array Behavior Testing

  # Test empty vs populated arrays
  echo "0" | claude -p '{count:0,items:count>0?["a","b","c"]:[]}'
  echo "3" | claude -p '{count:3,items:count>0?["a","b","c"]:[]}'

  # Test array spreading
  echo "x" | claude -p '{base:["a","b"],if true:{extended:[...base,"c","d"]}}'

  # Test array filtering logic
  echo "filter" | claude -p '{all:[1,2,3,4,5],even:[2,4],odd:[1,3,5]}'

  3. Pipe (|) Alternatives Testing

  # Test enum selection
  for choice in small medium large; do
    echo "$choice" | claude -p '{size:...,category:small|medium|large,price:size=="small"?5:size=="medium"?10:20}'
  done

  # Test branching paths
  echo "random" | claude -p '{path:analyze|skip|defer,if path=="analyze":{depth:"full"},if path=="skip":{reason:"..."}}'

  # Pipeline with alternatives
  echo "go" | claude -p '{action:start|stop|pause}' | claude -p '{prev:...,state:action=="start"?"running":"stopped"}'

  Creative Pipeline Examples

  4. State Machine Pipeline

  # Simple state transitions
  echo "init" | \
  claude -p '{state:"init",next:"loading"}' | \
  claude -p '{state:...,if state.next=="loading":{status:"loading",next:"ready"}}' | \
  claude -p '{state:...,if state.next=="ready":{status:"active",data:[...]}}'

  # Test state loops
  for i in 1 2 3; do
    echo "$i" | claude -p "{iteration:$i,state:iteration<3?\"continue\":\"done\",data:[...Array($i)]}"
  done

  5. Accumulator Pattern

  # Building up data through pipeline
  echo "1" | \
  claude -p '{value:1,acc:[1]}' | \
  claude -p '{prev:...,value:2,acc:[...prev.acc,2]}' | \
  claude -p '{prev:...,value:3,acc:[...prev.acc,3],sum:6}'

  # Conditional accumulation
  echo "start" | \
  claude -p '{items:[],addItem:true}' | \
  claude -p '{prev:...,if prev.addItem:{items:[...prev.items,"new"]},else:{items:prev.items}}'

  6. Transformation Pipeline

  # Data transformation chain
  echo "RaW-DaTa" | \
  claude -p '{input:...,clean:input.toLowerCase()}' | \
  claude -p '{prev:...,words:prev.clean.split("-")}' | \
  claude -p '{prev:...,formatted:prev.words.map(w=>w.capitalize()).join(" ")}'

  # Type conversion pipeline
  echo "123" | \
  claude -p '{str:"123",num:123}' | \
  claude -p '{prev:...,doubled:prev.num*2}' | \
  claude -p '{prev:...,final:String(prev.doubled)}'

  7. Validation Pipeline

  # Multi-stage validation
  echo "user@example.com" | \
  claude -p '{email:...,valid:email.includes("@")}' | \
  claude -p '{prev:...,if prev.valid:{domain:prev.email.split("@")[1]},else:{error:"invalid"}}' | \
  claude -p '{prev:...,if prev.domain:{tld:prev.domain.split(".").pop()},else:prev}'

  # Cascading validations
  echo "5" | \
  claude -p '{value:5,checks:{isNumber:true,inRange:value>=1&&value<=10}}' | \
  claude -p '{prev:...,if prev.checks.isNumber&&prev.checks.inRange:{status:"valid"},else:{status:"invalid"}}'

  8. Dynamic Schema Building

  # Build schema based on input
  echo "user" | \
  claude -p '{type:...,schema:type=="user"?{name:str,email:str}:type=="product"?{id:int,price:float}:{}}'

  # Nested schema generation
  echo "complex" | \
  claude -p '{buildSchema:{user:{fields:["id","name"],relations:{posts:[...]}},post:{fields:["title","content"]}}}'

  9. Error Handling Pipeline

  # Error propagation
  echo "process" | \
  claude -p '{action:"process",risky:true}' | \
  claude -p '{prev:...,if prev.risky:{try:"execute",catch:{error:"handled",fallback:"safe"}}}' | \
  claude -p '{prev:...,result:prev.catch?prev.catch.fallback:"success"}'

  # Recovery pipeline
  echo "fail" | \
  claude -p '{attempt:1,success:false}' | \
  claude -p '{prev:...,if !prev.success:{attempt:prev.attempt+1,retry:true}}' | \
  claude -p '{prev:...,if prev.retry&&prev.attempt<=3:{retrying:true},else:{giveUp:true}}'

  10. Map-Reduce Pattern

  # Map phase
  echo "1,2,3" | \
  claude -p '{input:...,values:[1,2,3],mapped:values.map(v=>v*2)}' | \
  claude -p '{prev:...,reduced:prev.mapped.reduce((a,b)=>a+b,0)}'

  # Parallel-style processing simulation
  for item in a b c; do
    echo "$item" | claude -p "{item:\"$item\",processed:{data:\"$item\",timestamp:now}}"
  done | claude -p '{batch:[...],summary:{count:batch.length,items:batch.map(b=>b.item)}}'

  11. Conditional Field Inclusion

  # Fields appear/disappear based on conditions
  echo "admin" | \
  claude -p '{role:...,user:{name:"John",if role=="admin":{permissions:["all"]},if role=="user":{permissions:["read"]}}}'

  # Dynamic object construction
  echo "5" | \
  claude -p '{level:5,powers:{basic:true,if level>3:{advanced:true},if level>7:{master:true}}}'

  12. Recursive-like Patterns

  # Simulated recursion
  echo "3" | \
  claude -p '{depth:3,dive:{level:1,data:"a"}}' | \
  claude -p '{prev:...,if prev.depth>1:{dive:{level:2,data:"b",parent:prev.dive}}}' | \
  claude -p '{prev:...,if prev.depth>2:{dive:{level:3,data:"c",parent:prev.dive}}}'

  # Nested expansion
  echo "expand" | \
  claude -p '{action:"expand",tree:{root:{if action=="expand":{children:[{leaf:1},{leaf:2}]}}}}'

  13. Smart Pipeline Routing

  # Decision-based routing
  echo "analyze" | \
  claude -p '{cmd:...,route:cmd=="analyze"?"deep":cmd=="scan"?"quick":"skip"}' | \
  claude -p '{prev:...,if prev.route=="deep":{analysis:{detailed:true,metrics:[...]}},else:{skipped:true}}'

  # Multi-path convergence
  { echo "path1" | claude -p '{source:"a",data:1}';
    echo "path2" | claude -p '{source:"b",data:2}'; } | \
  claude -p '{inputs:[...],merged:{sources:inputs.map(i=>i.source),total:inputs.reduce((s,i)=>s+i.data,0)}}'

  14. Testing Special Characters

  # Test JSON special handling
  echo 'te"st' | claude -p '{input:...,escaped:input.replace("\"","\\\"")}'

  # Array vs string behavior
  echo "a,b,c" | claude -p '{str:"a,b,c",arr:str.split(","),joined:arr.join("|")}'

  15. Complete Test Suite Pipeline

  #!/bin/bash
  # Run all tests and aggregate results

  test_results=()

  # Test 1: Conditionals
  result=$(echo "5" | claude -p '{n:5,test:n>3?"pass":"fail"}' | jq -r .test)
  test_results+=("conditional:$result")

  # Test 2: Arrays
  result=$(echo "x" | claude -p '{items:[1,2,3],count:items.length}' | jq -r .count)
  test_results+=("array_count:$result")

  # Test 3: Pipeline
  result=$(echo "go" | claude -p '{cmd:"go",next:"process"}' | claude -p '{prev:...,executed:prev.next=="process"}' | jq -r .executed)
  test_results+=("pipeline:$result")

  # Aggregate all results
  printf '%s\n' "${test_results[@]}" | \
  claude -p '{results:[...],summary:{total:results.length,passed:results.filter(r=>r.includes("pass")||r.includes("true")).length}}'

  16. Fun Creative Examples

  # Emoji state machine
  echo "😀" | \
  claude -p '{mood:"😀",next:mood=="😀"?"😎":"😢"}' | \
  claude -p '{prev:...,transition:prev.mood+"→"+prev.next}'

  # Mini game logic
  echo "start" | \
  claude -p '{game:{hp:10,player:"hero"}}' | \
  claude -p '{prev:...,event:"damage",game:{hp:prev.game.hp-3,status:prev.game.hp>7?"healthy":"hurt"}}' | \
  claude -p '{prev:...,if prev.game.hp<5:{alert:"Low health!",action:"heal"}}'

  # Code generator pipeline
  echo "Button" | \
  claude -p '{component:...,template:`<${component}></${component}>`}' | \
  claude -p '{prev:...,withProps:{html:prev.template.replace(">",` class="primary">`)}}'

  These examples demonstrate:
  - How ... expands contextually
  - Array manipulation and spreading
  - Conditional field inclusion/exclusion
  - Pipeline state passing
  - Complex nested structures
  - Dynamic schema building