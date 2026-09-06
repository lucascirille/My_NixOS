-- lua/plugins/treesitter.lua
return {
  {
    "nvim-treesitter/nvim-treesitter",
    tag = "v0.9.3",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "nix", "bash", "markdown", "markdown_inline", "c", "vim", "vimdoc" },
        highlight = { enable = true },
      })
    end,
  }
}
