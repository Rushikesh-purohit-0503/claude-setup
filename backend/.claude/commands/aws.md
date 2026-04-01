> Source of truth: `ai/commands/aws.md` — edit there, keep this file in sync.

Switch the AWS profile used by all `aws.*` MCP servers via the `AWS_MCP_PROFILE` env var in `~/.zshenv`.

Arguments: $ARGUMENTS

---

## --profile <name>  (also: --readonly, --default, --custom, --zaayka)

Switch `AWS_PROFILE` for all `aws.*` MCP servers by updating `~/.zshenv`.

Shorthand aliases map to profiles:
- `--readonly`  → profile `readonly`
- `--default`   → profile `default`
- `--custom`    → profile `custom`
- `--zaayka`    → profile `zaayka`

Steps:
1. Determine the target profile name:
   - If `--profile <name>` → use `<name>`
   - If `--readonly`       → use `readonly`
   - If `--default`        → use `default`
   - If `--custom`         → use `custom`
   - If `--zaayka`         → use `zaayka`
2. Read `~/.zshenv`
3. Find the line `export AWS_MCP_PROFILE=...`:
   - If found → replace it with `export AWS_MCP_PROFILE=<profile>`
   - If not found → append `export AWS_MCP_PROFILE=<profile>` at the end
4. Write `~/.zshenv`
5. Print a confirmation table:

| Server            | AWS_PROFILE |
|-------------------|-------------|
| aws               | <profile>   |
| aws.api           | <profile>   |
| aws.billing       | <profile>   |
| aws.cost_explorer | <profile>   |
| aws.pricing       | <profile>   |

6. Print: "Updated ~/.zshenv → AWS_MCP_PROFILE=<profile>. Restart Claude Code to apply."
7. Do NOT touch `.mcp.json` — it contains the `${AWS_MCP_PROFILE}` placeholder and must not be modified.

---

## --status

Show the current `AWS_MCP_PROFILE` and available profiles.

Steps:
1. Read `~/.zshenv`
2. Extract the value from the line `export AWS_MCP_PROFILE=<value>`:
   - If found → print: "Current AWS_MCP_PROFILE (from ~/.zshenv): <value>"
   - If not found → print: "AWS_MCP_PROFILE is not set in ~/.zshenv. Run `/aws --readonly` to set it."
3. Print the list of available profiles from `~/.aws/credentials` (grep `^\[` lines)
4. Do NOT read `.mcp.json` for profile info — it only contains the `${AWS_MCP_PROFILE}` placeholder.
