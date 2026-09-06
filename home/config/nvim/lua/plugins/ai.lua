-- lua/plugins/ai.lua
return {
  -- Layer 1: GitHub Copilot (Inline Autocomplete / Ghost Text)
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        panel = {
          enabled = false, -- Disabled because we use CodeCompanion for the heavy lifting
        },
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 75,
          keymap = {
            accept = "<C-l>", -- Press Ctrl+l to accept the ghost text
            accept_word = false,
            accept_line = false,
            next = "<C-j>",
            prev = "<C-k>",
            dismiss = "<C-e>",
          },
        },
      })
    end,
  },

  -- Layer 2: CodeCompanion (The AI Agent)
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "zbirenbaum/copilot.lua", -- Ensures Copilot loads first
    },
    config = function()
      require("codecompanion").setup({
        strategies = {
          chat = { adapter = "copilot" },
          inline = { adapter = "copilot" },
          agent = { adapter = "copilot" },
        },
      })

      -- Keybindings for CodeCompanion
      vim.keymap.set({ "n", "v" }, "<C-x>", "<cmd>CodeCompanionActions<cr>", { desc = "Open AI Action Palette" })
      vim.keymap.set({ "n", "v" }, "<leader>a", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "Toggle AI Chat" })
      vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { desc = "Add selection to AI Chat" })
    end,
  },
}
