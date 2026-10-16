---
name: nix-helper
description: Guidelines and commands for managing and rebuilding the NixOS dotfiles configuration.
---

# NixOS & Dotfiles Helper

Use these guidelines when working with this repository:

- **Rebuild System**: Run `nh os switch .` or `sudo nixos-rebuild switch --flake .`
- **Format Code**: Format Nix expressions using `nixfmt` or `alejandra`.
- **Flake Updates**: Use `nix flake update <input-name>` to update specific inputs rather than updating all inputs blindly.
- **Inspect System Capabilities**: Verify `flake.nix`, `modules/`, and `home/home.nix` to understand available system capabilities, packages, and enabled services before proposing changes. Run `nix flake check --no-build` to verify flake evaluation integrity.
- **Solution Hierarchy**:
  - Prioritize declarative Nix solutions (NixOS/Home Manager options, modules, flakes) first.
  - If an alternative solution is demonstrably better or more practical than the Nix-way solution, prioritize that superior solution above all.
