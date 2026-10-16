---
name: nix-helper
description: Guidelines and commands for managing and rebuilding the NixOS dotfiles configuration.
---

# NixOS & Dotfiles Helper

Use these guidelines when working with this repository:

- **Build & Test Scripts**:
  - `not`: Tests system configuration with `nh os test` (dry run / activation test without committing).
  - `nos`: Rebuilds system with `nh os switch`, auto-commits working configuration, and pushes to Git.
- **Inspect System Capabilities**: Verify `flake.nix`, `modules/`, and `home/home.nix` to understand available system capabilities, packages, and enabled services before proposing changes.
- **Format Code**: Format Nix expressions using `nixfmt` or `alejandra`.
- **Flake Updates**: Use `nix flake update <input-name>` to update specific inputs rather than updating all inputs blindly.

## NixOS QA & Post-Build Validation
- **Mandatory Passing**: All tests and validations must pass after building or testing. Never conclude a change with failing evaluations or broken units.
- **Rebuild Confirmation**: Rebuilding or switching the system (`nos` or `nh os switch`) must ALWAYS be the last part of confirmation. Always ask the user first if they want to rebuild their Nix configuration; NEVER run rebuild or switch commands automatically.
- **Validation Workflow**:
  1. Test configuration changes using `not`.
  2. Inspect system status for runtime regressions (`systemctl --failed`, `systemctl --user --failed`).
  3. Ask the user for confirmation to rebuild.
  4. Once confirmed by the user, apply and commit changes via `nos`.

## Solution Hierarchy
- Prioritize declarative Nix solutions (NixOS/Home Manager options, modules, flakes) first.
- If an alternative solution is demonstrably better or more practical than the Nix-way solution, prioritize that superior solution above all.
