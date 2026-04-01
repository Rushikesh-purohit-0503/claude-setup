GitLab Merge Request code review with session persistence and inline comments.
Supports `--local` to review uncommitted local changes instead of a remote MR.

Arguments: $ARGUMENTS

---

## Usage

Parse $ARGUMENTS for flags:
- If `--local` is present → follow the **`--local` mode** section below
- If an MR number or GitLab MR URL is present → extract the number and follow **MR mode**
- If neither → run `glab mr list` to show open MRs and stop

---

## --local mode — Review local git changes

### Local Step 1 — Determine session path

1. Get current branch: `git rev-parse --abbrev-ref HEAD`
2. Derive `<project-name>` from: `git remote get-url origin` — take the repo slug (last path segment, strip `.git`)
3. Set session directory: `ai/local/review/<project-name>/local-<branch>/`

### Local Step 2 — Load previous local session (if it exists)

1. Glob `ai/local/review/<project-name>/local-<branch>/session.md` — if found, read it
2. Read `ai/local/review/<project-name>/local-<branch>/comments.json` if it exists
3. Do not re-raise issues already marked `resolved: true`
4. If prior session found: "Re-reviewing local changes on `<branch>` — loaded previous session with <N> prior comments."

### Local Step 3 — Build the diff

Run in this priority order:
1. `git diff HEAD` — all uncommitted changes
2. If empty: `git diff --cached` — staged only
3. If empty: `git diff main...HEAD` — commits on this branch vs main

### Local Step 4 — Analyze and save

Analyze against: code correctness, project conventions, performance, test coverage, security (OWASP top 10), dependency tiers.

Save session and comments.json (same schema as MR mode, `gitlab_discussion_id` always `null`).

Tell the user: "Review saved to `ai/local/review/<project-name>/local-<branch>/`. When you open an MR, run `/review <mr-number>` to post these as inline comments."

---

## MR mode

---

## Step 1 — Determine project name, project ID, and session path

1. Extract the MR number from $ARGUMENTS (from URL or plain number)
2. Run `glab mr view <number>` to confirm it exists and get the branch name
3. Run `glab api "projects?search=<repo-slug>&membership=true"` to get the numeric project ID
4. Set:
   - `PROJECT_ID` = numeric ID (e.g. `46787886`)
   - Session directory: `ai/local/review/<project-name>/<mr-number>/`

---

## Step 2 — Load previous session (if it exists)

1. Glob `ai/local/review/<project-name>/<mr-number>/session.md` — if found, read it
2. Read `ai/local/review/<project-name>/<mr-number>/comments.json` — load previous comments
3. Do not re-raise issues already marked `resolved: true`
4. If prior session: "Re-reviewing MR #<number> — loaded previous session with <N> prior comments."

---

## Step 3 — Fetch diff and compute real file line numbers

Run `glab mr diff <number>` to get the full unified diff.

**CRITICAL — Line number tracking for inline comments:**

GitLab inline comments require the **actual line number in the new version of the file**, not the sequential line number in the diff output. Parse the diff as follows:

- When you see a hunk header `@@ -old_start,old_count +new_start,new_count @@`:
  - Set `current_new_line = new_start`
- For each line after the hunk header:
  - Lines starting with `+` (added): this line is at `current_new_line` in the new file → increment `current_new_line`
  - Lines starting with ` ` (context, no prefix): this line exists in both files → increment `current_new_line`
  - Lines starting with `-` (removed): do NOT increment `current_new_line`
- For each issue found on a `+` or context line, record its `current_new_line` value as the comment line number

For new files (`@@ -0,0 +1,N @@`): line numbers start at 1 and increment for every `+` line.

---

## Step 4 — Analyze the diff

Analyze against:
- Code correctness
- Project conventions (`ai/index/codebase-index.md`)
- Performance implications
- Test coverage
- Security considerations (OWASP top 10)
- Dependency tier rules (never add higher-tier dep to lower-tier package)

For each issue record:
- `file` — relative file path (as it appears in the diff header `+++ b/<file>`, strip the `b/` prefix)
- `line` — actual new-file line number (computed per Step 3)
- `severity` — `critical` | `high` | `medium` | `low` | `suggestion`
- `agent` — review aspect (`security`, `style`, `performance`, `architecture`, `correctness`)
- `body` — comment text (see format below)

---

## Step 5 — Print review summary

Output:
- **Overview**: what the MR does
- **Issues found**: grouped by severity, each with `file:line`
- **Suggestions**: non-blocking improvements

---

## Step 6 — Save session

Get MR diff refs: `glab api "projects/<PROJECT_ID>/merge_requests/<number>" | python3 -c "import sys,json; d=json.load(sys.stdin); refs=d.get('diff_refs',{}); print(refs.get('base_sha'), refs.get('start_sha'), refs.get('head_sha'))"`

Save/overwrite `ai/local/review/<project-name>/<mr-number>/session.md`:

```markdown
---
mr: <number>
project: <project-name>
project-id: <PROJECT_ID>
reviewed-at: <YYYY-MM-DD HH:MM>
branch: <source branch>
base-sha: <base_sha>
start-sha: <start_sha>
head-sha: <head_sha>
---

## Review Summary
<overview>

## Issues
<list each issue: severity | file:line | agent | short description>
```

Save/update `ai/local/review/<project-name>/<mr-number>/comments.json`:
```json
[
  {
    "file": "packages/foo/src/bar.ts",
    "line": 42,
    "severity": "high",
    "agent": "security",
    "body": "<comment text>",
    "gitlab_discussion_id": null,
    "resolved": false
  }
]
```

---

## Step 7 — Ask ONCE, then post all

After saving, ask the user ONE TIME:

> Found **<N> issues** (high: X, medium: Y, low: Z). Post all as inline comments on MR #<number>? [yes / no]

**If yes**: immediately post all comments without any further prompts (see Step 8).
**If no**: stop. Tell the user they can run `/review <number>` again to post later.

Do NOT ask per-comment. Do NOT ask again after the user says yes.

---

## Step 8 — Post all inline comments

Use the SHAs saved in session.md. For each comment in comments.json where `gitlab_discussion_id` is null:

```bash
glab api "projects/<PROJECT_ID>/merge_requests/<number>/discussions" \
  --method POST \
  -f "body=<comment body>" \
  -f "position[position_type]=text" \
  -f "position[base_sha]=<base_sha>" \
  -f "position[head_sha]=<head_sha>" \
  -f "position[start_sha]=<start_sha>" \
  -f "position[new_path]=<file>" \
  -f "position[new_line]=<line>"
```

Capture the returned `id` → save as `gitlab_discussion_id` in comments.json.
Print: `✓ <file>:<line> — <id>`

Post all comments in sequence without pausing.

---

## Step 9 — Resolve outdated comments on re-review

Only runs when prior session has comments with `gitlab_discussion_id` set and `resolved: false`.

For each such comment: check if the issue is still present in the current diff. If gone:

```bash
glab api "projects/<PROJECT_ID>/merge_requests/<number>/discussions/<discussion_id>" \
  --method PUT \
  -f "resolved=true"
```

Update `comments.json` → `resolved: true`. Print: `Resolved: <file>:<line>`

---

## Comment format

```
[agent:<agent-name>] <severity-emoji> **<severity>**

<clear description of the issue>

**Suggestion:**
<specific fix or improvement>
```

Severity emojis: `🔴 critical` | `🟠 high` | `🟡 medium` | `🔵 low` | `💡 suggestion`

---

## Session folder layout

```
ai/local/review/
  <project-name>/
    <mr-number>/
      session.md       ← review summary, metadata, SHAs
      comments.json    ← all comments with discussion IDs and resolved state
```

`ai/local/` is gitignored — never pushed.

---

## Rules

- Ask to post comments ONCE only — never per-comment
- If user says yes, post ALL without further prompting
- Never re-raise an issue marked `resolved: true`
- Always tag comments `[agent:<name>]`
- `new_line` in position MUST be the actual line number in the new file (parsed from hunk headers), not the line number in the diff output
- Use `glab api` (not curl) for all GitLab API calls
- Keep `comments.json` as the single source of truth across re-reviews
