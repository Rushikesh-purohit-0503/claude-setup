Git utilities for this project's bare-repo + worktree setup.

Arguments: $ARGUMENTS

## --branch <type> <name>

Create a new branch from `rc-3.0` and add it as a worktree.

- `type`: one of `feature`, `fix`, `imp`
- `name`: branch name (e.g. `my-feature`)
- Final branch format: `<type>/<git-username>/<name>`
- Worktree path: `/Users/vyapar/code/backend/monorepo/<type>/<git-username>/<name>`

Run these bash commands in sequence:

```bash
# 1. Get git username (lowercase, spaces → hyphens)
GIT_USER=$(git config user.name | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# 2. Pull latest rc-3.0
cd /Users/vyapar/code/backend/monorepo/rc-3.0 && git pull

# 3. Create branch from rc-3.0 and add as worktree
git worktree add ../<type>/$GIT_USER/<name> -b <type>/$GIT_USER/<name>

# 4. Bootstrap AI setup in new worktree
MAIN_ROOT=$(git worktree list | head -1 | awk '{print $1}')
NEW_WT="/Users/vyapar/code/backend/monorepo/<type>/$GIT_USER/<name>"
ln -sfn "$MAIN_ROOT/_ai-setup" "$NEW_WT/_ai-setup"
bash "$NEW_WT/_ai-setup/bootstrap.sh" --team backend
echo "✓ AI setup wired in new worktree"
```

Replace `<type>` and `<name>` with the values from $ARGUMENTS.

After success, confirm the branch name and worktree path created.
