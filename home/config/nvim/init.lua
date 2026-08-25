-- ========================================================================== --
-- 1. General Options & Leader Key (Set before lazy.nvim)
-- ========================================================================== --
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.clipboard = "unnamedplus"
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.timeoutlen = 300
opt.undofile = true

-- ========================================================================== --
-- 2. Bootstrap lazy.nvim
-- ========================================================================== --
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
opt.rtp:prepend(lazypath)

-- ========================================================================== --
-- 3. Plugin Specifications & Configurations
-- ========================================================================== --
require("lazy").setup({
  -- Theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    tag = "v0.9.3",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "nix", "bash", "markdown", "markdown_inline", "c", "vim", "vimdoc" },
        highlight = { enable = true },
      })
    end,
  },

  -- Autocompletion Engine
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }),
      })
    end,
  },

  -- LSP Configuration (Uses Nix-provided binaries)
{
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Keybindings on LSP attach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("gd", vim.lsp.buf.definition, "Goto Definition")
          map("K", vim.lsp.buf.hover, "Hover Documentation")
          map("<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
          map("]d", vim.diagnostic.goto_next, "Next Diagnostic")
        end,
      })

      -- Nix Language Server
      vim.lsp.config.nil_ls = {
        capabilities = capabilities,
      }
      vim.lsp.enable("nil_ls")

      -- Lua Language Server
      vim.lsp.config.lua_ls = {
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
        },
      }
      vim.lsp.enable("lua_ls")
    end,
  },

  -- File manager & Utilities
  {
    "stevearc/oil.nvim",
    opts = { default_file_explorer = true },
    keys = { { "`", "<CMD>Oil<CR>", desc = "Open parent directory" } },
    config = function()
        require('oil').setup {
          keymaps = {
            ['`'] = 'actions.parent',
            ['<Tab>'] = 'actions.select',
          },
        }
    end,
  },

  { "folke/snacks.nvim", priority = 1000, lazy = false, opts = {} },
  { "nvim-lua/plenary.nvim" },
  { "nvim-tree/nvim-web-devicons" },
  { "zbirenbaum/copilot.lua", event = "InsertEnter", opts = {} },
  { "tpope/vim-fugitive" },
  { "michaelrommel/nvim-silicon", opts = {} },
  { "epwalsh/obsidian.nvim", version = "*", lazy = true, ft = "markdown" },
  { "lervag/vimtex", ft = "tex" },
})
