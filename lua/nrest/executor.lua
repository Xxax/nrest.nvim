local M = {}

-- URL encode special characters in query string
-- Only encodes the query part (after ?) to preserve the base URL structure
local function url_encode_query(url)
  -- Split URL at the first '?'
  local base, query = url:match('^([^?]+)%?(.+)$')

  if not query then
    -- No query string, return as-is
    return url
  end

  -- Encode special characters in the query string
  -- Encode spaces and other characters that curl doesn't handle well
  local encoded_query = query:gsub('([^%w%-%.%_%~%=%&])', function(c)
    return string.format('%%%02X', string.byte(c))
  end)

  return base .. '?' .. encoded_query
end

--- Execute HTTP request asynchronously using curl
--- @param request table Request object with method, url, headers, body
--- @param callback function Callback function(response) called on completion
--- @param config table Plugin configuration
function M.execute(request, callback, config)
  local curl_cmd = M.build_curl_command(request, config)

  local stdout_data = {}
  local stderr_data = {}
  local timeout_timer = nil
  local job_id = nil
  local callback_called = false

  -- Safe callback wrapper to prevent double invocation (race condition between timeout and on_exit)
  local function safe_callback(result)
    if not callback_called then
      callback_called = true
      callback(result)
    end
  end

  -- Execute curl command asynchronously
  job_id = vim.fn.jobstart(curl_cmd, {
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
      -- Cancel timeout timer if job completes
      if timeout_timer then
        vim.fn.timer_stop(timeout_timer)
      end

      if exit_code ~= 0 then
        local error_msg = table.concat(stderr_data, '\n')
        safe_callback({
          success = false,
          error = 'Request failed with exit code: ' .. exit_code .. '\n' .. error_msg,
        })
        return
      end

      -- Parse response from stdout
      local response = M.parse_curl_response(stdout_data)
      response.success = true

      safe_callback(response)
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })

  -- Set up timeout if configured
  if config and config.timeout and config.timeout > 0 then
    timeout_timer = vim.fn.timer_start(config.timeout, function()
      if job_id and vim.fn.jobwait({job_id}, 0)[1] == -1 then
        vim.fn.jobstop(job_id)
        safe_callback({
          success = false,
          error = 'Request timeout after ' .. config.timeout .. 'ms',
        })
      end
    end)
  end
end

-- Validate header value to prevent command injection
local function validate_header_value(value)
  -- Headers must not contain newlines or carriage returns
  if value:match('[\r\n]') then
    return false, 'Header value contains invalid characters (newline)'
  end
  return true
end

--- Build curl command arguments from request
--- @param request table Request object
--- @param config table Plugin configuration
--- @return table cmd Array of command arguments for vim.fn.jobstart
function M.build_curl_command(request, config)
  local cmd = { 'curl', '-i', '-s', '-L' }

  -- Add SSL verification skip if configured
  if config and config.skip_ssl_verification then
    table.insert(cmd, '-k')
  end

  -- Add digest auth if present in request metadata
  if request.digest_auth then
    table.insert(cmd, '--digest')
    table.insert(cmd, '-u')
    table.insert(cmd, request.digest_auth.username .. ':' .. request.digest_auth.password)
  end

  -- Add method
  table.insert(cmd, '-X')
  table.insert(cmd, request.method)

  -- Add headers with validation
  for key, value in pairs(request.headers) do
    local valid, err = validate_header_value(value)
    if not valid then
      vim.notify('Invalid header "' .. key .. '": ' .. err, vim.log.levels.WARN)
      -- Skip invalid header instead of failing entire request
    else
      table.insert(cmd, '-H')
      table.insert(cmd, key .. ': ' .. value)
    end
  end

  -- Add body if present
  if request.body then
    table.insert(cmd, '-d')
    table.insert(cmd, request.body)
  end

  -- Add --globoff to prevent curl from interpreting brackets/braces
  table.insert(cmd, '--globoff')

  -- URL-encode query parameters to handle spaces and special characters
  local encoded_url = url_encode_query(request.url)
  table.insert(cmd, encoded_url)

  return cmd
end

--- Parse curl response (with headers)
--- Handles redirects by parsing only the final response
--- @param lines table Array of response lines from curl
--- @return table response Parsed response {status_line, status_code, headers, body}
function M.parse_curl_response(lines)
  local response = {
    status_line = '',
    status_code = 0,
    headers = {},
    body = '',
  }

  local i = 1

  -- Skip intermediate responses (redirects, 100 Continue, etc.)
  -- Find the last HTTP status line before the body
  local last_status_index = 1
  for idx, line in ipairs(lines) do
    if line:match('^HTTP/%S+%s+%d+') then
      last_status_index = idx
    end
  end

  -- Start parsing from the last status line
  i = last_status_index

  -- Parse status line
  if i <= #lines then
    -- Remove CR characters from status line
    response.status_line = lines[i]:gsub('\r', '')
    local status_code = lines[i]:match('HTTP/%S+%s+(%d+)')
    if status_code then
      response.status_code = tonumber(status_code)
    end
    i = i + 1
  end

  -- Parse headers
  while i <= #lines do
    local line = lines[i]:gsub('\r', '')  -- Remove CR from header lines
    if line:match('^%s*$') then
      -- Empty line marks end of headers
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
    -- Remove CR characters from body lines
    local clean_line = lines[i]:gsub('\r', '')
    table.insert(body_lines, clean_line)
    i = i + 1
  end
  response.body = table.concat(body_lines, '\n')

  return response
end

return M
