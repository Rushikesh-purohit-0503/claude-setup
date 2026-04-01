Manage AI personas — discover and add personas from the library.

Arguments: $ARGUMENTS

---

## list

Read `.claude/personas-registry.md` using the Read tool and output its contents.

---

## find <requirement>

Find relevant personas for a given requirement or task description.

Steps (no bash — use file tools only):
1. Use Glob to list all active BMAD personas: `.claude/commands/*.md`
2. Use Grep to extract `description:` from frontmatter (pattern: `^description:`)
3. Use Glob to list available-but-not-linked BMAD personas:
   - `ai/personas/agentic-engineer/.claude/commands/bmad-core/agents/*.md`
   - `ai/personas/agentic-engineer/.claude/commands/content-creation/agents/*.md`
4. Use Grep to extract their `description:` values too
5. Use Glob to list all Ruflo agents: `.claude/agents/**/*.md`
6. Use Grep to extract `description:` and `name:` from each Ruflo agent file
7. Match all results against the requirement in $ARGUMENTS (semantic match — pick most relevant)
8. Output three sections:

```
BMAD Personas matching "<requirement>":
  /name — description

Ruflo Agents matching "<requirement>":
  name (category) — description
  → invoke as Agent tool: subagent_type="<name>"

Available BMAD personas (not yet added):
  name — description  →  run: /persona add <name>
```

Always suggest the most relevant match first. Ruflo agents are invoked as subagents via the Agent tool (not slash commands).

---

## add <name>

Add a persona from the library into the active command set.

Steps:
1. Use Glob to find the persona file — search in order:
   - `ai/personas/agentic-engineer/.claude/commands/bmad-core/agents/<name>.md`
   - `ai/personas/agentic-engineer/.claude/commands/content-creation/agents/<name>.md`

2. If not found → tell the user the persona doesn't exist in the library and suggest `/persona find <requirement>` to discover available ones.

3. If found → run this bash to wire it up:
```bash
ROOT=$(git rev-parse --show-toplevel)
NAME="<name>"
SRC_PATH="<full path found in step 1>"
REL_SRC=$(python3 -c "import os; print(os.path.relpath('$SRC_PATH', '$ROOT/.claude/commands'))")

# Symlink into .claude/commands/
ln -sf "$REL_SRC" "$ROOT/.claude/commands/$NAME.md"
echo "✓ Linked .claude/commands/$NAME.md"

# Create .cursor/rules MDC
DESCRIPTION=$(grep -m1 '^description:' "$SRC_PATH" | sed 's/description: *//')
cat > "$ROOT/.cursor/rules/$NAME.mdc" << EOF
---
description: $DESCRIPTION
alwaysApply: false
---
@.claude/commands/$NAME.md
EOF
echo "✓ Created .cursor/rules/$NAME.mdc"
```

4. After bash completes, use the Edit tool to:
   - Append `N. /<name> — <description>` to `.claude/personas-registry.md` (increment N)
   - Add the persona to the **Existing Commands** table in `.claude/rules/commander.md`
   - Move the persona name out of the "not yet wired" list in `ai/docs/personas.md`

5. Confirm: `✓ /name is now active. Invoke with /name in Claude Code or Cursor.`
