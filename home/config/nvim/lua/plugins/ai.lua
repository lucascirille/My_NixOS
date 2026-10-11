-- lua/plugins/ai.lua
return {
  -- GitHub Copilot (Inline Autocomplete / Ghost Text)
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        panel = { enabled = false },
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 75,
          keymap = {
            accept = "<C-l>",
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

-- CodeCompanion.nvim (Chat & LLM Interface)
{
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      -- =====================================================================
      -- 1. SECURE CREDENTIAL LOADER (sops-nix integration)
      -- =====================================================================
      local file = io.open("/run/secrets/ai_models", "r") 
      local openrouter_key = ""
      
      if file then
        for line in file:lines() do
          if line:match("^OPENAI_API_KEY=") then
            openrouter_key = line:gsub("^OPENAI_API_KEY=", ""):gsub('["\']', '')
            break
          end
        end
        file:close()
      end

      -- =====================================================================
      -- 2. CODECOMPANION SETUP ("CAVEMAN" MODE)
      -- =====================================================================
      require("codecompanion").setup({
        -- Overwrite the default friendly personality to save prompt & output tokens
        opts = {
          system_prompt = "You are a minimalist, highly efficient AI coding assistant. Obey these rules strictly:\n1. NO reasoning, NO thought process, NO step-by-step explanations.\n2. NO pleasantries, NO greetings, NO conclusions, NO markdown fluff.\n3. Output ONLY the exact code or the direct answer requested.\n4. Be as brief as humanly possible.",
        },
        adapters = {
          http = {
            openrouter = function()
              return require("codecompanion.adapters").extend("openrouter", {
                env = {
                  api_key = openrouter_key,
                },
                schema = {
                  model = {
                    -- Kept mandatory per your request
                    default = "openrouter/free", 
                  },
                  max_tokens = {
                    default = 4096,
                  },
                  -- Instruct OpenRouter API to disable or hide reasoning tokens
                  reasoning = {
                    default = {
                      effort = "none",  -- Disables reasoning for models that allow it
                      exclude = true,   -- Hides <think> blocks from Neovim if the model forces them
                    },
                  },
                },
              })
            end,
          },
        },
        interactions = {
          chat = { adapter = "openrouter" },
          inline = { adapter = "openrouter" },
        },
      })
    end,
    -- =====================================================================
    -- 3. KEYMAPS
    -- =====================================================================
    keys = {
      { "<leader>cc", "<cmd>CodeCompanionChat<cr>", mode = { "n", "v" }, desc = "CodeCompanion Chat" },
      { "<leader>ca", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion Actions" },
      { "<leader>ci", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "CodeCompanion Inline" },
    },
  }
}
