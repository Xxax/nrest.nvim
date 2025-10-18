local M = {}

-- Valid HTTP methods
local VALID_METHODS = {
  GET = true,
  POST = true,
  PUT = true,
  PATCH = true,
  DELETE = true,
  HEAD = true,
  OPTIONS = true,
  CONNECT = true,
  TRACE = true,
}

-- Validate HTTP request
function M.validate_request(request)
  if not request then
    return false, 'Request is nil'
  end

  -- Validate method
  if not request.method or not VALID_METHODS[request.method] then
    return false, 'Invalid HTTP method: ' .. (request.method or 'nil')
  end

  -- Validate URL
  if not request.url or request.url == '' then
    return false, 'URL is missing'
  end

  -- Validate URL scheme
  if not request.url:match('^https?://') then
    return false, 'URL must start with http:// or https://'
  end

  return true, nil
end

-- Parse HTTP request from lines
function M.parse_request(lines)
  local requests = M.parse_all_requests(lines)
  if #requests > 0 then
    return requests[1]
  end
  return nil
end

-- Parse HTTP request at specific line
function M.parse_request_at_line(lines, cursor_line)
  local requests = M.parse_all_requests(lines)

  for _, request in ipairs(requests) do
    if cursor_line >= request.start_line and cursor_line <= request.end_line then
      return request
    end
  end

  return nil
end

-- Parse all HTTP requests in the buffer
function M.parse_all_requests(lines)
  local requests = {}
  local current_request = nil
  local i = 1

  while i <= #lines do
    local line = lines[i]

    -- Skip empty lines, comments, variable definitions, and auth directives outside of requests
    if not current_request and (line:match('^%s*$') or line:match('^%s*#') or line:match('^%s*//') or line:match('^@[%w_]+%s*=') or line:match('^%s*@auth%s+')) then
      i = i + 1
    -- Detect request separator (###)
    elseif line:match('^###') then
      if current_request then
        current_request.end_line = i - 1
        table.insert(requests, current_request)
        current_request = nil
      end
      i = i + 1
    -- Detect HTTP method
    elseif line:match('^%s*(%u+)%s+(.+)') then
      if current_request then
        current_request.end_line = i - 1
        table.insert(requests, current_request)
      end

      local method, url = line:match('^%s*(%u+)%s+(.+)')
      current_request = {
        method = method,
        url = url:gsub('%s+HTTP/.*$', ''),
        headers = {},
        body = nil,
        start_line = i,
        end_line = i,
      }
      i = i + 1

      -- Parse headers
      while i <= #lines and lines[i]:match('^%s*[%w%-]+%s*:%s*.+') do
        local key, value = lines[i]:match('^%s*([%w%-]+)%s*:%s*(.+)')
        if key and value then
          current_request.headers[key] = value
        end
        current_request.end_line = i
        i = i + 1
      end

      -- Skip empty line between headers and body
      if i <= #lines and lines[i]:match('^%s*$') then
        current_request.end_line = i
        i = i + 1
      end

      -- Parse body
      local body_lines = {}
      while i <= #lines do
        local body_line = lines[i]
        -- Stop at next request or separator
        if body_line:match('^###') or body_line:match('^%s*(%u+)%s+(.+)') then
          break
        end
        table.insert(body_lines, body_line)
        current_request.end_line = i
        i = i + 1
      end

      if #body_lines > 0 then
        -- Remove trailing empty lines from body
        while #body_lines > 0 and body_lines[#body_lines]:match('^%s*$') do
          table.remove(body_lines)
          current_request.end_line = current_request.end_line - 1
        end
        if #body_lines > 0 then
          current_request.body = table.concat(body_lines, '\n')
        end
      end
    else
      i = i + 1
    end
  end

  -- Add last request
  if current_request then
    current_request.end_line = #lines
    table.insert(requests, current_request)
  end

  return requests
end

return M
