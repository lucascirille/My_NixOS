-- lua/plugins/markdown.lua
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown", "codecompanion" },
    opts = {
      heading = {
        sign = true,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        signs = { "󰫎 " },
        width = "block",
        left_pad = 1,
        right_pad = 2,
      },
      code = {
        sign = false,
        style = "full",
        position = "left",
        width = "block",
        left_pad = 1,
        right_pad = 2,
        border = "thin",
      },
      bullet = {
        icons = { "●", "○", "◆", "◇" },
        right_pad = 1,
      },
      checkbox = {
        enabled = true,
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 " },
        custom = {
          todo = { raw = "[-]", rendered = "󰥔 Todo", highlight = "RenderMarkdownTodo" },
        },
      },
      pipe_table = {
        preset = "round",
        style = "full",
        cell = "padded",
        padding = 1,
      },
      callout = {
        note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
        tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
        important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
        warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
        caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
      },
      link = {
        enabled = true,
        image = "󰥶 ",
        hyperlink = "󰌹 ",
        custom = {
          web = { pattern = "^http[s]?://", icon = "󰖟 " },
          youtube = { pattern = "youtube%.com", icon = "󰗃 " },
          github = { pattern = "github%.com", icon = "󰊤 " },
        },
      },
      anti_conceal = {
        enabled = true,
      },
    },
    keys = {
      {
        "<leader>tm",
        "<cmd>RenderMarkdown toggle<CR>",
        desc = "Toggle Markdown Render",
        ft = { "markdown", "codecompanion" },
      },
    },
  },
}
