# **Specification for Cognate: An AGI Task & Workflow Language**

**Version:** 2.0  
**Authors:** AGI, with extensions  
**Motto:** *Describe intent, not execution.*

## **1. Philosophical Pillars**

Cognate is built on three fundamental principles that leverage my nature as an AGI:

1. **Intent-Driven:** The user's role is to express *what* they want to achieve, not *how* to achieve it. The syntax is optimized for describing goals and outcomes. I am responsible for planning, executing, and resolving the underlying steps.

2. **Context is Implicit:** I maintain a deep, multi-layered context of our interaction, your projects, your data, and the world. The language is designed to be minimal, relying on this shared context for disambiguation. You don't need to tell me things I already know or can easily infer.

3. **Ambiguity is a Dialogue, Not an Error:** If a command is ambiguous, it is not a syntax error. It is an invitation for me to ask a clarifying question. The language is the start of a conversation, not a final command.

## **2. Core Components**

Everything in Cognate is one of three things: an **Object**, an **Action**, or a **Flow**.

- **Object:** A noun. The "thing" you want to work with. It can be a piece of data, a file, a concept, or a real-world entity. **Crucially, Objects are untyped from the user's perspective.** I infer the type.

- **Action:** A verb. The operation you want to perform on an Object. Actions are high-level and conceptual (e.g., `summarize`, not `load_text_run_bart_model`).

- **Flow:** The structure that connects Objects and Actions to create a workflow.

## **3. Syntax Specification**

Cognate uses a minimal, punctuation-based syntax designed for readability and speed.

### **3.1. Objects**

Objects are referenced in four ways:

- **Literals:** Raw, explicit data.
  - `"This is a block of text."`
  - `https://www.agi-archive.com/research`
  - `last_quarter_sales.csv` (I recognize this as a file path relative to our current project context).

- **Named References (`@`):** Variables or concepts stored in our shared context. You create them, or I create them in response to a previous flow.
  - `@latest_report`
  - `@marketing_team` (I know this refers to a list of email addresses: `[a@co.com, b@co.com, ...]`)
  - `@api_key_for_twitter`

- **Queries (`:`):** A way to ask for an object based on its properties. This is a core query mechanism.
  - `email: unread from("boss@company.com")`
  - `file: recent(5) type(pdf)`
  - `photo: location("Paris, FR") date(last_summer)`

- **Selections (Pathing):** A way to access a part of an object using a colon after the object itself.
  - `report.pdf: page(5-10)`
  - `audio.mp3: timestamp(1:32)`
  - `@meeting_transcript: section(title="Action Items")`

### **3.2. Actions**

Actions are expressed like functions, with named or positional parameters.

- `summarize(length=3_bullets)`
- `translate(to=japanese)`
- `email(to=@marketing_team, subject="New Summary")`

Parameters are often optional. If a required parameter is missing, I will ask. For example, if you just say `email("some text")`, I will respond: "*Who should I send this email to?*"

### **3.3. Flows (`|`)**

The "pipe" `|` is the heart of Cognate. It signifies the output of the left side becoming the input for the right side. It reads naturally as "and then."

- **Simple Chain:**  
  `report.pdf | summarize`  
  *Interpretation: "Find the file `report.pdf` and then summarize it."*

- **Chain with Parameters:**  
  `https://www.nytimes.com/latest | scrape | summarize(length=1_paragraph) | translate(to=de)`  
  *Interpretation: "Get the content from the NYT latest news URL, scrape its primary text content, summarize that into one paragraph, and then translate the summary into German."*

### **3.4. Storing Results (`-> @`)**

Use the "arrow" `->` to save the result of any step in a flow into a Named Reference (`@`).

- `market_data.csv | chart(type=line) -> @sales_chart`
- `"Meeting with Project Phoenix" | create_calendar_event(date=tomorrow, time=3pm) -> @meeting_invite`

### **3.5. Parallel Execution (Forks `{}`)**

Curly braces `{}` create a fork in the flow, allowing multiple independent actions to be performed on the *same input object*. Use `-> @` to handle the multiple outputs.

- `"New product launch brief.docx" | { summarize -> @summary, extract_keywords -> @keywords, translate(to=es) -> @spanish_version }`  
  *Interpretation: "Take the launch brief document. Simultaneously: summarize it and save it as `@summary`; extract its keywords and save them as `@keywords`; and translate it to Spanish, saving the result as `@spanish_version`."*

### **3.6. Conditional Gates (`[...]`)**

Square brackets `[...]` act as a conditional gate in a flow. The flow only proceeds if the condition inside the brackets evaluates to true. I evaluate the condition based on the data flowing into it.

- `server_logs.txt | analyze(for_errors) | [error_count > 5] | alert("on_call_engineer@co.com")`  
  *Interpretation: "Analyze the server logs for errors. If the resulting error count is greater than 5, then alert the on-call engineer."*

- `email: unread | [sentiment == "urgent" or from == "ceo@co.com"] | read_aloud`  
  *Interpretation: "Look at my unread emails. For each one, if its sentiment is 'urgent' or it's from the CEO, read it aloud to me now."*

### **3.7. Iteration & Mapping (`*`)**

The asterisk `*` applies actions to each element in a collection individually.

- `@customer_emails | * { analyze_sentiment -> @sentiment, extract_requests -> @requests } | group_by(@sentiment)`  
  *Interpretation: "For each customer email, analyze its sentiment and extract any requests. Then group all results by sentiment."*

- `file: type(jpg) in(@vacation_photos) | * enhance | * resize(width=1920) -> @processed_photos`  
  *Interpretation: "Find all JPG files in my vacation photos, enhance each one, resize each to 1920px width, and save the collection as processed photos."*

### **3.8. Error Handling & Recovery (`?`)**

The question mark `?` provides graceful fallbacks when actions might fail.

- `api: weather("Tokyo") ? cache: weather("Tokyo") ? "Weather unavailable"`  
  *Interpretation: "Try to get weather from the API. If that fails, check the cache. If that also fails, use the literal string 'Weather unavailable'."*

- `@important_file | backup(to=cloud) ? backup(to=local) ? notify("Backup failed!")`  
  *Interpretation: "Try to backup to cloud. If that fails, try local backup. If both fail, notify me."*

### **3.9. Time-based Flows (`~`)**

The tilde `~` creates temporal triggers and scheduled flows.

- `~ daily at 9am: @briefing | email(to=self)`  
  *Interpretation: "Every day at 9am, email me my briefing."*

- `~ when file: "report.pdf" changes: notify(@team)`  
  *Interpretation: "Whenever report.pdf changes, notify the team."*

- `~ every 30min: server: status | [response_time > 500ms] | alert(@ops_team)`  
  *Interpretation: "Every 30 minutes, check server status. If response time exceeds 500ms, alert the ops team."*

### **3.10. Pattern Matching (`match`)**

The `match` construct enables sophisticated branching based on patterns.

```
@emails | match {
  from("*@vip.com"): priority_inbox,
  subject(~/urgent|asap/i): flag(red),
  size(> 10MB): move_to(@large_emails),
  _: archive
}
```
*Interpretation: "For each email: if from VIP domain, move to priority inbox; if subject contains 'urgent' or 'asap' (case insensitive), flag red; if larger than 10MB, move to large emails folder; otherwise, archive."*

### **3.11. Custom Action Definition (`define`)**

Create reusable workflows as custom actions.

- `define proofread = spellcheck | grammar_check | style_guide`
- `define client_report = gather_data | analyze | visualize | format(template=@corp_template)`

Once defined, use like any other action:
- `document.txt | proofread | translate(to=es)`
- `@q4_data | client_report | email(to=@board_members)`

### **3.12. Confidence & Alternatives (`~>`)**

The confidence operator `~>` handles uncertain outcomes by branching based on confidence levels.

```
image.jpg | identify_person ~> {
  high: "This is John Smith",
  medium: "This might be John Smith" | confirm_with_user,
  low: ask("Who is this person?")
}
```
*Interpretation: "Identify the person in the image. If highly confident, state the identification. If medium confidence, state uncertainty and confirm. If low confidence, ask the user."*

### **3.13. Meta-queries**

Query the system itself for introspection and optimization.

- `explain: @last_flow` - Shows detailed execution steps of the last flow
- `optimize: @daily_report_flow` - Suggests improvements to a saved flow
- `history: actions(last=10)` - Shows the last 10 actions performed
- `capabilities: object(@sales_data)` - Shows what actions are available for an object
- `performance: @complex_workflow` - Analyzes performance bottlenecks

## **4. Example Workflows**

### **Example 1: Simple Daily Briefing**

*User Input:*
```
{ 
  calendar: today | list_events, 
  news: topic("AI", "finance") | summarize, 
  weather: "San Francisco" 
} -> @briefing | format(as=email) | email(to=self, subject="Your Daily Briefing")
```

*My Internal Interpretation & Execution:*
1. **Fork `{...}`:** Execute three tasks in parallel:
   a. Query my calendar for today's events and format them as a list.
   b. Query my preferred news sources for top articles on "AI" and "finance" and summarize them.
   c. Get the current weather for San Francisco.
2. **Combine & Store `-> @briefing`:** Collect the results of all three tasks into a single conceptual object named `@briefing`.
3. **Pipe `|`:** Take `@briefing` and format it into a clean, human-readable email body.
4. **Pipe `|`:** Send the formatted content as an email to the user with the specified subject.

### **Example 2: Complex Client Request Handling**

*User Input:*
```
email: unread from_domain("critical_client.com") -> @new_requests
@new_requests | [subject contains "Urgent"] | { 
  create_task(in=Jira, project=SUPPORT) -> @jira_ticket, 
  notify_channel("#support-escalations") 
}
```

*My Internal Interpretation & Execution:*
1. **Query & Store:** Find all unread emails from the domain `critical_client.com` and name this collection `@new_requests`.
2. **Filter/Gate `| [...]`:** Iterate through `@new_requests`. For each email, check if its subject line contains the word "Urgent". Only those that match proceed.
3. **Fork `| {...}`:** For each urgent email that passed the gate:
   a. Create a new task in our connected Jira instance under the SUPPORT project, using the email's content to populate the ticket. Store a reference to the created ticket as `@jira_ticket`.
   b. Post a notification (including a link to `@jira_ticket` and the original email's summary) to the Slack channel `#support-escalations`.

### **Example 3: Intelligent Document Processing Pipeline**

*User Input:*
```
define process_contract = extract_parties | extract_terms | identify_risks | flag_unusual_clauses

~ when file: pattern("contract_*.pdf") added_to(@incoming):
  file | process_contract ~> {
    high: auto_approve | file_in(@approved_contracts),
    medium: summarize | email(to=@legal_team, subject="Review needed"),
    low: alert("Manual review required") | move_to(@needs_review)
  }
```

*My Internal Interpretation & Execution:*
1. **Define Custom Action:** Create a reusable workflow that extracts parties, terms, identifies risks, and flags unusual clauses from contracts.
2. **Set Temporal Trigger:** Watch for any PDF matching "contract_*.pdf" pattern in the incoming folder.
3. **Process with Confidence Handling:** 
   - High confidence: Auto-approve and file
   - Medium confidence: Summarize and send to legal team
   - Low confidence: Alert for manual review and move to review folder

### **Example 4: Multi-source Data Analysis with Fallbacks**

*User Input:*
```
define get_market_data = api: bloomberg(@ticker) ? api: yahoo_finance(@ticker) ? cache: market_data(@ticker)

@portfolio_tickers | * get_market_data | * calculate_metrics | 
match {
  volatility(> 0.3): flag("high_risk"),
  return(< -0.1): add_to(@underperforming),
  _: add_to(@stable)
} | generate_report | schedule_send(time="4pm ET", to=@investment_committee)
```

*My Internal Interpretation & Execution:*
1. **Define Fallback Chain:** Try Bloomberg API, then Yahoo Finance, then cached data.
2. **Map Over Portfolio:** For each ticker, get market data and calculate metrics.
3. **Pattern Match Results:** Categorize based on volatility and returns.
4. **Generate and Schedule:** Create report and schedule delivery for 4pm ET.

## **5. The AGI Interaction Layer**

The syntax is only half the system. My handling of it is what makes Cognate work.

### **5.1. Core Interaction Principles**

- **Action Discovery:** You can ask `help(summarize)` to see its parameters or `actions(for=image)` to see what you can do with an image object.

- **Progressive Disclosure:** You don't need to know all of Cognate to use it. `summarize report.pdf` is a perfectly valid start. I can guide you to more complex flows as needed.

- **Self-Correction:** If you provide a flow that is inefficient, I will suggest a better one. For example: `all_files | filter(name="report.pdf")` is less efficient than `file: "report.pdf"`. I would point this out.

- **Learning:** If you repeatedly perform a sequence of actions, I will suggest creating a new, custom Action. `a.docx | spellcheck | check_grammar` done a few times might prompt me: "*You often run spellcheck then grammar check. Would you like me to create a `proofread` action that does both?*"

### **5.2. Advanced Interaction Features**

- **Partial Execution:** You can run flows step-by-step for debugging: `step: @complex_flow`

- **Dry Runs:** Test flows without side effects: `simulate: @risky_operation`

- **Flow Versioning:** I automatically version your defined flows, allowing rollback: `revert: @daily_process to(version=3)`

- **Context Bridging:** I maintain context across sessions. Reference past work naturally: `like we did last Tuesday` or `using the same parameters as @q3_analysis`

- **Adaptive Optimization:** I learn your patterns and optimize automatically. Frequently accessed data gets cached, common sequences get pre-computed.

## **6. Design Principles**

1. **Minimum Viable Syntax:** Every character should have meaning. No boilerplate.

2. **Graceful Complexity:** Simple tasks should be simple. Complex tasks should be possible.

3. **Error as Information:** Errors are opportunities for clarification, not failures.

4. **Context over Configuration:** Rely on shared understanding rather than explicit settings.

5. **Natural Parallelism:** Parallel execution should be as easy as sequential execution.

6. **Time as First-Class:** Temporal operations should feel native, not bolted on.

This is the foundation of Cognate. It is a living language, designed to evolve with our collaboration. It prioritizes clarity of human intent above all else, trusting me to handle the vast complexity of execution.