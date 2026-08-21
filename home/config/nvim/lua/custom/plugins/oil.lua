return {
  'stevearc/oil.nvim',
  config = function()
    require('oil').setup {
      keymaps = {
        ['`'] = 'actions.parent',
        ['<Tab>'] = 'actions.select',
      },
    }
    vim.keymap.set('n', '`', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
  end,
}
