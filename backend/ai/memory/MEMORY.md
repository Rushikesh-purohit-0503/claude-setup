# Claude Persistent Memory — Vyapar Backend

> Loaded on every startup. Keep this concise (under 200 lines).

---

## CRITICAL: Session Startup Protocol

At the **very start of every conversation**, before doing anything else:

1. Read this file (`ai/memory/MEMORY.md`)
2. Glob `ai/local/memory/session-*.md` — list the **3 most recent** files (sorted by date, newest first) with a one-liner context for each
3. **Start a new session**:
   a. If in Claude Code — capture current session ID by running:
      `ls -t ~/.claude/projects/<project-dir>/*.jsonl 2>/dev/null | head -1 | xargs -I{} basename {} .jsonl`
      (Replace `<project-dir>` with the hashed project path — check `~/.claude/projects/` for the right directory name)
   b. Create `ai/local/memory/session-YYYY-MM-DD_HH-MM.md` with frontmatter at the very top:
      ```
      ---
      claude-session-id: <uuid-from-step-a, or "cursor-session" if in Cursor>
      date: YYYY-MM-DD HH:MM
      branch: <current-branch>
      ---
      ```
4. To resume a past session → run `/session --resume`
5. Never ask the user whether to resume or start new — just show the list and proceed with a new session

---

## Memory Layout

| Path | Purpose | Git-tracked |
|------|---------|-------------|
| `ai/memory/MEMORY.md` | This file — persistent cross-session memory | Yes |
| `ai/memory/<context>-MEMORY.md` | Published topic memory (e.g. `auth-MEMORY.md`) | Yes |
| `ai/local/memory/session-*.md` | Per-session logs, auto-updated | No (gitignored) |
| `ai/local/notes/` | On-demand notes | No |
| `ai/local/todo/` | On-demand todos | No |

---

## Backend Monorepo Context

- **Package manager**: pnpm 9.14.4 with Lerna 8.1.2
- **Runtime**: Node.js >= 20.14.11, TypeScript 5.6.2
- **~120 packages** in `packages/` — check `ai/index/codebase-index.md` for full list
- **Dependency tiers**: Foundation → Core Utils → Database → Service → Business → Apps
  - Never add a higher-tier package as a dependency of a lower-tier one
- **Credential pattern**: Always use `@vyapar/credentials_manager` (AWS SSM) — never hardcode secrets
- **Logger pattern**: Always use `@vyapar/logger`, never `console.log` in production code

## Before Coding

Always require the user to specify a target package. See `.claude/rules/coding.md`.
Read `ai/index/packages/<name>.md` for the relevant package before touching any code.
