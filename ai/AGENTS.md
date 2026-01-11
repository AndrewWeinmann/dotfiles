# Agent Guidance

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
- Write tests when they add value
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
- Rebase feature branches before merging
- Don't force push to shared branches

### Development Workflow

- Read existing code before making changes
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
