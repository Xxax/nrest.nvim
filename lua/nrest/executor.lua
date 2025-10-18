local M = {}

-- Execute HTTP request using curl
function M.execute(request, callback)
  local curl_cmd = M.build_curl_command(request)

  local stdout_data = {}
  local stderr_data = {}

  -- Execute curl command asynchronously
  vim.fn.jobstart(curl_cmd, {
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout_data, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr_data, data)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        local error_msg = table.concat(stderr_data, '\n')
        callback({
          success = false,
          error = 'Request failed with exit code: ' .. exit_code .. '\n' .. error_msg,
        })
        return
      end

      -- Parse response from stdout
      local response = M.parse_curl_response(stdout_data)
      response.success = true

      callback(response)
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

-- Build curl command from request
function M.build_curl_command(request)
  local cmd = { 'curl', '-i', '-s', '-L' }

  -- Add method
  table.insert(cmd, '-X')
  table.insert(cmd, request.method)

  -- Add headers
  for key, value in pairs(request.headers) do
    table.insert(cmd, '-H')
    table.insert(cmd, key .. ': ' .. value)
  end

  -- Add body if present
  if request.body then
    table.insert(cmd, '-d')
    table.insert(cmd, request.body)
  end

  -- Add URL
  table.insert(cmd, request.url)

  return cmd
end

-- Parse curl response (with headers)
function M.parse_curl_response(lines)
  local response = {
    status_line = '',
    status_code = 0,
    headers = {},
    body = '',
  }

  local i = 1
  local in_body = false

  -- Parse status line
  if i <= #lines then
    response.status_line = lines[i]
    local status_code = lines[i]:match('HTTP/%S+%s+(%d+)')
    if status_code then
      response.status_code = tonumber(status_code)
    end
    i = i + 1
  end

  -- Parse headers
  while i <= #lines do
    local line = lines[i]
    if line:match('^%s*$') then
      -- Empty line marks end of headers
      in_body = true
      i = i + 1
      break
    end

    local key, value = line:match('^([^:]+):%s*(.+)')
    if key and value then
      response.headers[key] = value
    end
    i = i + 1
  end

  -- Parse body
  local body_lines = {}
  while i <= #lines do
    table.insert(body_lines, lines[i])
    i = i + 1
  end
  response.body = table.concat(body_lines, '\n')

  return response
end

return M
