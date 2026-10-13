return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.config").setup({
        -- ADDED: "yaml", "rust", "ron", "toml" at the end of the list
        ensure_installed = { "lua", "nix", "bash", "markdown", "markdown_inline", "c", "vim", "vimdoc", "yaml", "rust", "ron", "toml" },
        highlight = { enable = true },
      })
    end,
  }
}
