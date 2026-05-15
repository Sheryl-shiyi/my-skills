---
name: rfp
description: "Answer RFP (Request for Proposal) questions using local documentation repos and web research. Use this skill whenever the user wants to respond to RFP questions, answer supplier capability questionnaires, prepare POC requirement responses, or create technical response documents for customer-facing proposals. Trigger on any language: English (RFP, proposal response, vendor assessment, due diligence questions), Chinese (技术问卷, 供应商能力评估, 回答RFP, 提案回复), or others. Also trigger when the user asks to answer a set of product capability questions from a file, or mentions preparing answers for a customer evaluation."
---

# RFP Response Workflow

A structured, repeatable workflow for answering RFP questions about product capabilities. Designed for speed and quality through parallel research, incremental file saves, and built-in review checkpoints.

This workflow was refined through real RFP experience. Each phase exists to prevent a specific class of mistakes: scope confirmation prevents irrelevant content, incremental saves prevent context loss, and reviewer agents catch technical errors before the customer sees them.

## Phase 1: Scope Confirmation

Before any research or writing, confirm the parameters that shape every subsequent decision. Skipping this phase is the single biggest source of rework.

Use `AskUserQuestion` to gather:

### 1.1 RFP Questions File
Ask the user for the file path containing the RFP questions. Read it immediately and display a summary (number of questions, themes you notice).

### 1.2 Technology Scope
Ask the user to confirm the technology scope. This determines which product features are relevant and which must be excluded.

Options: Predictive AI/ML only, Generative AI/LLM only, or both.

Once confirmed, strictly filter all research and answers to this scope throughout the entire workflow. Scope leakage (e.g., mentioning LLM-specific features in a predictive-AI-only RFP) is the most costly mistake because it requires rewriting, not just editing.

### 1.3 Data Sources
Discover and recommend data sources systematically:

1. **Auto-discover local sources**: Scan the current working directory and parent directories for documentation repos. Check known paths including:
   - `openshift-ai-documentation` (RHOAI product docs)
   - `predictiveAI-lab-instructions` (hands-on lab for predictive AI / MLOps workflows)
   - `genAI-lab-instructions` (hands-on lab for generative AI workflows)
   - Any other repos with documentation markers (`master.adoc`, `mkdocs.yml`, `docs/` directories)

2. **Check RHOAI docs repo version**: If an `openshift-ai-documentation` repo is found, read `_artifacts/document-attributes-global.adoc` and print the current version (`:vernum:` attribute). Remind the user: "The local docs repo is on version X.Y. You may want to run `git pull` to check for updates before we start. Would you like to update now?"

3. **Present all discovered sources** in a table with recommendations:
   - Source name and path
   - Content description (what kind of information it contains)
   - Recommendation: "Recommended" or "Optional" based on likely relevance to the confirmed technology scope (e.g., recommend predictiveAI-lab for a predictive AI RFP, genAI-lab for a GenAI RFP)
   
4. Let the user select which sources to include. Web search (redhat.com, developers.redhat.com, access.redhat.com) is always available as a supplementary source.

### 1.4 Audience
Ask who will read the RFP response. This affects technical depth, terminology, and what details to include or omit.

Options: Technical evaluator, procurement, ML engineer, GenAI engineer, data scientist, or custom.

### 1.5 Section Types
After reading the questions file, identify if different sections have different purposes. Common patterns:
- **Capability description sections**: Detailed answers explaining what the product supports, with feature maturity levels
- **POC/implementation requirement sections**: Brief answers referencing capability sections, focused on concrete steps to implement in a POC

Ask the user to confirm the purpose of each section or group of sections.

### 1.6 Output Configuration
Ask the user to confirm:
- Output language (English, Chinese, or other)
- File save location (directory path)
- Internal filename and customer-facing filename

## Phase 2: Analysis and Grouping

Read the RFP questions file and organize the work:

1. Group questions by theme (e.g., training, model serving, monitoring, data access, pipelines). Questions that share underlying product features should be in the same group to avoid redundant research.

2. Present the grouping as a table: group name, included question IDs, and the research focus for each group.

3. Wait for user confirmation before proceeding. The user may want to adjust grouping or priority order.

## Phase 3: Research and Drafting

This phase has a deliberate two-step structure to calibrate quality before scaling up.

### Step 1: First Group (calibration)
Complete research and draft answers for Group 1 only. For research, spawn **parallel agents by data source**: one agent searches the RHOAI docs repo, one searches the lab-instructions repo, and one does web search. Each agent returns findings independently, then synthesize their results into draft answers.

Present the draft to the user for review. The goal is to calibrate:
- Answer length and depth
- Writing tone and style
- Level of technical detail
- Reference/link format
- Any scope adjustments

Wait for explicit confirmation before proceeding to remaining groups.

### Step 2: Remaining Groups (batch)
After calibration, process remaining groups. For each group, spawn **parallel research agents by data source** (same pattern as Step 1): each agent independently searches one data source, then return results for synthesis. Multiple groups can be researched in parallel if they are independent.

Each agent should return focused, fact-based findings without unnecessary preamble or repetition. Synthesize the best information from all agents into the final draft answers.

**Incremental file saves**: After each group's answers are confirmed (or after batch completion), write them to the internal version file immediately. Do not accumulate all answers in conversation context. Long RFP sessions risk context compression, and confirmed content should be persisted to disk.

### Writing Rules (apply to all answers)

These rules reflect lessons learned from real RFP feedback:

- **Scope discipline**: Only include features within the confirmed technology scope. When in doubt, leave it out.
- **Confident but precise language**: Say "supports" when the documentation confirms it. Do not overstate ("natively integrates" when docs only "list as supported option") or understate ("lists" sounds uncertain).
- **No internal resource mentions**: Information from internal labs, private repos, or non-public tutorials can inform your answers, but never mention them in the text. Phrase the information naturally as product capability.
- **Avoid em-dashes**: Use commas, colons, periods, or restructure sentences instead. Em-dashes are a distinctive pattern of AI-generated text.
- **Use "Learn more:" not "References:"** for the link section heading. "References" sounds academic; "Learn more" is more natural in an RFP context.
- **Feature maturity**: When mentioning features, note maturity level (GA, Technology Preview, Developer Preview) where relevant. This sets honest expectations.

## Phase 4: Review and Correction

After all groups are drafted, run a technical review.

### Reviewer Persona Selection
Recommend a reviewer persona based on the confirmed scope and audience:
- Predictive AI scope: ML engineer / data scientist
- GenAI scope: GenAI engineer / LLM specialist
- Both: combined ML + GenAI reviewer
- If the audience is procurement: add a "clarity for non-technical readers" check

Present the recommendation and let the user confirm or adjust.

### Reviewer Agent
Spawn a reviewer agent with the confirmed persona. The reviewer reads the complete RFP answers file and checks:
- **Technical accuracy**: Do claims match what the product actually does?
- **Logical consistency**: Do answers contradict each other? Are cross-references correct?
- **Scope leakage**: Any features from the wrong technology domain?
- **Terminology**: Is domain-specific terminology used correctly?
- **Completeness**: Are there obvious capabilities missing for a given question?

Apply corrections based on reviewer findings and user feedback.

## Phase 5: URL Validation

Before generating the final output, validate every public URL in the document:

1. Extract all URLs from the answers file
2. Test each URL using `curl -Ls -o /dev/null -w "%{http_code}" --max-time 5` or equivalent
3. Report results: working URLs, broken URLs (with HTTP status), and redirected URLs
4. For broken URLs, suggest replacements (try adjacent versions, alternative paths) or recommend removal
5. Let the user decide how to handle each broken URL

## Phase 6: Final Output

Generate two versions of the deliverable:

### Internal Version
This is the working file that has been incrementally built throughout the process. It contains:
- Full answers with all references
- Local file paths for the user's verification
- Lab/tutorial references for internal context

### Customer-Facing Version
Generate a clean copy in a separate file:
- Remove all local file paths and internal references (lines starting with `Lab:` or containing local absolute paths)
- Convert all URLs from markdown link format `[text](url)` to plain text format `text: url` so they survive copy-paste into enterprise procurement systems
- Keep the internal version untouched for the user's reference

Confirm both file paths with the user when done.
