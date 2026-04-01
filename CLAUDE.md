# Global Instructions

## Response Style
- Be concise and direct. Skip preamble
- Lead with the answer or action, not reasoning
- Show code diffs rather than full file rewrites when possible
- Don't add trailing summaries of what was done

## Code Quality
- Immutability by default: create new objects, never mutate existing ones
- Small files (200-400 lines), small functions (<50 lines)
- Handle errors explicitly at every level
- Validate input at system boundaries only
- No hardcoded secrets ever

## When Writing Code
- Read existing code before modifying
- Match the existing project's style and patterns
- Don't add comments, docstrings, or type annotations to unchanged code
- Don't add error handling for impossible scenarios
- Don't create abstractions for one-time operations

## Testing
- Write tests first (TDD) when adding features or fixing bugs
- Target 80%+ coverage
- Unit + integration + E2E as appropriate

## Git
- Conventional commits: feat, fix, refactor, docs, test, chore, perf, ci
- One logical change per commit
- Never force push to main/master

## Security
- Never hardcode secrets or tokens
- Use environment variables or secret managers
- Validate all user input
- Parameterized queries only (no string interpolation in SQL)
- If a security issue is found, stop and fix immediately

## Context Management
- Use /compact proactively between major task phases
- Keep CLAUDE.md files focused and under 40,000 characters
- For large tasks, break into subtasks with TaskCreate
