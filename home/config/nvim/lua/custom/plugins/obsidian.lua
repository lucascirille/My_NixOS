return {
  'epwalsh/obsidian.nvim',
  version = '*', -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = 'markdown',
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  event = {
    -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    -- refer to `:h file-pattern` for more examples
    'BufReadPre /home/dneit/Documents/my_digital_brain/*.md',
    'BufNewFile /home/dneit/Documents/my_digital_brain/*.md',
  },
  dependencies = {
    -- Required.
    'nvim-lua/plenary.nvim',

    -- see below for full list of optional dependencies 👇
  },
  opts = {
    workspaces = {
      {
        name = 'personal',
        path = '~/Documents/my_digital_brain',
      },
      -- {
      --   name = 'work',
      --   path = '~/vaults/work',
      -- },
    },

    -- see below for full list of options 👇
  },
  config = function(_, opts)
    require('obsidian').setup(opts)

    -- Activar conceallevel=2 solo cuando se abre un archivo Obsidian
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown', -- o "obsidian" si usás ese filetype
      callback = function()
        vim.wo.conceallevel = 2
      end,
    })
  end,
}
