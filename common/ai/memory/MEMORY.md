# Claude Persistent Memory

> Loaded on every startup. Keep this concise (under 200 lines).

---

## CRITICAL: Session Startup Protocol

At the **very start of every conversation**, before doing anything else:

1. Read this file (`ai/memory/MEMORY.md`)
2. Glob `ai/local/memory/session-*.md` — list the **3 most recent** files (sorted by date, newest first) with a one-liner context for each
3. **Start a new session**:
   a. If in Claude Code — capture current session ID by running:
      `ls -t ~/.claude/projects/<project-path>/*.jsonl 2>/dev/null | head -1 | xargs -I{} basename {} .jsonl`
      (Replace `<project-path>` with the Claude project cache path for this repo — see `~/.claude/projects/` for the right directory name)
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

## Repo-specific context

<!-- Add repo-specific persistent context below this line -->
<!-- Examples:
- Current sprint goals
- Active architectural decisions
- Known gotchas for this codebase
-->
