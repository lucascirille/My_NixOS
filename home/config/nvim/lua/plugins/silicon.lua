-- lua/plugins/silicon.lua
return {
  {
    "michaelrommel/nvim-silicon",
    lazy = true,
    cmd = "Silicon",
    main = "nvim-silicon",
    opts = {
      -- Font settings
      font = "JetBrainsMono Nerd Font=34",

      -- Syntax highlighting theme (matches your dark style)
      theme = "Dracula",

      -- Window / padding aesthetics
      pad_horiz = 40,
      pad_vert = 40,
      line_offset = 1,
      line_pad = 2,
      shadow_blur_radius = 16,
      shadow_offset_x = 0,
      shadow_offset_y = 8,
      shadow_color = "#101014",
      gobble = true,

      -- Window title
      window_title = function()
        local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
        local fname = vim.fn.fnamemodify(buf_name, ":t")
        return fname ~= "" and fname or "snippet"
      end,

      -- Output & clipboard
      to_clipboard = true,
      output = function()
        local dir = vim.fn.expand("~/Pictures/screenshots")
        if vim.fn.isdirectory(dir) == 0 then
          vim.fn.mkdir(dir, "p")
        end
        local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
        local fname = vim.fn.fnamemodify(buf_name, ":t")
        if fname == "" then
          fname = "snippet"
        end
        return dir .. "/" .. fname .. "_" .. os.date("%Y-%m-%d_%H-%M-%S") .. ".png"
      end,
    },
    keys = {
      {
        "<leader>sc",
        function()
          require("nvim-silicon").clip()
        end,
        mode = "v",
        desc = "Copy code screenshot to clipboard",
      },
      {
        "<leader>sf",
        function()
          require("nvim-silicon").file()
        end,
        mode = "v",
        desc = "Save code screenshot to ~/Pictures/screenshots",
      },
      {
        "<leader>ss",
        function()
          require("nvim-silicon").shoot()
        end,
        mode = "v",
        desc = "Save screenshot and copy to clipboard",
      },
    },
  },
}
