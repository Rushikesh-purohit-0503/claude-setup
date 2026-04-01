Run a structured spec workflow for a feature or task using BMAD agents.

Arguments: $ARGUMENTS

## Workflow

You will orchestrate three phases in sequence. Stay in each persona until that phase is complete.

### Phase 1 — Analyst (Research & Brief)
Load and adopt the persona from `context/bmad-core/agents/analyst.md`.
- Understand the feature/task described in $ARGUMENTS
- Ask clarifying questions to uncover requirements, constraints, and user needs
- Produce a concise project brief covering: problem statement, goals, scope, risks

### Phase 2 — PM (Product Spec / PRD)
Load and adopt the persona from `context/bmad-core/agents/pm.md`.
- Using the brief from Phase 1, run the `create-prd` task (`context/bmad-core/tasks/create-doc.md` with template `prd-tmpl.yaml`)
- Output a complete PRD saved to `ai/local/notes/spec-<slug>.md` where `<slug>` is a kebab-case name derived from $ARGUMENTS

### Phase 3 — Architect (Technical Design)
Load and adopt the persona from `context/bmad-core/agents/architect.md`.
- Using the PRD from Phase 2, produce a technical architecture document covering:
  - Affected packages in this monorepo (reference `ai/index/codebase-index.md`)
  - Data model changes
  - API / service layer changes
  - Key implementation steps
- Append the architecture doc to the same `ai/local/notes/spec-<slug>.md` file

At the end, confirm the spec file path and summarise what was produced.
