-- lua/plugins/tools.lua
return {
  -- File manager
  {
    "stevearc/oil.nvim",
    keys = {
      { "`", "<CMD>Oil<CR>", desc = "Open parent directory" },
    },
    opts = {
      default_file_explorer = true,
      keymaps = {
        ["`"] = "actions.parent",
        ["<Tab>"] = "actions.select",
      },
    },
  },

  -- Git & Diff Utilities
  { "tpope/vim-fugitive" },
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Abrir Diffview / Merge Tool" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Cerrar Diffview" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Historial del archivo actual" },
    },
    config = function()
      local actions = require("diffview.actions")

      require("diffview").setup({
        enhanced_diff_hl = true,
        view = {
          default = {
            layout = "diff2_horizontal",
          },
          merge_tool = {
            layout = "diff3_mixed",
            disable_diagnostics = true,
            winbar_info = true,
          },
        },
        keymaps = {
          view = {
            -- Navegación entre conflictos (]x = siguiente, [x = anterior)
            { "n", "]x", actions.next_conflict, { desc = "Siguiente conflicto" } },
            { "n", "[x", actions.prev_conflict, { desc = "Conflicto anterior" } },
            -- Elegir qué versión conservar desde el panel inferior
            { "n", "<leader>co", actions.conflict_choose("ours"), { desc = "Elegir OURS (Local)" } },
            { "n", "<leader>ct", actions.conflict_choose("theirs"), { desc = "Elegir THEIRS (Entrante)" } },
            { "n", "<leader>cb", actions.conflict_choose("base"), { desc = "Elegir BASE (Ancestro)" } },
            { "n", "<leader>ca", actions.conflict_choose("all"), { desc = "Elegir TODOS" } },
            { "n", "dx", actions.conflict_choose("none"), { desc = "Borrar todo el conflicto" } },
          },
        },
      })
    end,
  },

  -- Notes & LaTeX
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      workspaces = {
        {
          name = "second_brain",
          path = "~/Documents/second_brain",
        },
      },
      ui = { enable = false },
    },
  },
  {
    "lervag/vimtex",
    ft = "tex",
    keys = {
      { "<leader>vc", "<cmd>VimtexCompile<CR>", desc = "VimTeX Compile" },
    },
    init = function()
      vim.g.vimtex_view_general_viewer = "zathura"

      -- Tell VimTeX to automatically clean up when its compiler stops
      vim.api.nvim_create_autocmd("User", {
        pattern = "VimtexEventQuit",
        command = "VimtexClean",
      })
    end,
  },
}
