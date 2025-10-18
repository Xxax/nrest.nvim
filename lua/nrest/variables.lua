local M = {}

-- Store for environment variables
-- Structure: { variable_name = value }
local variables = {}

-- Parse variable definitions from lines
-- Format: @variableName = value
function M.parse_variables(lines)
  local vars = {}

  for _, line in ipairs(lines) do
    -- Match @variableName = value
    local name, value = line:match('^@([%w_]+)%s*=%s*(.+)$')
    if name and value then
      -- Trim whitespace from value
      value = value:match('^%s*(.-)%s*$')

      -- Substitute system environment variables in the value
      -- This allows @apiKey = $USER to work correctly
      value = M.substitute_system_env(value)

      vars[name] = value
    end
  end

  return vars
end

-- Substitute only system environment variables
-- Separate function to avoid circular dependency
function M.substitute_system_env(text)
  if not text then
    return text
  end

  -- Replace $VAR or ${VAR} with system environment variables
  local result = text:gsub('%$({?)([%w_]+)(}?)', function(open_brace, var_name, close_brace)
    -- Validate matching braces
    if (open_brace == '{' and close_brace ~= '}') or (open_brace == '' and close_brace == '}') then
      -- Malformed, keep original
      return '$' .. open_brace .. var_name .. close_brace
    end

    -- Get system environment variable
    local env_value = vim.env[var_name] or os.getenv(var_name)
    if env_value then
      return env_value
    else
      -- Keep original if not found
      return '$' .. open_brace .. var_name .. close_brace
    end
  end)

  return result
end

-- Load variables from environment file
function M.load_env_file(file_path)
  if not file_path or file_path == '' then
    return {}
  end

  -- Check if file exists and is readable
  local file = io.open(file_path, 'r')
  if not file then
    return {}
  end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  return M.parse_variables(lines)
end

-- Set variables (merges with existing)
function M.set_variables(vars)
  for name, value in pairs(vars) do
    variables[name] = value
  end
end

-- Get all variables
function M.get_variables()
  return vim.tbl_extend('force', {}, variables)
end

-- Clear all variables
function M.clear_variables()
  variables = {}
end

-- Substitute variables in text
-- Replaces {{variableName}} with actual values
-- Also supports system environment variables with $VAR or ${VAR}
function M.substitute(text, vars)
  if not text then
    return text
  end

  -- Use provided vars or global variables
  local var_table = vars or variables

  -- First, replace system environment variables: $VAR or ${VAR}
  local result = M.substitute_system_env(text)

  -- Then, replace {{variableName}} patterns with user-defined variables
  result = result:gsub('{{([%w_]+)}}', function(var_name)
    local value = var_table[var_name]
    if value then
      return value
    else
      -- Keep original if variable not found
      return '{{' .. var_name .. '}}'
    end
  end)

  return result
end

-- Substitute variables in request object
function M.substitute_request(request, vars)
  if not request then
    return request
  end

  local var_table = vars or variables

  -- Substitute in URL
  if request.url then
    request.url = M.substitute(request.url, var_table)
  end

  -- Substitute in headers
  if request.headers then
    local new_headers = {}
    for key, value in pairs(request.headers) do
      local new_key = M.substitute(key, var_table)
      local new_value = M.substitute(value, var_table)
      new_headers[new_key] = new_value
    end
    request.headers = new_headers
  end

  -- Substitute in body
  if request.body then
    request.body = M.substitute(request.body, var_table)
  end

  return request
end

return M
