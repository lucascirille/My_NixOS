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
  { "michaelrommel/nvim-silicon", opts = {} },
  { "epwalsh/obsidian.nvim", version = "*", lazy = true, ft = "markdown" },
  {
    "lervag/vimtex",
    ft = "tex",
    keys = {
      { "<leader>vc", "<cmd>VimtexCompile<CR>", desc = "VimTeX Compile" },
    },
    init = function()
-- Use the "general" method instead of the specialized "zathura" backend
      vim.g.vimtex_view_method = "general"
      vim.g.vimtex_view_general_viewer = "zathura"
      vim.g.vimtex_view_zathura = { xdotool = 0 }

      -- Tell VimTeX to automatically clean up when its compiler stops
      vim.api.nvim_create_autocmd("User", {
        pattern = "VimtexEventQuit",
        command = "VimtexClean"
      })
    end,
  },
}
