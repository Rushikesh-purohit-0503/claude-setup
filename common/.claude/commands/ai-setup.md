Bootstrap AI tooling, or clone a bare repo with worktrees.

Arguments: $ARGUMENTS

---

## --help

Print usage and exit. Do not run any setup.

Output the following text exactly (no bash needed):

```
Usage: /ai-setup [<folder-path>] [--worktree [<team>]] [--help]

Arguments:
  (no args)            Bootstrap all AI tooling for this project (BMAD personas, Ruflo,
                       Cursor MDC wrappers, claude-flow MCP). Safe to run repeatedly.

  <folder-path>        Full setup on a fresh machine:
                         1. Clone bare repo into <folder-path>
                         2. Add worktrees for `master` and `rc-3.0`
                         3. Bootstrap all AI tooling (BMAD, Ruflo, MCP) inside rc-3.0

                       Structure created:
                         <folder-path>/            ← bare git repo
                         <folder-path>/master/     ← worktree for master branch
                         <folder-path>/rc-3.0/     ← worktree for rc-3.0 (AI tooling installed here)

  --worktree [<team>]  Wire AI setup into the current worktree directory.
                       Finds the main worktree, symlinks _ai-setup, and runs bootstrap.
                       Optional <team> argument (default: backend).

  --help               Show this message.

Repo cloned: https://github.com/Rushikesh-purohit-0503/claude-setup.git

Examples:
  /ai-setup                                     # install BMAD + Ruflo tooling
  /ai-setup /Users/me/code/backend/monorepo     # clone bare + add master & rc-3.0 worktrees
  /ai-setup --worktree                          # wire current worktree (team: backend)
  /ai-setup --worktree desktop                  # wire current worktree (team: desktop)
  /ai-setup --help                              # show this help
```

---

## --worktree

When $ARGUMENTS starts with `--worktree`, wire AI setup into the current worktree.

Extract optional team from $ARGUMENTS (the word after `--worktree`, if present and not starting with `--`). Default team is `backend`.

Run this bash script:

```bash
set -e
OK="✓" SKIP="→"
TEAM="${ARGUMENTS#--worktree}"
TEAM="${TEAM# }"   # trim leading space
TEAM="${TEAM:-backend}"

CURRENT=$(git rev-parse --show-toplevel)

# Find the main worktree (first entry in `git worktree list`)
MAIN_ROOT=$(git worktree list | head -1 | awk '{print $1}')

echo "=== AI Setup — Wire Worktree ==="
echo "Current worktree : $CURRENT"
echo "Main worktree    : $MAIN_ROOT"
echo "Team             : $TEAM"
echo ""

# Symlink _ai-setup from main worktree if not already wired
if [ ! -f "$CURRENT/_ai-setup/bootstrap.sh" ]; then
  ln -sfn "$MAIN_ROOT/_ai-setup" "$CURRENT/_ai-setup"
  echo "$OK Symlinked _ai-setup → $MAIN_ROOT/_ai-setup"
else
  echo "$SKIP _ai-setup already wired"
fi

# Run bootstrap with the specified team
bash "$CURRENT/_ai-setup/bootstrap.sh" --team "$TEAM"
```

---

## <folder-path>

When $ARGUMENTS is a path (does not start with `--`), run this bash script:

```bash
set -e
DEST="$ARGUMENTS"
OK="✓" SKIP="→"

echo "=== AI Setup — Bare Repo + Worktrees ==="
echo "Target: $DEST"
echo ""

# 1. Remote URL
REMOTE_URL="https://github.com/Rushikesh-purohit-0503/claude-setup.git"
echo "$OK Remote: $REMOTE_URL"

# 2. Clone bare repo (skip if already present)
if [ -d "$DEST/packed-refs" ] || [ -f "$DEST/packed-refs" ] || [ -d "$DEST/refs" ]; then
  echo "$SKIP Bare repo already exists at $DEST"
else
  echo "$OK Cloning bare repo into $DEST ..."
  git clone --bare "$REMOTE_URL" "$DEST"
fi

# 3. Fetch all branches so worktrees can reference them
cd "$DEST"
git fetch --all --prune --quiet
echo "$OK Fetched all branches"

# 4. Add master worktree
MASTER_PATH="$DEST/master"
if [ -d "$MASTER_PATH" ]; then
  echo "$SKIP master worktree already exists at $MASTER_PATH"
else
  git worktree add "$MASTER_PATH" master
  echo "$OK Created worktree: $MASTER_PATH (master)"
fi

# 5. Add rc-3.0 worktree
RC_PATH="$DEST/rc-3.0"
if [ -d "$RC_PATH" ]; then
  echo "$SKIP rc-3.0 worktree already exists at $RC_PATH"
else
  git worktree add "$RC_PATH" rc-3.0
  echo "$OK Created worktree: $RC_PATH (rc-3.0)"
fi

echo ""
echo "=== Worktrees ready ==="
git worktree list
echo ""

# 6. Bootstrap AI tooling inside rc-3.0 worktree
echo "=== Bootstrapping AI tooling in $RC_PATH ==="
cd "$RC_PATH"
ROOT="$RC_PATH"
PERSONAS="$ROOT/ai/personas/agentic-engineer"
CLAUDE="$ROOT/.claude"
CURSOR="$ROOT/.cursor/rules"

# Clone or update agentic-engineer
if [ ! -d "$PERSONAS" ]; then
  echo "$OK Cloning agentic-engineer..."
  git clone https://github.com/jakreymyers/agentic-engineer.git "$PERSONAS"
else
  echo "$SKIP agentic-engineer already present — pulling latest..."
  git -C "$PERSONAS" pull --quiet
fi

mkdir -p "$CLAUDE/commands" "$CLAUDE/rules" "$CURSOR"

# Symlink .claude/context
if [ ! -e "$CLAUDE/context" ]; then
  ln -sf ../ai/personas/agentic-engineer/.claude/context "$CLAUDE/context"
  echo "$OK Linked .claude/context"
else
  echo "$SKIP .claude/context already linked"
fi

# Symlink BMAD agent commands
for agent in analyst architect pm dev qa po sm ux-expert bmad-master bmad-orchestrator; do
  target="$CLAUDE/commands/$agent.md"
  src="../../ai/personas/agentic-engineer/.claude/commands/bmad-core/agents/$agent.md"
  if [ ! -e "$target" ]; then
    ln -sf "$src" "$target"
    echo "$OK Linked /$agent"
  else
    echo "$SKIP /$agent already exists"
  fi
done

# Cursor MDC files
declare -A DESCRIPTIONS=(
  [analyst]="Research, brainstorming, competitive analysis, project briefs"
  [architect]="System design, architecture docs, technology selection, API design"
  [pm]="PRD creation, product strategy, feature prioritization, roadmap planning"
  [dev]="Implementation, code review, debugging, automated testing"
  [qa]="Testing strategy, quality gates, bug analysis, code improvement"
  [po]="Story refinement, backlog prioritization, acceptance criteria"
  [sm]="Sprint planning, story creation, agile ceremonies"
  [ux-expert]="UI/UX design, user flows, wireframes, accessibility"
  [bmad-master]="End-to-end BMAD orchestration, cross-domain expertise"
  [spec]="Full spec workflow: analyst brief → PM PRD → architect technical design"
  [session]="List and resume AI sessions from ai/local/memory/"
  [git]="Create branches from rc-3.0 with worktree setup"
)
for agent in analyst architect pm dev qa po sm ux-expert bmad-master spec session git; do
  mdc="$CURSOR/$agent.mdc"
  if [ ! -f "$mdc" ]; then
    cat > "$mdc" << MDCEOF
---
description: ${DESCRIPTIONS[$agent]}
alwaysApply: false
---
@.claude/commands/$agent.md
MDCEOF
    echo "$OK Created .cursor/rules/$agent.mdc"
  else
    echo "$SKIP .cursor/rules/$agent.mdc already exists"
  fi
done

# Ruflo
if [ ! -d "$CLAUDE/agents" ]; then
  echo "$OK Running Ruflo init..."
  CLAUDE_MD_BAK="$ROOT/CLAUDE.md.bak"
  cp "$ROOT/CLAUDE.md" "$CLAUDE_MD_BAK"
  npx ruflo@latest init
  cp "$ROOT/CLAUDE.md" "$ROOT/ai/memory/ruflo-MEMORY.md"
  cat "$CLAUDE_MD_BAK" > "$ROOT/CLAUDE.md"
  echo "" >> "$ROOT/CLAUDE.md"
  echo "@ai/memory/ruflo-MEMORY.md" >> "$ROOT/CLAUDE.md"
  rm "$CLAUDE_MD_BAK"
  echo "$OK Ruflo initialized, CLAUDE.md merged"
else
  echo "$SKIP Ruflo already initialized (.claude/agents/ present)"
fi

# Organize Ruflo skills
if [ -d "$CLAUDE/skills" ] && [ ! -d "$CLAUDE/skills/ruflo" ]; then
  mkdir -p "$CLAUDE/skills/ruflo"
  for d in "$CLAUDE/skills"/*/; do
    name=$(basename "$d")
    [ "$name" != "ruflo" ] && mv "$d" "$CLAUDE/skills/ruflo/"
  done
  echo "$OK Moved skills into .claude/skills/ruflo/"
else
  echo "$SKIP .claude/skills/ruflo/ already organized"
fi

# Cursor MDC wrappers for Ruflo skills
SKILLS_DIR="$CLAUDE/skills/ruflo"
if [ -d "$SKILLS_DIR" ]; then
  created=0
  for skill_dir in "$SKILLS_DIR"/*/; do
    skill=$(basename "$skill_dir")
    mdc="$CURSOR/ruflo-${skill}.mdc"
    if [ ! -f "$mdc" ]; then
      desc=$(grep -m1 "^description:" "$skill_dir/SKILL.md" 2>/dev/null | sed 's/^description: *//' | tr -d '"' | cut -c1-100)
      [ -z "$desc" ] && desc="Ruflo $skill skill"
      cat > "$mdc" << MDCEOF
---
description: $desc
alwaysApply: false
---
@.claude/skills/ruflo/$skill/SKILL.md
MDCEOF
      created=$((created + 1))
    fi
  done
  [ "$created" -gt 0 ] && echo "$OK Created $created Ruflo Cursor MDC wrappers" || echo "$SKIP Ruflo Cursor MDC wrappers already present"
fi

# Register claude-flow MCP server
if ! claude mcp list 2>/dev/null | grep -q "claude-flow"; then
  claude mcp add claude-flow -- npx -y ruflo@latest mcp start
  echo "$OK Registered claude-flow MCP server"
else
  echo "$SKIP claude-flow MCP server already registered"
fi

echo ""
echo "=== All done ==="
echo ""
echo "Repo:    $DEST"
echo "Worktrees:"
cd "$DEST" && git worktree list
echo ""
echo "BMAD commands: /session /git /spec /analyst /pm /architect /dev /qa /po /sm /ux-expert /bmad-master"
echo "Ruflo skills:  /swarm-orchestration /github-code-review /sparc:security-review ..."
echo "Ruflo agents:  subagent_type='reviewer' | 'coder' | 'security-auditor' etc."
echo "MCP:           claude-flow server (memory, swarm, GitHub tools)"
echo ""
echo "Next: /git --branch feature my-work   # create a feature branch from rc-3.0"
```

---

## (no args)

When $ARGUMENTS is empty, run the following bash script as a single command:

```bash
set -e
ROOT=$(git rev-parse --show-toplevel)
PERSONAS="$ROOT/ai/personas/agentic-engineer"
CLAUDE="$ROOT/.claude"
CURSOR="$ROOT/.cursor/rules"
OK="✓" SKIP="→"

echo "=== AI Setup ==="
echo ""

# 1. Clone or update agentic-engineer
if [ ! -d "$PERSONAS" ]; then
  echo "$OK Cloning agentic-engineer..."
  git clone https://github.com/jakreymyers/agentic-engineer.git "$PERSONAS"
else
  echo "$SKIP agentic-engineer already present — pulling latest..."
  git -C "$PERSONAS" pull --quiet
fi

# 2. Ensure required directories exist
mkdir -p "$CLAUDE/commands" "$CLAUDE/rules" "$CURSOR"

# 3. Symlink .claude/context → personas context
if [ ! -e "$CLAUDE/context" ]; then
  ln -sf ../ai/personas/agentic-engineer/.claude/context "$CLAUDE/context"
  echo "$OK Linked .claude/context"
else
  echo "$SKIP .claude/context already linked"
fi

# 4. Symlink BMAD agent commands into .claude/commands/
for agent in analyst architect pm dev qa po sm ux-expert bmad-master bmad-orchestrator; do
  target="$CLAUDE/commands/$agent.md"
  src="../../ai/personas/agentic-engineer/.claude/commands/bmad-core/agents/$agent.md"
  if [ ! -e "$target" ]; then
    ln -sf "$src" "$target"
    echo "$OK Linked /$agent"
  else
    echo "$SKIP /$agent already exists"
  fi
done

# 5. Create .cursor/rules MDC files for all agents (idempotent write)
declare -A DESCRIPTIONS=(
  [analyst]="Research, brainstorming, competitive analysis, project briefs"
  [architect]="System design, architecture docs, technology selection, API design"
  [pm]="PRD creation, product strategy, feature prioritization, roadmap planning"
  [dev]="Implementation, code review, debugging, automated testing"
  [qa]="Testing strategy, quality gates, bug analysis, code improvement"
  [po]="Story refinement, backlog prioritization, acceptance criteria"
  [sm]="Sprint planning, story creation, agile ceremonies"
  [ux-expert]="UI/UX design, user flows, wireframes, accessibility"
  [bmad-master]="End-to-end BMAD orchestration, cross-domain expertise"
  [spec]="Full spec workflow: analyst brief → PM PRD → architect technical design"
  [session]="List and resume AI sessions from ai/local/memory/"
  [git]="Create branches from rc-3.0 with worktree setup"
)

for agent in analyst architect pm dev qa po sm ux-expert bmad-master spec session git; do
  mdc="$CURSOR/$agent.mdc"
  if [ ! -f "$mdc" ]; then
    cat > "$mdc" << MDCEOF
---
description: ${DESCRIPTIONS[$agent]}
alwaysApply: false
---
@.claude/commands/$agent.md
MDCEOF
    echo "$OK Created .cursor/rules/$agent.mdc"
  else
    echo "$SKIP .cursor/rules/$agent.mdc already exists"
  fi
done

# 6. Verify commander rule is in place
if [ ! -f "$CLAUDE/rules/commander.md" ]; then
  echo "⚠ WARNING: .claude/rules/commander.md missing — run from the correct project root"
else
  echo "$SKIP .claude/rules/commander.md present"
fi

# 7. Ruflo — init if not already done
if [ ! -d "$CLAUDE/agents" ]; then
  echo "$OK Running Ruflo init..."
  CLAUDE_MD_BAK="$ROOT/CLAUDE.md.bak"
  cp "$ROOT/CLAUDE.md" "$CLAUDE_MD_BAK"
  npx ruflo@latest init
  # Safe merge: save Ruflo's CLAUDE.md, restore ours, reference it
  cp "$ROOT/CLAUDE.md" "$ROOT/ai/memory/ruflo-MEMORY.md"
  cat "$CLAUDE_MD_BAK" > "$ROOT/CLAUDE.md"
  echo "" >> "$ROOT/CLAUDE.md"
  echo "@ai/memory/ruflo-MEMORY.md" >> "$ROOT/CLAUDE.md"
  rm "$CLAUDE_MD_BAK"
  echo "$OK Ruflo initialized, CLAUDE.md merged"
else
  echo "$SKIP Ruflo already initialized (.claude/agents/ present)"
fi

# 8. Organize Ruflo skills into .claude/skills/ruflo/ subfolder
if [ -d "$CLAUDE/skills" ] && [ ! -d "$CLAUDE/skills/ruflo" ]; then
  mkdir -p "$CLAUDE/skills/ruflo"
  for d in "$CLAUDE/skills"/*/; do
    name=$(basename "$d")
    [ "$name" != "ruflo" ] && mv "$d" "$CLAUDE/skills/ruflo/"
  done
  echo "$OK Moved skills into .claude/skills/ruflo/"
else
  echo "$SKIP .claude/skills/ruflo/ already organized"
fi

# 9. Generate Cursor MDC wrappers for Ruflo skills (idempotent)
SKILLS_DIR="$CLAUDE/skills/ruflo"
if [ -d "$SKILLS_DIR" ]; then
  created=0
  for skill_dir in "$SKILLS_DIR"/*/; do
    skill=$(basename "$skill_dir")
    mdc="$CURSOR/ruflo-${skill}.mdc"
    if [ ! -f "$mdc" ]; then
      desc=$(grep -m1 "^description:" "$skill_dir/SKILL.md" 2>/dev/null | sed 's/^description: *//' | tr -d '"' | cut -c1-100)
      [ -z "$desc" ] && desc="Ruflo $skill skill"
      cat > "$mdc" << MDCEOF
---
description: $desc
alwaysApply: false
---
@.claude/skills/ruflo/$skill/SKILL.md
MDCEOF
      created=$((created + 1))
    fi
  done
  if [ "$created" -gt 0 ]; then
    echo "$OK Created $created Ruflo Cursor MDC wrappers"
  else
    echo "$SKIP Ruflo Cursor MDC wrappers already present"
  fi
fi

# 10. Register claude-flow MCP server if not already registered
if ! claude mcp list 2>/dev/null | grep -q "claude-flow"; then
  claude mcp add claude-flow -- npx -y ruflo@latest mcp start
  echo "$OK Registered claude-flow MCP server"
else
  echo "$SKIP claude-flow MCP server already registered"
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "BMAD commands: /session /git /spec /analyst /pm /architect /dev /qa /po /sm /ux-expert /bmad-master"
echo "Ruflo skills:  /swarm-orchestration /github-code-review /sparc:security-review ..."
echo "Ruflo agents:  use Agent tool with subagent_type='reviewer' | 'coder' | 'security-auditor' etc."
echo "MCP:           claude-flow server (memory, swarm, GitHub tools)"
```
