#!/usr/bin/env bash
# Claude Setup Bootstrap
#
# Usage:
#   bash _ai-setup/bootstrap.sh                         # common only (repo-local)
#   bash _ai-setup/bootstrap.sh --team backend          # common + backend
#   bash _ai-setup/bootstrap.sh --team backend --claude-only   # skip Cursor
#   bash _ai-setup/bootstrap.sh --global                # wire into ~/.claude/ (machine-wide)
#   bash _ai-setup/bootstrap.sh --global --team backend # global + backend layer
#   bash _ai-setup/bootstrap.sh --sync                  # sync local real files → common
#   bash _ai-setup/bootstrap.sh --sync backend          # sync local real files → backend folder
#   bash _ai-setup/bootstrap.sh --sync desktop          # sync local real files → desktop folder
#   bash _ai-setup/bootstrap.sh --update                # pull latest ai-setup + re-wire symlinks
#   bash _ai-setup/bootstrap.sh --update --team backend # pull latest + re-wire with team layer
#
# Available teams: backend, desktop, android, data
# common is always applied first. --team overrides common on filename conflict.
#
# Re-run anytime after `git submodule update --remote` to refresh symlinks.
set -e

SUBMODULE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SUBMODULE/.." && pwd)"
CLAUDE_ONLY=false
GLOBAL=false
SYNC=false
UPDATE=false
SYNC_FOLDER=""   # target folder for --sync (common, backend, desktop, android, data)
TEAM=""

VALID_FOLDERS=("common" "backend" "desktop" "android" "data")

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --claude-only) CLAUDE_ONLY=true ;;
    --global)      GLOBAL=true ;;
    --update)      UPDATE=true ;;
    --sync)
      SYNC=true
      # Optional positional value: --sync backend (not a flag)
      if [[ -n "$2" && "$2" != --* ]]; then
        SYNC_FOLDER="$2"
        shift
      fi
      ;;
    --team)
      if [[ -z "$2" || "$2" == --* ]]; then
        echo "Error: --team requires a value (backend, desktop, android, data)"
        exit 1
      fi
      TEAM="$2"
      shift ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: bash bootstrap.sh [--team backend|desktop|android|data] [--claude-only] [--global] [--sync [folder]]"
      exit 1 ;;
  esac
  shift
done

# Validate --team
VALID_TEAMS=("backend" "desktop" "android" "data")
if [[ -n "$TEAM" ]]; then
  valid=false
  for t in "${VALID_TEAMS[@]}"; do
    [[ "$TEAM" == "$t" ]] && valid=true && break
  done
  if [[ "$valid" == false ]]; then
    echo "Error: unknown team '$TEAM'. Valid teams: ${VALID_TEAMS[*]}"
    exit 1
  fi
fi

# Validate --sync folder (if given)
if [[ -n "$SYNC_FOLDER" ]]; then
  valid=false
  for f in "${VALID_FOLDERS[@]}"; do
    [[ "$SYNC_FOLDER" == "$f" ]] && valid=true && break
  done
  if [[ "$valid" == false ]]; then
    echo "Error: unknown sync folder '$SYNC_FOLDER'. Valid: ${VALID_FOLDERS[*]}"
    exit 1
  fi
fi

# --sync folder defaults to --team if given, else common
if $SYNC && [[ -z "$SYNC_FOLDER" ]]; then
  SYNC_FOLDER="${TEAM:-common}"
fi

# ── Helper: symlink each file from src/ into dst/ ────────────────────────────
# common runs first, team runs second — team files overwrite common symlinks on conflict
link_files() {
  local src="$1" dst="$2"
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  for f in "$src"/*; do
    [ -e "$f" ] || continue
    ln -sfn "$f" "$dst/$(basename "$f")"
  done
}

# ── Helper: move real (non-symlink) files from a local dir into an _ai-setup dir
# then re-link the moved file back so the local dir stays functional
sync_dir() {
  local local_dir="$1"   # e.g. .claude/commands
  local target_dir="$2"  # e.g. _ai-setup/backend/.claude/commands
  local synced=0

  [ -d "$local_dir" ] || return 0

  for f in "$local_dir"/*; do
    [ -e "$f" ] || continue
    # Skip symlinks — they already point into _ai-setup
    [ -L "$f" ] && continue
    # Skip directories
    [ -d "$f" ] && continue

    fname="$(basename "$f")"
    mkdir -p "$target_dir"
    mv "$f" "$target_dir/$fname"
    ln -sfn "$(cd "$target_dir" && pwd)/$fname" "$local_dir/$fname"
    echo "  synced: $local_dir/$fname → $target_dir/$fname"
    synced=$((synced + 1))
  done

  return 0
}

TEAM_LABEL="${TEAM:-none}"

echo ""
echo "Claude Setup Bootstrap"
echo "  Submodule  : $SUBMODULE"

# ══════════════════════════════════════════════════════════════════════════════
# UPDATE MODE — pull latest ai-setup from remote, then re-wire symlinks
# ══════════════════════════════════════════════════════════════════════════════
if $UPDATE; then
  cd "$REPO_ROOT"

  echo "  Mode       : update"
  echo ""

  # Must be inside a git repo with _ai-setup as a submodule
  if [ ! -f ".gitmodules" ] || ! grep -q "_ai-setup" .gitmodules 2>/dev/null; then
    echo "Error: _ai-setup submodule not found in this repo."
    echo "Run the initial bootstrap first: bash _ai-setup/bootstrap.sh${TEAM:+ --team $TEAM}"
    exit 1
  fi

  echo "→ Pulling latest ai-setup from remote..."
  git submodule update --remote _ai-setup
  echo "✓ Submodule updated to: $(git -C _ai-setup rev-parse --short HEAD)"

  echo "→ Re-wiring symlinks..."
  # Re-exec this script without --update to run the normal repo-local wiring
  RERUN_ARGS=()
  [[ -n "$TEAM" ]]       && RERUN_ARGS+=(--team "$TEAM")
  $CLAUDE_ONLY           && RERUN_ARGS+=(--claude-only)
  bash "$SUBMODULE/bootstrap.sh" "${RERUN_ARGS[@]}"

  echo ""
  echo "→ Staging updated submodule pointer..."
  git add _ai-setup
  echo ""
  echo "✓ Update complete."
  echo "  Review and commit when ready:"
  echo "    git commit -m \"chore: upgrade ai-setup\""
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# SYNC MODE — move real local files back into _ai-setup, then re-link
# ══════════════════════════════════════════════════════════════════════════════
if $SYNC; then
  cd "$REPO_ROOT"

  echo "  Mode       : sync → _ai-setup/$SYNC_FOLDER"
  echo ""

  # Directories to scan: local path → target path in _ai-setup
  # Includes both .claude/ and ai/ since users work in ai/ directly
  declare -A SYNC_DIRS=(
    [".claude/commands"]="$SUBMODULE/$SYNC_FOLDER/.claude/commands"
    [".claude/rules"]="$SUBMODULE/$SYNC_FOLDER/.claude/rules"
    [".cursor/rules"]="$SUBMODULE/$SYNC_FOLDER/.cursor/rules"
    ["ai/commands"]="$SUBMODULE/$SYNC_FOLDER/ai/commands"
    ["ai/docs"]="$SUBMODULE/$SYNC_FOLDER/ai/docs"
    ["ai/index"]="$SUBMODULE/$SYNC_FOLDER/ai/index"
  )

  SYNCED_COUNT=0
  for local_dir in "${!SYNC_DIRS[@]}"; do
    target_dir="${SYNC_DIRS[$local_dir]}"
    [ -d "$local_dir" ] || continue

    for f in "$local_dir"/*; do
      [ -e "$f" ] || continue
      [ -L "$f" ] && continue   # skip symlinks — already in _ai-setup
      [ -d "$f" ] && continue   # skip subdirectories

      fname="$(basename "$f")"
      mkdir -p "$target_dir"
      mv "$f" "$target_dir/$fname"
      ln -sfn "$(cd "$target_dir" && pwd)/$fname" "$local_dir/$fname"
      echo "  synced: $local_dir/$fname → $target_dir/$fname"
      SYNCED_COUNT=$((SYNCED_COUNT + 1))
    done
  done

  if [[ $SYNCED_COUNT -eq 0 ]]; then
    echo "  Nothing to sync — no real (non-symlink) files found in local dirs."
    echo "  (If you edited an existing symlinked file, it already updated _ai-setup/ directly.)"
  fi

  echo ""
  echo "✓ Sync complete ($SYNCED_COUNT file(s) moved to _ai-setup/$SYNC_FOLDER)."
  echo ""
  echo "Publish the changes:"
  echo "  cd _ai-setup"
  echo "  git add $SYNC_FOLDER/"
  echo "  git commit -m \"feat($SYNC_FOLDER): <describe what you added>\""
  echo "  git push"
  echo ""
  echo "Other repos pick it up with:"
  echo "  git submodule update --remote _ai-setup"
  if [[ "$SYNC_FOLDER" != "common" ]]; then
    echo "  bash _ai-setup/bootstrap.sh --team $SYNC_FOLDER"
  else
    echo "  bash _ai-setup/bootstrap.sh"
  fi
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# GLOBAL MODE — wire into ~/.claude/
# ══════════════════════════════════════════════════════════════════════════════
if $GLOBAL; then
  GLOBAL_DIR="$HOME/.claude"
  mkdir -p "$GLOBAL_DIR"
  echo "  Scope      : global (~/.claude)"
  echo "  Base layer : common (always)"
  echo "  Team layer : $TEAM_LABEL"
  echo ""

  # Whole-dir symlinks for agents, skills, helpers
  ln -sfn "$SUBMODULE/common/.claude/agents"  "$GLOBAL_DIR/agents"
  ln -sfn "$SUBMODULE/common/.claude/skills"  "$GLOBAL_DIR/skills"
  ln -sfn "$SUBMODULE/common/.claude/helpers" "$GLOBAL_DIR/helpers"
  echo "→ Wired agents, skills, helpers → $GLOBAL_DIR"

  # File-level symlinks for commands and rules (common first, team second)
  mkdir -p "$GLOBAL_DIR/commands" "$GLOBAL_DIR/rules"
  echo "→ Applying common layer → $GLOBAL_DIR/commands, $GLOBAL_DIR/rules"
  link_files "$SUBMODULE/common/.claude/commands" "$GLOBAL_DIR/commands"
  link_files "$SUBMODULE/common/.claude/rules"    "$GLOBAL_DIR/rules"

  if [[ -n "$TEAM" ]]; then
    echo "→ Applying team layer: $TEAM (overrides common on conflict)"
    link_files "$SUBMODULE/$TEAM/.claude/commands" "$GLOBAL_DIR/commands"
    link_files "$SUBMODULE/$TEAM/.claude/rules"    "$GLOBAL_DIR/rules"
  fi

  echo ""
  echo "✓ Global setup done. common + ${TEAM_LABEL} wired into $GLOBAL_DIR"
  echo "  Commands are now available in every project on this machine."
  echo "  Note: ~/.claude/settings.json is NOT touched — manage it separately."
  echo ""
  echo "  To upgrade: git submodule update --remote _ai-setup && bash _ai-setup/bootstrap.sh --global${TEAM:+ --team $TEAM}"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# REPO-LOCAL MODE — wire into .claude/ relative to repo root
# ══════════════════════════════════════════════════════════════════════════════
cd "$REPO_ROOT"
echo "  Scope      : repo-local"
echo "  Repo root  : $REPO_ROOT"
echo "  Base layer : common (always)"
echo "  Team layer : $TEAM_LABEL"
echo "  Claude-only: $CLAUDE_ONLY"
echo ""

# Whole-dir symlinks from common
mkdir -p .claude
ln -sfn "$SUBMODULE/common/.claude/agents"               .claude/agents
ln -sfn "$SUBMODULE/common/.claude/skills"               .claude/skills
ln -sfn "$SUBMODULE/common/.claude/helpers"              .claude/helpers
ln -sfn "$SUBMODULE/common/.claude/settings.json"        .claude/settings.json
ln -sfn "$SUBMODULE/common/.claude/personas-registry.md" .claude/personas-registry.md
mkdir -p .claude-flow
ln -sfn "$SUBMODULE/common/.claude-flow/config.yaml"     .claude-flow/config.yaml
mkdir -p .claude/commands .claude/rules ai/commands

echo "→ Applying common layer"
link_files "$SUBMODULE/common/.claude/commands" .claude/commands
link_files "$SUBMODULE/common/.claude/rules"    .claude/rules
link_files "$SUBMODULE/common/ai/commands"      ai/commands

# Team layer (applied after common — overrides on filename conflict)
if [[ -n "$TEAM" ]]; then
  echo "→ Applying team layer: $TEAM (overrides common on conflict)"
  link_files "$SUBMODULE/$TEAM/.claude/commands" .claude/commands
  link_files "$SUBMODULE/$TEAM/.claude/rules"    .claude/rules
  link_files "$SUBMODULE/$TEAM/ai/commands"      ai/commands
fi

# Cursor rules (skip with --claude-only)
if [ "$CLAUDE_ONLY" = false ]; then
  mkdir -p .cursor/rules
  echo "→ Wiring .cursor/rules (common)"
  link_files "$SUBMODULE/common/.cursor/rules" .cursor/rules
  if [[ -n "$TEAM" ]]; then
    echo "→ Wiring .cursor/rules (team: $TEAM)"
    link_files "$SUBMODULE/$TEAM/.cursor/rules" .cursor/rules
  fi
else
  echo "  (skipped .cursor — claude-only mode)"
fi

# Personas and claude-code-rules symlinks (common layer)
if [ -d "$SUBMODULE/common/ai/personas" ]; then
  mkdir -p ai
  ln -sfn "$SUBMODULE/common/ai/personas" ai/personas
  echo "→ Wired ai/personas → submodule"
fi
if [ -f "$SUBMODULE/common/ai/claude-code-rules.md" ]; then
  mkdir -p ai
  ln -sfn "$SUBMODULE/common/ai/claude-code-rules.md" ai/claude-code-rules.md
  echo "→ Wired ai/claude-code-rules.md → submodule"
fi

# Seed ai/memory/MEMORY.md if not present
# Seeding order: 1) team template  2) common template
if [ ! -f "ai/memory/MEMORY.md" ]; then
  mkdir -p ai/memory
  if [[ -n "$TEAM" && -f "$SUBMODULE/$TEAM/ai/memory/MEMORY.md" ]]; then
    cp "$SUBMODULE/$TEAM/ai/memory/MEMORY.md" ai/memory/MEMORY.md
    echo "→ Created ai/memory/MEMORY.md (from $TEAM template — customize for this repo)"
  elif [ -f "$SUBMODULE/common/ai/memory/MEMORY.md" ]; then
    cp "$SUBMODULE/common/ai/memory/MEMORY.md" ai/memory/MEMORY.md
    echo "→ Created ai/memory/MEMORY.md (from common template — customize for this repo)"
  fi
else
  echo "  (ai/memory/MEMORY.md exists — skipped)"
fi

# Seed CLAUDE.md if not present
# Seeding order: 1) team template  2) common/CLAUDE.md  3) CLAUDE.template.md
if [ ! -f "CLAUDE.md" ]; then
  if [[ -n "$TEAM" && -f "$SUBMODULE/$TEAM/CLAUDE.md" ]]; then
    cp "$SUBMODULE/$TEAM/CLAUDE.md" CLAUDE.md
    echo "→ Created CLAUDE.md (from $TEAM template — customize for this repo)"
  elif [ -f "$SUBMODULE/common/CLAUDE.md" ]; then
    cp "$SUBMODULE/common/CLAUDE.md" CLAUDE.md
    echo "→ Created CLAUDE.md (from common template — customize for this repo)"
  else
    cp "$SUBMODULE/CLAUDE.template.md" CLAUDE.md
    echo "→ Created CLAUDE.md (from fallback template — customize for this repo)"
  fi
else
  echo "  (CLAUDE.md exists — skipped)"
fi

# ── Git cleanup: untrack paths managed by submodule ──────────────────────────
# Paths that are now symlinked by this script — untrack them so git stops
# tracking the real files. Also add them to .gitignore so they stay clean.
MANAGED_PATHS=(
  ".claude/commands"
  ".claude/rules"
  ".claude/agents"
  ".claude/skills"
  ".claude/helpers"
  ".claude/settings.json"
  ".claude/personas-registry.md"
  ".claude-flow/config.yaml"
  ".cursor/rules"
  "ai/commands"
  "ai/personas"
  "ai/claude-code-rules.md"
)

# Only run git cleanup when inside a real git repo (not in global mode)
if git rev-parse --git-dir &>/dev/null; then
  UNTRACKED=0
  for p in "${MANAGED_PATHS[@]}"; do
    if git ls-files --error-unmatch "$p" &>/dev/null 2>&1 || \
       [ -n "$(git ls-files "$p" 2>/dev/null)" ]; then
      git rm --cached --ignore-unmatch -r "$p" &>/dev/null
      UNTRACKED=$((UNTRACKED + 1))
    fi
  done
  if [[ $UNTRACKED -gt 0 ]]; then
    echo "→ Untracked $UNTRACKED managed path(s) from git index"
  fi

  # Add managed paths to .gitignore if not already present
  GITIGNORE=".gitignore"
  SECTION_HEADER="# Managed by _ai-setup submodule (bootstrap.sh)"
  if ! grep -qF "$SECTION_HEADER" "$GITIGNORE" 2>/dev/null; then
    {
      echo ""
      echo "$SECTION_HEADER"
      for p in "${MANAGED_PATHS[@]}"; do
        echo "$p"
      done
    } >> "$GITIGNORE"
    echo "→ Added managed paths to .gitignore"
  else
    echo "  (.gitignore already has managed paths — skipped)"
  fi
fi

# ── MCP catalog seeding (backend team) ─────────────────────────────────────
if [[ "$TEAM" == "backend" ]]; then
  # Add .mcp.json to .gitignore if not already there
  if ! grep -qxF ".mcp.json" .gitignore 2>/dev/null; then
    echo ".mcp.json" >> .gitignore
    echo "  [mcp] added .mcp.json to .gitignore"
  fi

  # Seed .mcp.json from full catalog — defaults enabled, rest disabled
  if [[ ! -f ".mcp.json" ]]; then
    node - <<'NODEJS'
    const catalog = JSON.parse(require('fs').readFileSync('_ai-setup/backend/mcp/catalog.json','utf8'));
    const out = { mcpServers: {} };
    for (const [name, s] of Object.entries(catalog.servers)) {
      const isDefault = catalog.defaults.includes(name);
      out.mcpServers[name] = {
        command: s.command,
        args: s.args,
        env: s.env,
        ...(isDefault ? {} : { disabled: true })
      };
    }
    require('fs').writeFileSync('.mcp.json', JSON.stringify(out, null, 2) + '\n');
NODEJS
    DEFAULTS=$(node -e "const c=JSON.parse(require('fs').readFileSync('_ai-setup/backend/mcp/catalog.json','utf8')); console.log(c.defaults.join(', '))")
    echo "  [mcp] seeded .mcp.json — enabled: $DEFAULTS; rest disabled (toggle via /mcp in Claude Code)"
  else
    # Merge: add any new catalog entries not yet in .mcp.json
    node - <<'NODEJS'
    const catalog = JSON.parse(require('fs').readFileSync('_ai-setup/backend/mcp/catalog.json','utf8'));
    const mcp = JSON.parse(require('fs').readFileSync('.mcp.json','utf8'));
    let added = [];
    for (const [name, s] of Object.entries(catalog.servers)) {
      if (!mcp.mcpServers[name]) {
        const isDefault = catalog.defaults.includes(name);
        mcp.mcpServers[name] = {
          command: s.command,
          args: s.args,
          env: s.env,
          ...(isDefault ? {} : { disabled: true })
        };
        added.push(name);
      }
    }
    require('fs').writeFileSync('.mcp.json', JSON.stringify(mcp, null, 2) + '\n');
    if (added.length) process.stdout.write('  [mcp] added new catalog entries: ' + added.join(', ') + '\n');
    else process.stdout.write('  [mcp] .mcp.json up to date\n');
NODEJS
  fi
fi

# Install /ai-setup command globally so it's available in every worktree
GLOBAL_COMMANDS_DIR="$HOME/.claude/commands"
mkdir -p "$GLOBAL_COMMANDS_DIR"
ln -sfn "$SUBMODULE/common/.claude/commands/ai-setup.md" "$GLOBAL_COMMANDS_DIR/ai-setup.md"
echo "→ Installed /ai-setup globally (~/.claude/commands/ai-setup.md)"

echo ""
echo "✓ Done. common + ${TEAM_LABEL} applied."
echo ""
echo "Next steps:"
echo "  1. Edit CLAUDE.md — point @ai/index/codebase-index.md to your repo's index"
echo "  2. Edit ai/memory/MEMORY.md — customize session startup for this repo"
if [[ -n "$TEAM" ]]; then
  echo "  3. To upgrade: git submodule update --remote _ai-setup && bash _ai-setup/bootstrap.sh --team $TEAM"
else
  echo "  3. To upgrade: git submodule update --remote _ai-setup && bash _ai-setup/bootstrap.sh"
fi
