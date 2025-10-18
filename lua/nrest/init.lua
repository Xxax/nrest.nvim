local M = {}

-- Plugin configuration
M.config = {
  -- Default configuration
  result_split_horizontal = false,
  result_split_in_place = false,
  skip_ssl_verification = false,
  timeout = 10000, -- Request timeout in milliseconds (10 seconds)
  highlight = {
    enabled = true,
    timeout = 150,
  },
  result = {
    show_url = true,
    show_http_info = true,
    show_headers = true,
    show_body = true,
  },
  -- Environment variables
  env_file = nil, -- Optional path to environment file (e.g., '.env.http')
  -- Custom keybindings
  keybindings = {
    run_request = '<leader>hr',
    run_request_under_cursor = '<leader>hc',
  },
}

-- Setup function to configure the plugin
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  -- Create autocommands for .http files
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'http',
    callback = function()
      require('nrest.keymaps').setup_buffer_keymaps()
    end,
  })
end

-- Main function to run HTTP request
function M.run()
  local parser = require('nrest.parser')
  local executor = require('nrest.executor')
  local ui = require('nrest.ui')
  local variables = require('nrest.variables')

  -- Get current buffer content
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Parse variables from buffer
  local buffer_vars = variables.parse_variables(lines)

  -- Load variables from env file if configured
  local env_vars = {}
  if M.config.env_file then
    env_vars = variables.load_env_file(M.config.env_file)
  end

  -- Merge variables (buffer vars override env file vars)
  local all_vars = vim.tbl_extend('force', env_vars, buffer_vars)

  -- Parse HTTP request
  local request = parser.parse_request(lines)

  if not request then
    vim.notify('No valid HTTP request found', vim.log.levels.ERROR)
    return
  end

  -- Substitute variables in request
  request = variables.substitute_request(request, all_vars)

  -- Validate request
  local valid, error_msg = parser.validate_request(request)
  if not valid then
    vim.notify('Invalid request: ' .. error_msg, vim.log.levels.ERROR)
    return
  end

  -- Execute request
  vim.notify('Executing request...', vim.log.levels.INFO)
  executor.execute(request, function(response)
    ui.show_response(response, M.config)
  end, M.config)
end

-- Run request under cursor
function M.run_at_cursor()
  local parser = require('nrest.parser')
  local executor = require('nrest.executor')
  local ui = require('nrest.ui')
  local variables = require('nrest.variables')

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Parse variables from buffer
  local buffer_vars = variables.parse_variables(lines)

  -- Load variables from env file if configured
  local env_vars = {}
  if M.config.env_file then
    env_vars = variables.load_env_file(M.config.env_file)
  end

  -- Merge variables (buffer vars override env file vars)
  local all_vars = vim.tbl_extend('force', env_vars, buffer_vars)

  local request = parser.parse_request_at_line(lines, cursor_line)

  if not request then
    vim.notify('No valid HTTP request found at cursor', vim.log.levels.ERROR)
    return
  end

  -- Substitute variables in request
  request = variables.substitute_request(request, all_vars)

  -- Validate request
  local valid, error_msg = parser.validate_request(request)
  if not valid then
    vim.notify('Invalid request: ' .. error_msg, vim.log.levels.ERROR)
    return
  end

  vim.notify('Executing request...', vim.log.levels.INFO)
  executor.execute(request, function(response)
    ui.show_response(response, M.config)
  end, M.config)
end

return M
