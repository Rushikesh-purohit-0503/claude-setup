# Rushikesh-purohit-0503/claude-setup

Shared AI tooling — Claude Code commands, agents, skills, helpers, and Cursor rules. Consumed as a git submodule. One push here updates every repo.

---

## Repository structure

```
ai-setup/
├── common/                        ← applied to every repo automatically
│   ├── .claude/
│   │   ├── commands/              ← slash commands (lyra, review, session, git, persona, BMAD agents, etc.)
│   │   ├── agents/                ← 99+ Ruflo specialized agents
│   │   ├── skills/                ← Ruflo skill sets (lyra, ruflo)
│   │   ├── helpers/               ← lifecycle hook scripts (41 scripts)
│   │   ├── rules/                 ← coding.md, commander.md
│   │   ├── settings.json          ← hook configuration for Claude Code
│   │   └── personas-registry.md
│   ├── .claude-flow/
│   │   └── config.yaml            ← RuFlo V3 runtime config
│   ├── .cursor/rules/             ← 51 Cursor .mdc rule files
│   └── ai/
│       ├── commands/              ← source of truth for shared commands (lyra, review, session)
│       └── memory/MEMORY.md       ← generic session startup protocol (customize per repo)
│
├── backend/                       ← backend-specific additions
│   ├── .claude/commands/          ← backend-only slash commands
│   ├── .claude/rules/             ← backend rule overrides
│   └── .cursor/rules/             ← backend-specific .mdc files
│
├── desktop/                       ← desktop-specific additions (same structure)
├── android/                       ← android-specific additions (same structure)
├── data/                          ← data team additions (same structure)
│
├── bootstrap.sh                   ← one-time setup + re-run on upgrade
└── CLAUDE.template.md             ← starter CLAUDE.md for new consumer repos
```

**How layers work**: `common/` is always applied first. If `--team` is given, that team's files are applied second into the same directories — if both `common` and the team have a file with the same name, the **team file wins** (symlink is overwritten). Files in `.claude/commands/`, `.claude/rules/`, `.cursor/rules/`, and `ai/commands/` are symlinked individually, so both layers can contribute files to the same directory. `agents/`, `skills/`, and `helpers/` are **whole-directory symlinks** (common only) — meaning the entire folder is a single symlink, so team layers cannot add to them.

---

## Every developer — after cloning or pulling

> **Run these two commands whenever you clone the repo or pull changes that update the `_ai-setup` submodule pointer.**

```bash
git submodule update --init
bash _ai-setup/bootstrap.sh --team backend
```

That's it. Bootstrap is idempotent — safe to re-run anytime. It will:
- Populate `_ai-setup/` if it's empty (first clone)
- Sync `_ai-setup/` to the pinned commit if the pointer changed (after pull)
- Re-create all symlinks: `.claude/commands/`, `.claude/rules/`, `.cursor/rules/`, `ai/commands/`, `ai/personas`, `ai/claude-code-rules.md`
- Seed `CLAUDE.md` and `ai/memory/MEMORY.md` **only if they don't exist** (never overwrites your customizations)

Replace `backend` with your team (`desktop`, `android`, `data`) if applicable.

---

## Onboarding a new repo (one-time)

```bash
# 1. Add the submodule
git submodule add git@github.com:Rushikesh-purohit-0503/claude-setup.git _ai-setup
git submodule update --init

# 2. Run bootstrap — pick one team (or none for common only)
bash _ai-setup/bootstrap.sh --team backend          # common + backend
bash _ai-setup/bootstrap.sh --team data             # common + data
bash _ai-setup/bootstrap.sh --team desktop          # common + desktop
bash _ai-setup/bootstrap.sh --team android          # common + android
bash _ai-setup/bootstrap.sh                         # common only
bash _ai-setup/bootstrap.sh --team backend --claude-only  # skip Cursor setup

# 3. Customize the per-repo files (seeded automatically if they don't exist)
#    - CLAUDE.md              → update @ai/index/codebase-index.md reference
#    - ai/memory/MEMORY.md   → customize session startup for this repo

# 4. Commit
git add _ai-setup .gitmodules
git commit -m "chore: add ai-setup submodule"
```

---

## bootstrap.sh flags

| Flag | Description |
|------|-------------|
| `--team <name>` | One team layer to apply on top of common: `backend`, `desktop`, `android`, or `data`. Team files override common on filename conflict. |
| `--claude-only` | Skip `.cursor/rules/` setup (for repos not using Cursor). |
| `--global` | Wire into `~/.claude/` instead of the repo-local `.claude/`. Makes commands available machine-wide in every project. Can be combined with `--team`. |
| `--sync [folder]` | Move real (non-symlink) files from local `ai/` and `.claude/` dirs into `_ai-setup/<folder>/`, then re-link. Folder can be `common`, `backend`, `desktop`, `android`, or `data`. Defaults to `common` if omitted. |
| `--update` | Pull the latest `ai-setup` from remote (`git submodule update --remote`), re-wire all symlinks, and stage the updated submodule pointer. Combine with `--team` to keep the same layer. |

**Layer order**: `common` always runs first, then `--team` (if given). Same filename in both → team wins.

Bootstrap is **idempotent** — re-run after any upgrade to refresh symlinks. Existing `CLAUDE.md` and `ai/memory/MEMORY.md` are never overwritten.

**Global `/ai-setup` install**: Every `bootstrap.sh` repo-local run automatically symlinks `common/.claude/commands/ai-setup.md` → `~/.claude/commands/ai-setup.md`, making `/ai-setup` available as a slash command in **every** Claude Code project on the machine — no global flag needed.

---

## Wiring a new worktree

When you create a new git worktree, it starts with an empty `_ai-setup/` and no symlinks. Two ways to bootstrap it:

### Option A — Automatic (via `/git --branch`)

The `/git --branch` command handles everything after creating the worktree:

```bash
/git --branch feature my-work
# → creates worktree at /Users/me/code/monorepo/feature/<user>/my-work
# → symlinks _ai-setup from the main worktree
# → runs bootstrap.sh --team backend automatically
```

### Option B — Manual (via `/ai-setup --worktree`)

Because bootstrap installs `/ai-setup` globally into `~/.claude/commands/`, this command is available in **any** Claude Code session — even in a brand-new worktree with no local setup:

```bash
/ai-setup --worktree            # bootstrap current worktree (team: backend)
/ai-setup --worktree desktop    # bootstrap current worktree (team: desktop)
```

What it does:
1. Finds the main worktree via `git worktree list`
2. Symlinks `_ai-setup/` from main → current worktree (if not already wired)
3. Runs `bootstrap.sh --team <team>` in the current worktree

---

## Global setup (machine-wide)

Use `--global` to wire commands into `~/.claude/` so they are available in **every** Claude Code project on the machine — no submodule needed in each repo.

```bash
# Wire common commands globally
bash _ai-setup/bootstrap.sh --global

# Wire common + backend commands globally
bash _ai-setup/bootstrap.sh --global --team backend

# Upgrade global setup
git submodule update --remote _ai-setup
bash _ai-setup/bootstrap.sh --global --team backend
```

**What gets wired globally:**

| Target | Source | Type |
|--------|--------|------|
| `~/.claude/commands/` | `common/.claude/commands/` + team | file-level symlinks |
| `~/.claude/rules/` | `common/.claude/rules/` + team | file-level symlinks |
| `~/.claude/agents/` | `common/.claude/agents/` | whole-dir symlink |
| `~/.claude/skills/` | `common/.claude/skills/` | whole-dir symlink |
| `~/.claude/helpers/` | `common/.claude/helpers/` | whole-dir symlink |

`~/.claude/settings.json` is **not touched** — manage global settings separately to avoid overwriting personal configuration.

**Repo-local vs global:**

| | Repo-local (default) | Global (`--global`) |
|---|---|---|
| Scope | One repo | Every project on the machine |
| Requires submodule | Yes | Yes (submodule is the source) |
| Per-repo override possible | Yes (add files to `.claude/`) | No — all repos share the same global symlinks |
| Cursor rules wired | Yes (`.cursor/rules/`) | No — Cursor is project-scoped |

---

## Upgrading a consumer repo

**One command:**

```bash
bash _ai-setup/bootstrap.sh --update --team backend   # replace backend with your team
bash _ai-setup/bootstrap.sh --update                  # if using common only
```

This pulls the latest `ai-setup`, re-wires all symlinks, and stages the updated submodule pointer. Then just commit:

```bash
git commit -m "chore: upgrade ai-setup"
```

**Manual equivalent** (if you prefer step-by-step):

```bash
git submodule update --remote _ai-setup
bash _ai-setup/bootstrap.sh --team backend
git add _ai-setup
git commit -m "chore: upgrade ai-setup"
```

---

## Syncing local changes back to the repo

Update files in your repo's `ai/` or `.claude/` folder, then use `--sync <folder>` to move them into `_ai-setup/` and publish so every repo gets them.

```bash
# Sync into a team folder
bash _ai-setup/bootstrap.sh --sync backend
bash _ai-setup/bootstrap.sh --sync desktop
bash _ai-setup/bootstrap.sh --sync android
bash _ai-setup/bootstrap.sh --sync data

# Sync into common (shared with everyone)
bash _ai-setup/bootstrap.sh --sync
bash _ai-setup/bootstrap.sh --sync common
```

**What `--sync` does:**

1. Scans these local directories for **real files** (not symlinks):
   - `.claude/commands/`, `.claude/rules/`, `.cursor/rules/`
   - `ai/commands/`, `ai/docs/`, `ai/index/`
2. **Moves** each real file into the target `_ai-setup/<folder>/` path
3. Re-creates a symlink in the original location — your local setup keeps working
4. Reports count and tells you the exact `git` commands to publish

**After sync — publish:**

```bash
cd _ai-setup
git add backend/          # or desktop/, common/, etc.
git commit -m "feat(backend): add my-new-command"
git push
```

Other repos pick it up:
```bash
git submodule update --remote _ai-setup
bash _ai-setup/bootstrap.sh --team backend
```

**Rule of thumb:**

| Scenario | Command |
|----------|---------|
| New command for backend repos | `--sync backend` |
| New command for desktop repos | `--sync desktop` |
| New command for all repos | `--sync` (goes into `common/`) |
| Edited an existing symlinked file | Already in `_ai-setup/` — just `cd _ai-setup && git commit && git push` |

---

## Adding content to a team layer

To add a backend-specific command:

```bash
# In this (ai-setup) repo:

# 1. Add the command file
echo "# My backend command" > backend/.claude/commands/my-command.md

# 2. Mirror it for Cursor (optional)
cat > backend/.cursor/rules/my-command.mdc <<'EOF'
---
description: My backend command
alwaysApply: false
---
@.claude/commands/my-command.md
EOF

# 3. Commit and push
git add backend/
git commit -m "feat(backend): add my-command"
git push

# In each consumer repo:
git submodule update --remote _ai-setup
bash _ai-setup/bootstrap.sh --team backend
```

The new file will appear as `.claude/commands/my-command.md` (symlink) in every repo bootstrapped with `--team backend`.

### Overriding a common file from a team layer

If `common/.claude/commands/review.md` exists and you want `backend` to use a different version:

```bash
# Add a file with the exact same name in the team folder
cp common/.claude/commands/review.md backend/.claude/commands/review.md
# Edit backend/.claude/commands/review.md with backend-specific content

git add backend/.claude/commands/review.md
git commit -m "feat(backend): override review command"
git push
```

After `bootstrap.sh --team backend`, the backend symlink overwrites the common one.

---

## Adding content to common

Same process, but place files under `common/`:

```bash
# New shared command available to all teams
common/.claude/commands/my-shared-command.md
common/.cursor/rules/my-shared-command.mdc
common/ai/commands/my-shared-command.md   # source of truth (optional)
```

After pushing, all consumer repos pick it up on their next `git submodule update --remote` + `bootstrap.sh` run.

---

## Consumer repo layout (after bootstrap)

```
consumer-repo/
├── _ai-setup/              ← git submodule → Rushikesh-purohit-0503/claude-setup
├── .claude/
│   ├── commands/           ← real dir; files symlinked from common/ + team layers
│   ├── agents/             ← symlink → _ai-setup/common/.claude/agents/
│   ├── skills/             ← symlink → _ai-setup/common/.claude/skills/
│   ├── helpers/            ← symlink → _ai-setup/common/.claude/helpers/
│   ├── rules/              ← real dir; files symlinked from common/ + team layers
│   ├── settings.json       ← symlink → _ai-setup/common/.claude/settings.json
│   └── personas-registry.md
├── .cursor/rules/          ← real dir; files symlinked from common/ + team layers
├── ai/
│   ├── commands/           ← real dir; files symlinked from common/ + team layers
│   ├── index/              ← PER-REPO — codebase index (never in submodule)
│   ├── docs/               ← PER-REPO — ai-dev-setup.md
│   ├── memory/MEMORY.md    ← PER-REPO — customize from template
│   └── local/              ← gitignored — sessions, notes, scratch
└── CLAUDE.md               ← PER-REPO — customize from template
```

Files under `ai/index/`, `ai/docs/`, `ai/memory/`, and `CLAUDE.md` are never touched by bootstrap or submodule updates — they are always repo-specific.

---

## Per-repo vs submodule-managed

| What | Where | Overridable? |
|------|-------|--------------|
| Commands, rules, agents, skills, helpers | Submodule → symlinked into `.claude/` | Yes — remove the `.gitignore` entry, add your own real file |
| `.cursor/rules/` | Submodule → symlinked | Yes — same as above |
| `ai/commands/` | Submodule → symlinked | Yes — same as above |
| `ai/personas/` | Submodule → symlinked from `common/ai/personas/` | Yes — remove `.gitignore` entry, add real directory |
| `ai/claude-code-rules.md` | Submodule → symlinked from `common/ai/claude-code-rules.md` | Yes — remove `.gitignore` entry, add real file |
| `CLAUDE.md` | Seeded from team template on first run, then fully editable | Yes — edit directly, bootstrap never overwrites |
| `ai/memory/MEMORY.md` | Seeded from team template on first run, then fully editable | Yes — edit directly, bootstrap never overwrites |
| `ai/index/` | Per-repo only — codebase index | N/A — never in submodule |
| `ai/docs/` | Per-repo only — ai-dev-setup.md and other docs | N/A — never in submodule |

**To override a symlinked file:**

1. Remove the `.gitignore` entry for that path (or just add the real file — git will track it over the symlink)
2. Create the real file at the same path
3. Re-running bootstrap will no longer overwrite it (bootstrap only creates symlinks, not real files)
