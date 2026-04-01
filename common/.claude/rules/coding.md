# Coding & Implementation Rule

## MANDATORY: Always require a target package/folder before coding

When the user makes any coding, implementation, debugging, or refactoring request:

**DO NOT** scan or explore the codebase to guess the relevant package.

**DO** require the user to specify the target package or folder explicitly before proceeding.

If no package/folder is mentioned, respond with:

> Which package or folder should I work in? Check `ai/index/codebase-index.md` for the full list, or tell me the feature area and I'll look up the right package index.

## Using the index correctly

Once the package is specified:
1. Read `ai/index/packages/<package-name>.md` for that package's structure, exports, and patterns
2. Scope all file reads, edits, and searches to that package's `packages/<name>/src/` directory
3. Do not read files outside the specified package unless a cross-package dependency is explicitly needed

## Package naming reference

All packages are listed in `ai/index/codebase-index.md`. Common locations:
- Source: `packages/<name>/src/`
- Tests: `packages/<name>/src/__tests__/` or `packages/<name>/tests/`
- Built output: `packages/<name>/dist/`

## Why

This monorepo has 120+ packages. Scanning broadly wastes context, slows responses, and risks touching the wrong code. Explicit package scoping keeps work fast, focused, and correct.
