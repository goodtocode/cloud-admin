# Copilot instructions: cloud-admin

This repo is a PowerShell and Markdown knowledge base for Azure cloud administration, engineering, and architecture (scripts, how-to docs, command references, T-SQL DBA scripts).

## PowerShell scripts
- Target PowerShell 7+ on Windows; use Windows paths in docs, forward slashes in `Import-Module` relative paths.
- Start each script with the existing header comment: synopsis line, parameter list, and an `Example:` line.
- Use `param()` with typed parameters; `$ErrorActionPreference = 'Stop'` for new scripts.
- Anything that creates, changes, or deletes resources must use `[CmdletBinding(SupportsShouldProcess)]` and honor `-WhatIf`.
- Prefer `az` CLI or `Az.*` modules. Do not depend on `az` extensions. Check `$LASTEXITCODE` after `az` calls and keep stderr out of parsed JSON.
- Always wrap `ConvertFrom-Json` results that may be single items in `@()` before indexing or counting.
- Shared helpers: import from `scripts/System.psm1` and `scripts/Azure.psm1` only (never copy the module into subfolders). Compute the relative path from the script's own folder.
- Install modules only when missing (`Get-Module -ListAvailable`), not on every run.
- Make bulk operations resilient: skip and report items that fail or are missing, then print a summary.

## Git workflow
- Do not run `git commit`, `git push`, or create pull requests. Leave changes uncommitted in the working tree so the repo owner can review them, then commit, push, and open the PR themselves.

## Security
- Never commit secrets, keys, tokens, real tenant/subscription/object IDs, or customer data. Use `00000000-0000-0000-0000-000000000000` placeholders.
- Default to least privilege in examples; call out destructive commands clearly.

## Documentation (docs/)
- Markdown how-tos use the naming pattern `How-to <Topic>.md` and `Commands - <Area>.md`.
- Show runnable commands in fenced `powershell`/`bash` blocks; state prerequisites and required permissions.
- Update `README.md` when adding a notable script or doc.
