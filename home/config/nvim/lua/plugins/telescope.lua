-- home/config/nvim/lua/plugins/telescope.lua
return {
  -- Fuzzy Finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>sf", "<cmd>Telescope find_files<cr>", desc = "Search Files" },
      { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Search by Grep" },
      { "<leader><space>", "<cmd>Telescope buffers<cr>", desc = "Find existing buffers" },
    },
  },
  
  -- Shortcut Menu Popup
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  }
}
