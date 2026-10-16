---
name: nix-helper
description: Guidelines and commands for managing and rebuilding the NixOS dotfiles configuration.
---

# NixOS & Dotfiles Helper

Use these guidelines when working with this repository:

- **Rebuild System**: Run `nh os switch .` or `sudo nixos-rebuild switch --flake .`
- **Rebuild Home Manager**: Handled automatically through the NixOS system rebuild module or `home-manager switch --flake .`
- **Format Code**: Format Nix expressions using `nixfmt` or `alejandra`.
- **Flake Updates**: Use `nix flake update <input-name>` to update specific inputs rather than updating all inputs blindly.
