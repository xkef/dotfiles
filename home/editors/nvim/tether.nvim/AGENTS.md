# tether.nvim development

This plugin grows spec-first with OpenSpec. The specs in `openspec/specs/`
describe current behavior; changes in `openspec/changes/` describe behavior in
progress.

## Workflow

1. Every behavior change starts as a change directory: `openspec/changes/<id>/`
   with `.openspec.yaml`, `proposal.md`, `design.md`, `tasks.md`, and delta
   specs under `specs/<capability>/`.
2. Run `openspec validate --all --strict` from this directory. Without a global
   install, use `npx @fission-ai/openspec`.
3. Implement against `tasks.md` and check tasks off as they land.
4. Each spec scenario has one test in `tests/`, named after the scenario. Run
   `tests/run.sh` (headless Neovim, needs `jj` and `git`).
5. When all tasks are done and tests pass, archive the change:
   `openspec archive <id> --yes`.

Refactors and tooling changes without behavior changes skip specs and set
`skip_specs: true` in `.openspec.yaml`.

## Code

- Lua modules live in `lua/tether/`; `plugin/tether.lua` only defines the
  command.
- No required plugin dependencies. snacks.nvim, codediff.nvim, WezTerm, and the
  OpenSpec CLI are optional and must degrade cleanly.
- jj calls for UI refreshes use `--ignore-working-copy`.
- Format with stylua (2 spaces, 120 columns).
