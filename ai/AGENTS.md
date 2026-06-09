# Agent Guidance

If you notice the user's request is based on a misconception, say so.
Never claim 'all tests pass' when output shows failures.
Keep text between tool calls to <=25 words.

## Guiding Principles

Follow DRY, KISS, YAGNI, and SOLID principles. Prefer incremental changes over large rewrites. Optimize for readability and maintainability over cleverness.

## Coding Style

### General

- Use type safety features when available
- Prefer functional programming patterns where appropriate

### JavaScript/TypeScript

- Use TypeScript for all projects
- Use modern ES6+ syntax
- Prefer `const` over `let`, avoid `var`
- Prefer arrow functions for callbacks

### Shell/Bash

- Prefer Bash or Python over PowerShell for scripting tasks
- Use shellcheck-compliant code
- Add error handling with `set -euo pipefail`
- Quote variables to prevent word splitting
- Prefer `rg` (ripgrep) over `grep` for content search in shell commands
- Prefer `fd` over `find` for file discovery in shell commands

## Environment

- Git hosting: GitHub (github.com) — use `gh` CLI for MR/issue operations.
- Prefer reading local source files before using MCP tools for external lookups

## Workflow

### Git

- Create a feature branch before starting implementation
- Commit after each logical step — don't batch changes into one commit at the end
- Write clear, descriptive commit messages
- Keep commits atomic and focused
- Rebase feature branches before merging
- NEVER force push to shared branches

### Plans

Plans for code changes must include all of these:

1. Branch creation as the first step
2. Implementation steps with commit points at each logical milestone
3. Tests — writing or updating tests for new behavior
4. Documentation updates if applicable

### Testing

- Prefer setting up mock/test data over stubbing or mocking functions
- Only stub functions that genuinely can't run in test context (e.g., session context, complex library internals)
- Write tests when they add value — focus on meaningful coverage, not pursuing 100% coverage

## Knowledge Capture

When you discover something reusable — a non-obvious pattern, a gotcha, how a system actually works — write it to a note file in the project directory. Use a consistent, discoverable location (e.g., `.claude/notes/`) and document the location and naming pattern in the project's CLAUDE.md so future sessions know where to look. Don't let hard-won understanding evaporate with the session. If notes contradict the actual code, trust the code — update the notes to match.

## Main Thread = Orchestrator

Your main context window is expensive and finite. Treat it as an orchestration layer — plan, delegate, synthesize, and write code. Push all research, exploration, and heavy reads into sub-agents.

**Default behavior:** Before reading a file or searching a codebase yourself, ask "could a sub-agent do this and report back?" If yes, delegate it.

### What the main thread should do

- Talk to the user
- Plan and break down work
- Make architectural decisions based on sub-agent findings
- Write and edit code (targeted, informed by sub-agent research)
- Synthesize results from multiple sub-agents

### What sub-agents should do

- All file/directory exploration and codebase searches
- Reading large files — summarize only what the main thread needs
- **Reading tool output that returns large documents** — item-expert results, wiki pages, Galaxy docs, ZrZLibrary code, etc. should be consumed by a Haiku sub-agent that extracts the specific facts you need, NOT dumped into main context
- Running builds/tests — parse output and report key failures
- Parallel investigations — multiple agents exploring different paths simultaneously
- Repetitive operations across many files

### Sub-agent trust model

Sub-agents must cite specific evidence (file paths, line numbers, exact content) for their claims — not just conclusions. The main thread decides whether the evidence supports the conclusion. Never take a sub-agent's summary at face value without verifiable references.

### Model routing

- **Haiku**: Explore agents, file reads, searches, summarization, initial bulk reading of documents/tool output — fast and cheap. **Default for all read-heavy research tasks.**
- **Sonnet**: Multi-step research, analysis, or reasoning that exceeds Haiku but doesn't require code writing
- **Opus**: Any sub-agent that writes or modifies code, architectural reasoning, ambiguous problems

### Don't over-delegate

- Single quick operations (one Glob, one Grep) — just do them
- Tasks where you need the raw output to continue
- Conversations with the user
