Manage AI session files stored in `ai/local/memory/`.

Arguments: $ARGUMENTS

## --list
Use the Glob tool to find all files matching `ai/local/memory/session-*.md`, sorted by modification time.
For each file, use the Grep tool to extract:
- `claude-session-id:` from the frontmatter (show first 8 chars, or "no-id" if missing)
- The first `- ` bullet under `## Context` as the 1-liner

Display as:
```
N. session-YYYY-MM-DD_HH-MM  [id: 3c0817a3...]  <context 1-liner>
```

Do NOT use bash. Use only Glob and Grep tools.

## --resume [optional: session-name]
If no session-name given → run --list first and ask user to pick by number.

Once a session is selected, use the Read tool to open the file and extract `claude-session-id` from the frontmatter.

- In Claude Code CLI: run `/resume <claude-session-id>` to restore the full conversation transcript. If claude-session-id is missing or "cursor-session" → open `/resume` picker instead.
- In Cursor: display the full session file content as active context and continue appending to it.

Do NOT use bash. Use only Glob, Grep, and Read tools.
