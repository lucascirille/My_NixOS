return {
  'michaelrommel/nvim-silicon',
  lazy = true,
  cmd = 'Silicon',
  main = 'nvim-silicon',
  opts = {
    -- Configuration here, or leave empty to use defaults
    to_clipboard = true,
    output = function()
      return '/home/dneit/Pictures/Code/' .. os.date '!%Y-%m-%dT%H-%M-%SZ' .. '_code.png'
    end,
    -- End configuration
    line_offset = function(args)
      return args.line1
    end,
  },
  keys = {
    {
      '<leader>sc',
      function()
        require('nvim-silicon').clip()
      end,
      mode = 'v',
      desc = 'Copy code screenshot to clipboard',
    },
    {
      '<leader>sf',
      function()
        require('nvim-silicon').file()
      end,
      mode = 'v',
      desc = 'Save code screenshot as file',
    },
    {
      '<leader>ss',
      function()
        require('nvim-silicon').shoot()
      end,
      mode = 'v',
      desc = 'Create code screenshot',
    },
  },
}
