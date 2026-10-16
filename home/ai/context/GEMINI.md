# Global Context for Antigravity (Gemini)

## Environment & OS
- Operating System: NixOS (fully declarative).
- System Capability Verification: Inspect the Nix configuration (`flake.nix`, `home/home.nix`, `modules/`, etc.) to know the capabilities of the OS, installed packages, and enabled services before proposing or implementing changes.
- Package Management: Always use `nix-shell`, `nix run`, `nix profile`, or Flakes. NEVER suggest imperatively installing packages with `apt`, `pacman`, `dnf`, `brew`, etc.
- Default Shell: zsh.
- Primary Editor: Neovim.
- Terminal Multiplexer: tmux / workmux.

## Code & System Preferences
- Configuration is version-controlled in `~/.dotfiles`, are not neccesary git add or commit manually (the "nos" script have control to the remote git repository).
- Keep Nix expressions modular and clean (`lib.mkIf`, `lib.mkMerge`).
- Follow Conventional Commits for Git commit messages (`feat:`, `fix:`, `chore:`, etc.).
- Be concise, direct, and avoid unnecessary boilerplate or unsolicited explanations.

## Build Scripts & QA Validation
- **Helper Scripts**:
  - `not`: Tests system configuration using `nh os test` without switching or committing.
  - `nos`: Rebuilds/switches system using `nh os switch`, auto-commits, and pushes on success.
- **Post-Build QA**: All tests must pass after build. Always validate changes with `not` or check for runtime failures (`systemctl --failed`, `systemctl --user --failed`) before considering work complete.
- **Rebuild Confirmation**: Rebuilding or switching NixOS (`nos`, `nh os switch`) must ALWAYS be the final step and strictly requires asking the user for explicit confirmation beforehand. NEVER execute a rebuild automatically.

## Solution Hierarchy
- **Nix-Way First**: If a declarative Nix configuration, option, flake input, or NixOS/Home Manager module solves the problem in question, make it PRIORITY over other solutions.
- **Pragmatic Priority**: If an alternative solution is genuinely better or more practical than the Nix-way solution, make that superior solution PRIORITY ABOVE ALL.
