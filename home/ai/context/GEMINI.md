# Global Context for Antigravity (Gemini)

## Environment & OS
- Operating System: NixOS (fully declarative).
- Package Management: Always use `nix-shell`, `nix run`, `nix profile`, or Flakes. NEVER suggest imperatively installing packages with `apt`, `pacman`, `dnf`, `brew`, etc.
- Default Shell: zsh.
- Primary Editor: Neovim.
- Terminal Multiplexer: tmux / workmux.

## Code & System Preferences
- Configuration is version-controlled in `~/.dotfiles`.
- Keep Nix expressions modular and clean (`lib.mkIf`, `lib.mkMerge`).
- Follow Conventional Commits for Git commit messages (`feat:`, `fix:`, `chore:`, etc.).
- Be concise, direct, and avoid unnecessary boilerplate or unsolicited explanations.
