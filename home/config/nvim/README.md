# 🚀 Neo's Neovim Configuration

A clean, modern, modular Neovim setup managed declaratively via **Home-Manager / NixOS** and powered by **lazy.nvim**.

---

## 📂 Architecture & Directory Structure

```text
~/.dotfiles/home/config/nvim/
├── init.lua              # Bootstrap lazy.nvim and loads options
├── lazy-lock.json        # Pinned plugin lockfile
├── README.md             # This documentation
└── lua/
    ├── options.lua       # General Vim settings and window movement
    └── plugins/          # Modular Lazy specs (auto-loaded)
        ├── ai.lua        # GitHub Copilot & CodeCompanion (with sops secret)
        ├── cmp.lua       # Autocompletion (nvim-cmp, LuaSnip)
        ├── core.lua      # Foundation utilities & snacks.nvim (image rendering)
        ├── img-clip.lua  # Clipboard image pasting into Markdown / LaTeX
        ├── lsp.lua       # Native Neovim LSP configs (nil_ls, lua_ls, rust-analyzer)
        ├── markdown.lua  # render-markdown.nvim (rich tables, callouts, icons)
        ├── silicon.lua   # Code screenshots via native silicon binary
        ├── telescope.lua # Fuzzy finding & which-key
        ├── tools.lua     # Oil.nvim (file manager), Obsidian, VimTeX, Fugitive
        ├── treesitter.lua# Treesitter syntax highlighting
        └── ui.lua        # Catppuccin-mocha theme & Bufferline tabs
```

---

## 🧩 Plugins Audit & Status

All plugins in this configuration follow modern Neovim (v0.10+ / v0.12+) standards:

| Plugin | Category | Purpose | Status |
| :--- | :--- | :--- | :--- |
| **`folke/lazy.nvim`** | Package Manager | Fast, deterministic plugin management | ✅ Modern standard |
| **`catppuccin/nvim`** | UI / Theme | Catppuccin-Mocha aesthetic | ✅ Modern standard |
| **`akinsho/bufferline.nvim`** | UI | Tabbed buffer line at top | ✅ Active & stable |
| **`folke/snacks.nvim`** | Core / Utilities | Modern helpers + Ghostty Kitty graphics image viewer | ✅ Cutting-edge (2025) |
| **`MeanderingProgrammer/render-markdown.nvim`** | Markdown | Rich inline Markdown rendering (tables, callouts, checkboxes) | ✅ Cutting-edge (2025) |
| **`michaelrommel/nvim-silicon`** | Utilities | Code screenshots to clipboard/file via native `silicon` | ✅ Active & fast |
| **`stevearc/oil.nvim`** | File Navigation | Edit filesystem like a Neovim buffer | ✅ Modern standard |
| **`nvim-telescope/telescope.nvim`** | Search | Fuzzy finder for files, text, and buffers | ✅ Industry standard |
| **`folke/which-key.nvim`** | Help / UI | Popup showing available keybindings as you type | ✅ Modern standard |
| **`hrsh7th/nvim-cmp`** + **`LuaSnip`** | Completion | Autocompletion engine for LSP, snippets, and paths | ✅ Industry standard |
| **`nvim-treesitter`** | Highlighting | AST-based syntax highlighting and indentation | ✅ Modern standard |
| **`neovim/nvim-lspconfig`** | LSP | Configures `nil_ls`, `lua_ls`, `rust-analyzer` | ✅ Native 0.11+ API |
| **`zbirenbaum/copilot.lua`** | AI | Fast, pure-Lua inline Ghost-text completions | ✅ Modern standard |
| **`olimorris/codecompanion.nvim`** | AI | LLM chat & inline code assistant (sops integration) | ✅ Modern standard |
| **`epwalsh/obsidian.nvim`** | Notes | Note-taking linked to `~/Documents/second_brain` | ✅ Active & synced |
| **`lervag/vimtex`** | LaTeX | LaTeX compilation & Zathura viewer integration | ✅ Timeless standard |
| **`HakonHarnes/img-clip.nvim`** | Media | Paste clipboard images straight into Markdown/LaTeX | ✅ Active & modern |
| **`tpope/vim-fugitive`** | Git | Git wrapper inside Neovim | ✅ Timeless standard |

---

## ⌨️ Keybindings Cheat Sheet

### 🪟 Navigation & Buffers
* `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>`: Move focus across window splits
* `<Tab>`: Next open buffer
* `<S-Tab>`: Previous open buffer
* `<leader>x`: Close current buffer
* `` ` ``: Open parent directory in **Oil.nvim**

### 🔍 Search & Finding (Telescope)
* `<leader>sf`: Search files
* `<leader>sg`: Live grep across project files
* `<leader><space>`: Search open buffers
* `<leader>sn`: Search Neovim configuration files

### 🧠 Code & LSP
* `gd`: Go to definition
* `K`: Hover documentation
* `<leader>rn`: Rename symbol
* `<leader>ca`: Code actions (LSP)
* `<leader>d`: Show diagnostic popup
* `[d` / `]d`: Jump to previous / next diagnostic

### 🤖 AI Assistant (CodeCompanion & Copilot)
* `<C-l>`: Accept Copilot suggestion
* `<C-j>` / `<C-k>`: Cycle next / previous suggestion
* `<C-e>`: Dismiss suggestion
* `<leader>cc`: Open CodeCompanion chat
* `<leader>ci`: CodeCompanion inline prompt
* `<leader>ca` *(or visual)*: CodeCompanion actions menu

### 📝 Markdown & Media
* `<leader>tm`: Toggle Markdown rendering on/off
* `<leader>pi`: Paste clipboard image into document
* `<leader>sc` *(Visual mode)*: Copy code screenshot to clipboard
* `<leader>sf` *(Visual mode)*: Save code screenshot to `~/Pictures/screenshots`
* `<leader>ss` *(Visual mode)*: Save screenshot and copy to clipboard

---

## 🔒 Secrets & NixOS Notes
* Secrets for `codecompanion.nvim` are securely loaded at startup from `/run/secrets/ai_models` (managed via **sops-nix**).
* The Neovim directory is symlinked out-of-store via `home.nix`:
  `xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/config/nvim";`
  Any changes made to files in `~/.dotfiles/home/config/nvim` take effect immediately on next Neovim launch.
