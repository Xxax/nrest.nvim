-- nrest.nvim - HTTP REST client for Neovim
-- Automatically loaded when Neovim starts

if vim.g.loaded_nrest then
  return
end
vim.g.loaded_nrest = 1

-- Define commands
vim.api.nvim_create_user_command('NrestRun', function()
  require('nrest').run()
end, { desc = 'Run HTTP request' })

vim.api.nvim_create_user_command('NrestRunCursor', function()
  require('nrest').run_at_cursor()
end, { desc = 'Run HTTP request under cursor' })

-- Define filetype detection for .http and .rest files
vim.filetype.add({
  extension = {
    http = 'http',
    rest = 'http', -- vscode-restclient compatibility
  },
})
