return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "nix", "bash", "markdown", "markdown_inline", "c", "vim", "vimdoc" },
        highlight = { enable = true },
      })
    end,
  }
}
