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

--- Validate HTTP request structure and content
--- @param request table|nil The request object to validate
--- @return boolean valid True if request is valid
--- @return string|nil error Error message if validation fails
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

--- Parse the first HTTP request from buffer lines
--- @param lines table Array of buffer lines
--- @return table|nil request Parsed request object or nil if no request found
--- @field method string HTTP method (GET, POST, etc.)
--- @field url string Request URL
--- @field headers table<string, string> Request headers
--- @field body string|nil Request body
--- @field auth_line string|nil Auth directive line if present
--- @field start_line number Starting line number
--- @field end_line number Ending line number
function M.parse_request(lines)
  local requests = M.parse_all_requests(lines)
  if #requests > 0 then
    return requests[1]
  end
  return nil
end

--- Parse HTTP request at a specific cursor line
--- @param lines table Array of buffer lines
--- @param cursor_line number Current cursor line number
--- @return table|nil request Request object at cursor position or nil if not found
function M.parse_request_at_line(lines, cursor_line)
  local requests = M.parse_all_requests(lines)

  for _, request in ipairs(requests) do
    if cursor_line >= request.start_line and cursor_line <= request.end_line then
      return request
    end
  end

  return nil
end

--- Parse all HTTP requests in the buffer
--- @param lines table Array of buffer lines
--- @return table requests Array of parsed request objects
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
        auth = nil, -- Per-request auth directive
        start_line = i,
        end_line = i,
      }
      i = i + 1

      -- Parse auth directive and headers
      while i <= #lines do
        local current_line = lines[i]

        -- Check for auth directive
        if current_line:match('^%s*@auth%s+') then
          current_request.auth_line = current_line
          current_request.end_line = i
          i = i + 1
        -- Check for header
        elseif current_line:match('^%s*[%w%-]+%s*:%s*.+') then
          local key, value = current_line:match('^%s*([%w%-]+)%s*:%s*(.+)')
          if key and value then
            current_request.headers[key] = value
          end
          current_request.end_line = i
          i = i + 1
        else
          -- No more auth directives or headers
          break
        end
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
