-- lua/plugins/tools.lua
return {
  -- File manager
  {
    "stevearc/oil.nvim",
    opts = { default_file_explorer = true },
    keys = { { "`", "<CMD>Oil<CR>", desc = "Open parent directory" } },
    config = function()
      require("oil").setup({
        keymaps = {
          ["`"] = "actions.parent",
          ["<Tab>"] = "actions.select",
        },
      })
    end,
  },

  -- Other Utilities
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
    -- La configuración del paso 3 va acá adentro si usás lazy.nvim
  end,
},
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
        command = "VimtexClean"
      })
    end,
  },
}
