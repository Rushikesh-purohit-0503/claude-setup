# AI Command Authoring Guide

Commands in this project are shared across Claude Code CLI and Cursor.

## Structure

```
ai/commands/<name>.md         ← source of truth (git-tracked, edit here)
.claude/commands/<name>.md    ← copy for Claude Code CLI (keep in sync with ai/commands/)
.cursor/rules/<name>.mdc      ← Cursor slash command (references .claude/commands/<name>.md)
```

## Step 1 — Write the command: `ai/commands/<name>.md`

```markdown
<One-line description of what the command does>

Arguments: $ARGUMENTS

## --flag-one
[Instructions for this flag]

## --flag-two
[Instructions for this flag]
```

Rules:
- `$ARGUMENTS` is replaced with whatever the user types after the command name
- No YAML frontmatter — plain markdown only
- **Never use bash** — use Glob, Grep, and Read tools instead (zero confirmation prompts)
- Keep each `## --flag` section self-contained with explicit step-by-step instructions

## Step 2 — Copy to Claude Code CLI: `.claude/commands/<name>.md`

Copy the file content from `ai/commands/<name>.md` into `.claude/commands/<name>.md`.
Add this note at the top so the source is always traceable:

```markdown
> Source of truth: `ai/commands/<name>.md` — edit there, keep this file in sync.
```

## Step 3 — Add the Cursor counterpart: `.cursor/rules/<name>.mdc`

```
---
description: <one-line description>
alwaysApply: false
---
@.claude/commands/<name>.md
```

Use `alwaysApply: true` only for rules that must always be in context (like this file).
Use `alwaysApply: false` for on-demand slash commands.

---

## Existing Custom Commands

| Command | Source | Description |
|---------|--------|-------------|
| `/docs` | `ai/index/docs-index.md` | Index of all docs in `docs/` — on-demand only |

## Built-in Commands (managed elsewhere)

| Command | File | Description |
|---------|------|-------------|
| `/ai-setup` | `.claude/commands/ai-setup.md` | Bootstrap all AI tooling (idempotent) |
| `/persona` | `.claude/commands/persona.md` | `list` · `find <req>` · `add <name>` · `prompt [<topic>]` — manage personas and generate coding prompts |
| `/session` | `.claude/commands/session.md` | List and resume AI sessions |
| `/git` | `.claude/commands/git.md` | Create branches from rc-3.0 with worktree |
| `/spec` | `.claude/commands/spec.md` | Full spec workflow: analyst → PM PRD → architect design |

## BMAD Agent Personas (from `ai/personas/agentic-engineer`)

Symlinked into `.claude/commands/` — invoke directly as slash commands:

| Command | Persona | Use for |
|---------|---------|---------|
| `/analyst` | Analyst | Research, briefs, competitive analysis |
| `/pm` | Product Manager | PRDs, roadmaps, feature prioritization |
| `/architect` | Architect | System design, architecture docs, API design |
| `/dev` | Developer | Implementation, code review, debugging |
| `/qa` | QA Engineer | Testing strategy, quality gates |
| `/po` | Product Owner | Backlog, stories, acceptance criteria |
| `/sm` | Scrum Master | Sprint planning, agile ceremonies |
| `/ux-expert` | UX Expert | User flows, wireframes, accessibility |
| `/bmad-master` | BMAD Master | End-to-end orchestration |

Context files resolve from `.claude/context/` (symlinked to `ai/personas/agentic-engineer/.claude/context/`).
