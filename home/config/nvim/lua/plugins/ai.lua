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
      -- We read the API key directly from the local filesystem via Lua.
      -- This bypasses Neovim's background shell, preventing pipeline/parsing 
      -- errors when reading strict root-owned sops-nix secrets.
      local file = io.open("/run/secrets/ai_models", "r") 
      local openrouter_key = ""
      
      if file then
        for line in file:lines() do
          -- Extract the key strictly from the OPENAI_API_KEY assignment
          if line:match("^OPENAI_API_KEY=") then
            openrouter_key = line:gsub("^OPENAI_API_KEY=", ""):gsub('["\']', '')
            break
          end
        end
        file:close()
      end

      -- =====================================================================
      -- 2. CODECOMPANION SETUP (v19+ Architecture)
      -- =====================================================================
      require("codecompanion").setup({
        adapters = {
          -- In CodeCompanion v19+, adapters must be nested under the 'http' table
          http = {
            openrouter = function()
              return require("codecompanion.adapters").extend("openrouter", {
                env = {
                  -- Inject the parsed key directly into the adapter environment
                  api_key = openrouter_key,
                },
                schema = {
                  model = {
                    -- Use OpenRouter's free model auto-router
                    default = "openrouter/free",
                  },
                  max_tokens = {
                    -- CRITICAL FIX: OpenRouter's free tier has an 8888 credit limit.
                    -- CodeCompanion defaults to requesting 65536 tokens, triggering
                    -- a 402 Payment Required error. We force it to 4096 here.
                    default = 4096,
                  },
                },
              })
            end,
          },
        },
        -- 'interactions' replaces the deprecated 'strategies' table in v19+
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
      -- Note: 'Toggle' is explicitly omitted from the Chat command to force 
      -- Neovim to spawn a fresh chat buffer, preventing old cache corruption.
      { "<leader>cc", "<cmd>CodeCompanionChat<cr>", mode = { "n", "v" }, desc = "CodeCompanion Chat" },
      { "<leader>ca", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion Actions" },
      { "<leader>ci", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "CodeCompanion Inline" },
    },
  },
}
