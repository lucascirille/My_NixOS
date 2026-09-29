return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  opts = {
    default = {
      -- Where to save the images globally or per project
      dir_path = "images", 
      -- Set to true if you want it to ask you for a file name before saving
      prompt_for_file_name = true, 
    },
    filetypes = {
      tex = {
        -- The exact LaTeX code it will inject when you paste an image
        template = [[
\begin{figure}[htpb]
  \centering
  \includegraphics[width=0.8\textwidth]{$FILE_PATH}
  \caption{$CURSOR}
  \label{fig:$FILE_NAME}
\end{figure}
]]
      }
    }
  },
  keys = {
    -- Map <leader>p to paste the image
    { "<leader>pi", "<cmd>PasteImage<cr>", desc = "Paste image from clipboard" },
  },
}
