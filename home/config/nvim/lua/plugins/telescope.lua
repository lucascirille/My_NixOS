-- home/config/nvim/lua/plugins/telescope.lua
return {
  -- Fuzzy Finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    
    -- 1. Agregamos las opciones de configuración para Telescope aquí:
    opts = function()
      local actions = require("telescope.actions")
      return {
        defaults = {
          mappings = {
            i = { -- 'i' aplica al modo "insertar" (cuando escribes en el prompt)
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
            },
          },
        },
      }
    end,
    
    keys = {
      { "<leader>sf", "<cmd>Telescope find_files<cr>", desc = "Search Files" },
      { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Search by Grep" },
      { "<leader><space>", "<cmd>Telescope buffers<cr>", desc = "Find existing buffers" },
      { 
        "<leader>sn", 
        function() 
          require("telescope.builtin").find_files { cwd = vim.fn.stdpath("config") } 
        end, 
        desc = "Search Neovim config" 
      },
    },
  },
  
  -- Shortcut Menu Popup
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  }
}
