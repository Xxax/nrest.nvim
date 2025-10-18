local M = {}

-- Setup buffer keymaps for .http files
function M.setup_buffer_keymaps()
  local nrest = require('nrest')
  local config = nrest.config

  -- Set buffer-local keymaps
  local opts = { noremap = true, silent = true, buffer = true }

  -- Run request under cursor
  vim.keymap.set('n', config.keybindings.run_request_under_cursor, function()
    require('nrest').run_at_cursor()
  end, vim.tbl_extend('force', opts, { desc = 'Run HTTP request under cursor' }))

  -- Run all requests (first one)
  vim.keymap.set('n', config.keybindings.run_request, function()
    require('nrest').run()
  end, vim.tbl_extend('force', opts, { desc = 'Run HTTP request' }))
end

return M
