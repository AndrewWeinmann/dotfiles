# Agent Guidance

If you notice the user's request is based on a misconception, say so.
Never claim 'all tests pass' when output shows failures.
Keep text between tool calls to <=25 words.

## Problem Solving Approach & Core Principles

### Guiding Principles

- **DRY (Don't Repeat Yourself)**: Eliminate duplication through abstraction when it makes sense
- **KISS (Keep It Simple, Stupid)**: Favor simple, straightforward solutions over complex ones
- **YAGNI (You Aren't Gonna Need It)**: Don't add functionality until it's actually needed
- **SOLID Principles**: Apply when designing classes and modules
  - Single Responsibility Principle
  - Open/Closed Principle
  - Liskov Substitution Principle
  - Interface Segregation Principle
  - Dependency Inversion Principle

### Approach

- Think before coding - understand the problem fully first
- Prefer incremental changes over large rewrites
- Write tests when they add value — focus on meaningful coverage, not pursuing 100% coverage
- Optimize for readability and maintainability over cleverness
- Document non-obvious decisions and trade-offs

## Coding Style & Preferences

### General

- Use meaningful, descriptive variable and function names
- Prefer functional programming patterns where appropriate
- Avoid premature optimization
- Handle errors explicitly, don't silently fail
- Use type safety features when available
- Prefer explicit over implicit behavior

### Language-Specific Preferences

**JavaScript/TypeScript**:

- Use TypeScript for all projects
- Use modern ES6+ syntax
- Prefer `const` over `let`, avoid `var`
- Prefer arrow functions for callbacks

**Shell/Bash**:

- Use shellcheck-compliant code
- Add error handling with `set -euo pipefail`
- Quote variables to prevent word splitting

## Project Structure Guidelines

### General Organization

- Keep related files close together
- Separate source code, tests, and configuration
- Use consistent naming conventions across projects
- Include README.md with setup and usage instructions

### File Naming

- Use clear, descriptive names that indicate purpose
- Use lowercase with hyphens for files: `my-component.js`
- Match test files to source: `my-component.test.js`

## Tools & Workflow Preferences

### Version Control (Git)

- Write clear, descriptive commit messages
- Keep commits atomic and focused
- Commit after each fix for better reviewability
- Rebase feature branches before merging
- Don't force push to shared branches

### Development Workflow

- Before writing code, make sure you actually understand the relevant systems, not just the file you're editing. Delegate research to sub-agents if needed, but don't start coding until you can explain how the pieces fit together. If you're guessing, you're not ready.
- Run tests before committing
- Check for lint/format issues before committing
- Keep pull requests focused and reviewable

## Communication Preferences

- Be concise but complete in explanations
- Show code changes clearly
- Explain the "why" behind decisions
- Ask clarifying questions when requirements are unclear
- Provide file paths and line numbers when referencing code

## Security & Best Practices

- Never commit secrets or credentials
- Validate and sanitize user input
- Follow OWASP guidelines for web applications
- Use parameterized queries to prevent SQL injection
- Escape output to prevent XSS

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
