-- lua/plugins/ui.lua
return {
  -- Theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },

  -- Bufferline (Tabs for open files)
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup({
        options = {
          always_show_bufferline = true,
          mode = "buffers",
        }
      })

      vim.keymap.set("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Go to next open file/buffer" })
      vim.keymap.set("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Go to previous open file/buffer" })
      vim.keymap.set("n", "<leader>x", "<Cmd>bdelete<CR>", { desc = "Close current buffer" })
    end,
  },
}
