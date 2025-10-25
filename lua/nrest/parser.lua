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

--- Resolve file references in body content
--- Supports vscode-restclient syntax: < ./file.json
--- @param body string Body content potentially containing file references
--- @return string body Resolved body content with file contents
function M._resolve_file_references(body)
  if not body then
    return body
  end

  -- Check if the body is a single file reference
  local file_ref = body:match('^%s*<%s*(.+)%s*$')
  if file_ref then
    -- Load entire file content
    local file_path = vim.fn.expand(file_ref)
    local file = io.open(file_path, 'r')
    if file then
      local content = file:read('*all')
      file:close()
      return content
    else
      vim.notify('Failed to read file: ' .. file_path, vim.log.levels.WARN)
      return body
    end
  end

  -- Support inline file references (e.g., in multipart)
  -- Replace lines like "< ./file.png" with file content
  local result = body:gsub('(^[^\n]*<%s*([^\n]+))', function(full_line, file_ref_inline)
    local file_path = vim.fn.expand(file_ref_inline:gsub('^%s+', ''):gsub('%s+$', ''))
    local file = io.open(file_path, 'r')
    if file then
      local content = file:read('*all')
      file:close()
      -- Replace the line with file content (preserve line prefix before <)
      local prefix = full_line:match('^(.-)<%s*')
      return (prefix or '') .. content
    else
      vim.notify('Failed to read file: ' .. file_path, vim.log.levels.WARN)
      return full_line
    end
  end)

  return result
end

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

  local pending_request_name = nil -- Store @name for next request

  while i <= #lines do
    local line = lines[i]

    -- Check for request naming (# @name or // @name)
    local request_name = line:match('^%s*#%s*@name%s+(.+)') or line:match('^%s*//%s*@name%s+(.+)')
    if request_name then
      pending_request_name = request_name:gsub('%s+$', '') -- Trim trailing spaces
      i = i + 1
    -- Skip empty lines, comments, variable definitions, and auth directives outside of requests
    elseif not current_request and (line:match('^%s*$') or line:match('^%s*#') or line:match('^%s*//') or line:match('^@[%w_]+%s*=') or line:match('^%s*@auth%s+')) then
      i = i + 1
    -- Detect request separator (###)
    elseif line:match('^###') then
      if current_request then
        current_request.end_line = i - 1
        table.insert(requests, current_request)
        current_request = nil
      end
      -- Reset pending name after separator
      pending_request_name = nil
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
        name = pending_request_name, -- Assigned name from @name directive
        start_line = i,
        end_line = i,
      }
      pending_request_name = nil -- Reset after assignment
      i = i + 1

      -- Parse multiline query parameters (vscode-restclient compatible)
      while i <= #lines do
        local current_line = lines[i]
        -- Check for query parameters starting with ? or &
        local query_param = current_line:match('^%s*([?&].+)')
        if query_param then
          -- Remove leading/trailing whitespace
          query_param = query_param:gsub('^%s+', ''):gsub('%s+$', '')
          -- Append to URL
          if query_param:match('^%?') then
            -- First query param with ?
            if current_request.url:match('%?') then
              -- URL already has ?, replace ? with &
              current_request.url = current_request.url .. '&' .. query_param:sub(2)
            else
              current_request.url = current_request.url .. query_param
            end
          else
            -- Additional query param with &
            current_request.url = current_request.url .. query_param
          end
          current_request.end_line = i
          i = i + 1
        else
          break
        end
      end

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
          local body = table.concat(body_lines, '\n')
          -- Check for file reference (< ./file.json)
          current_request.body = M._resolve_file_references(body)
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
