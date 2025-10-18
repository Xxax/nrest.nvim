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
    folding = true, -- Enable folding for headers section
  },
  -- Response formatting
  format_response = true, -- Format response body (JSON with jq, etc.)
  -- Environment variables
  env_file = nil, -- Optional path to environment file (e.g., '.env.http')
  -- Set to 'auto' to automatically search for .env.http in directory hierarchy
  -- Set to specific path to use that file
  -- Set to nil to disable env file loading
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
  local auth = require('nrest.auth')

  -- Get current buffer content
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Parse variables from buffer
  local buffer_vars = variables.parse_variables(lines)

  -- Load variables from env file if configured
  local env_vars = {}
  if M.config.env_file then
    local env_file_path = M.config.env_file

    -- Auto-discover .env.http if configured
    if env_file_path == 'auto' then
      local buffer_dir = vim.fn.expand('%:p:h')
      env_file_path = variables.find_env_file(buffer_dir)
    end

    if env_file_path then
      env_vars = variables.load_env_file(env_file_path)
    end
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

  -- Parse and apply authentication
  -- Priority: request-scoped auth > file-level auth
  local auth_config, auth_error

  if request.auth_line then
    -- Request has per-request auth directive
    auth_config, auth_error = auth.parse_auth_line(request.auth_line)
  else
    -- Fall back to file-level auth (backward compatibility)
    auth_config, auth_error = auth.parse_auth(lines)
  end

  if auth_error then
    vim.notify('Auth error: ' .. auth_error, vim.log.levels.ERROR)
    return
  end

  if auth_config then
    -- Substitute variables in auth parameters
    if auth_config.params then
      for i, param in ipairs(auth_config.params) do
        auth_config.params[i] = variables.substitute(param, all_vars)
      end
    end

    local auth_ok, auth_apply_error = auth.apply_auth(request, auth_config)
    if not auth_ok then
      vim.notify('Auth error: ' .. auth_apply_error, vim.log.levels.ERROR)
      return
    end
  end

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
  local auth = require('nrest.auth')

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Parse variables from buffer
  local buffer_vars = variables.parse_variables(lines)

  -- Load variables from env file if configured
  local env_vars = {}
  if M.config.env_file then
    local env_file_path = M.config.env_file

    -- Auto-discover .env.http if configured
    if env_file_path == 'auto' then
      local buffer_dir = vim.fn.expand('%:p:h')
      env_file_path = variables.find_env_file(buffer_dir)
    end

    if env_file_path then
      env_vars = variables.load_env_file(env_file_path)
    end
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

  -- Parse and apply authentication
  -- Priority: request-scoped auth > file-level auth
  local auth_config, auth_error

  if request.auth_line then
    -- Request has per-request auth directive
    auth_config, auth_error = auth.parse_auth_line(request.auth_line)
  else
    -- Fall back to file-level auth (backward compatibility)
    auth_config, auth_error = auth.parse_auth(lines)
  end

  if auth_error then
    vim.notify('Auth error: ' .. auth_error, vim.log.levels.ERROR)
    return
  end

  if auth_config then
    -- Substitute variables in auth parameters
    if auth_config.params then
      for i, param in ipairs(auth_config.params) do
        auth_config.params[i] = variables.substitute(param, all_vars)
      end
    end

    local auth_ok, auth_apply_error = auth.apply_auth(request, auth_config)
    if not auth_ok then
      vim.notify('Auth error: ' .. auth_apply_error, vim.log.levels.ERROR)
      return
    end
  end

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
