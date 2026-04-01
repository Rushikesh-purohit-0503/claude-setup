# Claude Code Rules

## Documentation Rule (MANDATORY)

**Every AI related installation, configuration change, architectural decision, or new tool introduced in this branch MUST be recorded in `ai/docs/ai-dev-setup.md`.**

Before finishing any task that involves:
- Installing a new tool, package, or dependency
- Changing configuration files
- Setting up infrastructure or services
- Making an architectural decision

...update `ai/docs/ai-dev-setup.md` with:
1. What was done
2. Why (brief rationale)
3. Relevant links (install pages, official docs, blog posts)
4. Commands used (if any)

## Session Memory

> Session startup protocol and memory layout are defined in `ai/memory/MEMORY.md`.

**Auto-save session memory continuously throughout the session.**

## Private Local Workspace

`ai/local/` is gitignored and **never pushed to repo**. Use it for:
- `memory/session-YYYY-MM-DD_HH-MM.md` — per-session logs
- `notes/` — on-demand notes
- `todo/` — on-demand todos
- Scratch files, drafts, personal context

## Published Memory

`ai/memory/` is tracked by git. Only put context here when explicitly asked to publish/share memory.
- File naming: `<context>-MEMORY.md` (e.g. `auth-MEMORY.md`, `db-MEMORY.md`)
