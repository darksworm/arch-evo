-- Disable format-on-save for Kotlin files.
-- The lazyvim lang.kotlin extra enables ktlint reformatting on save via
-- conform.nvim; this turns off LazyVim's autoformat for kotlin buffers only.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "kotlin",
  callback = function()
    vim.b.autoformat = false
  end,
})

return {}
