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
  { "lervag/vimtex", ft = "tex" },
}
