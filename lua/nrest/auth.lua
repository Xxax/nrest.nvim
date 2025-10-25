local M = {}

-- Supported authentication types
local AUTH_TYPES = {
  basic = true,
  bearer = true,
  apikey = true,
  digest = true,
}

-- Pure Lua Base64 encoding (no shell dependency, prevents injection)
-- Based on: https://en.wikipedia.org/wiki/Base64
local function base64_encode(data)
  local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  return ((data:gsub('.', function(x)
    local r, b_val = '', x:byte()
    for i = 8, 1, -1 do
      r = r .. (b_val % 2 ^ i - b_val % 2 ^ (i - 1) > 0 and '1' or '0')
    end
    return r
  end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if #x < 6 then
      return ''
    end
    local c = 0
    for i = 1, 6 do
      c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
    end
    return b:sub(c + 1, c + 1)
  end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

--- Parse authentication directive from buffer lines (file-level)
--- Searches all lines for @auth directive
--- Syntax: @auth <type> <params...>
--- Examples:
---   @auth basic username password
---   @auth bearer token123
---   @auth apikey X-API-Key mykey123
---   @auth digest username password
--- @param lines table Array of buffer lines
--- @return table|nil config Auth configuration {type, params} or nil if not found
--- @return string|nil error Error message if parsing fails
function M.parse_auth(lines)
  for _, line in ipairs(lines) do
    local auth_line = line:match('^%s*@auth%s+(.+)')
    if auth_line then
      local parts = {}
      for part in auth_line:gmatch('%S+') do
        table.insert(parts, part)
      end

      if #parts == 0 then
        return nil, 'Auth directive is empty'
      end

      local auth_type = parts[1]:lower()
      if not AUTH_TYPES[auth_type] then
        return nil, 'Invalid auth type: ' .. parts[1]
      end

      return {
        type = auth_type,
        params = { unpack(parts, 2) },
      }, nil
    end
  end

  return nil, nil -- No auth directive found
end

--- Parse authentication directive from a single line (request-scoped)
--- Syntax: @auth <type> <params...>
--- @param line string|nil Line containing auth directive
--- @return table|nil config Auth configuration {type, params} or nil if not found
--- @return string|nil error Error message if parsing fails
function M.parse_auth_line(line)
  if not line then
    return nil, nil
  end

  local auth_line = line:match('^%s*@auth%s+(.+)')
  if not auth_line then
    return nil, nil -- No auth directive in this line
  end

  local parts = {}
  for part in auth_line:gmatch('%S+') do
    table.insert(parts, part)
  end

  if #parts == 0 then
    return nil, 'Auth directive is empty'
  end

  local auth_type = parts[1]:lower()
  if not AUTH_TYPES[auth_type] then
    return nil, 'Invalid auth type: ' .. parts[1]
  end

  return {
    type = auth_type,
    params = { unpack(parts, 2) },
  }, nil
end

--- Parse standard Authorization header (vscode-restclient compatible)
--- Detects and parses Authorization headers with special syntax
--- @param request table Request object to check and modify
--- @return boolean modified True if Authorization header was parsed
function M.parse_standard_auth_header(request)
  if not request.headers['Authorization'] then
    return false
  end

  local auth_value = request.headers['Authorization']

  -- Parse "Basic username:password" or "Basic username password"
  local basic_user, basic_pass = auth_value:match('^Basic%s+([^:%s]+):([^%s]+)$')
  if not basic_user then
    basic_user, basic_pass = auth_value:match('^Basic%s+([^%s]+)%s+([^%s]+)$')
  end
  if basic_user and basic_pass then
    -- Convert to base64 encoded format
    local credentials = basic_user .. ':' .. basic_pass
    local encoded = base64_encode(credentials)
    request.headers['Authorization'] = 'Basic ' .. encoded
    return true
  end

  -- Parse "Digest username password"
  local digest_user, digest_pass = auth_value:match('^Digest%s+([^%s]+)%s+([^%s]+)$')
  if digest_user and digest_pass then
    -- Store digest credentials for curl
    request.digest_auth = {
      username = digest_user,
      password = digest_pass,
    }
    -- Remove Authorization header (curl will handle it)
    request.headers['Authorization'] = nil
    return true
  end

  -- All other formats (Bearer, API keys, etc.) are already standard
  return false
end

--- Apply authentication to request
--- Modifies request.headers or request.digest_auth based on auth type
--- @param request table Request object to modify
--- @param auth table|nil Auth configuration {type, params}
--- @return boolean success True if authentication was applied successfully
--- @return string|nil error Error message if application fails
function M.apply_auth(request, auth)
  if not auth then
    return true, nil
  end

  if auth.type == 'basic' then
    return M._apply_basic_auth(request, auth.params)
  elseif auth.type == 'bearer' then
    return M._apply_bearer_auth(request, auth.params)
  elseif auth.type == 'apikey' then
    return M._apply_apikey_auth(request, auth.params)
  elseif auth.type == 'digest' then
    return M._apply_digest_auth(request, auth.params)
  end

  return false, 'Unknown auth type: ' .. auth.type
end

-- Apply Basic Authentication
-- Params: username, password
function M._apply_basic_auth(request, params)
  if #params < 2 then
    return false, 'Basic auth requires username and password'
  end

  local username = params[1]
  local password = params[2]

  -- Encode credentials in base64 (using pure Lua to prevent shell injection)
  local credentials = username .. ':' .. password
  local encoded = base64_encode(credentials)

  request.headers['Authorization'] = 'Basic ' .. encoded
  return true, nil
end

-- Apply Bearer Token Authentication
-- Params: token
function M._apply_bearer_auth(request, params)
  if #params < 1 then
    return false, 'Bearer auth requires a token'
  end

  local token = params[1]
  request.headers['Authorization'] = 'Bearer ' .. token
  return true, nil
end

-- Apply API Key Authentication
-- Params: header_name, api_key
function M._apply_apikey_auth(request, params)
  if #params < 2 then
    return false, 'API Key auth requires header name and key value'
  end

  local header_name = params[1]
  local api_key = params[2]

  request.headers[header_name] = api_key
  return true, nil
end

-- Apply Digest Authentication
-- Params: username, password
-- Note: Digest auth is handled by curl's --digest flag
-- We store the credentials for curl command building
function M._apply_digest_auth(request, params)
  if #params < 2 then
    return false, 'Digest auth requires username and password'
  end

  -- Store digest credentials in request metadata for executor
  request.digest_auth = {
    username = params[1],
    password = params[2],
  }

  return true, nil
end

return M
