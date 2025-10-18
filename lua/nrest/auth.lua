local M = {}

-- Supported authentication types
local AUTH_TYPES = {
  basic = true,
  bearer = true,
  apikey = true,
  digest = true,
}

-- Parse authentication directive from lines (file-level, searches all lines)
-- Syntax: @auth <type> <params...>
-- Examples:
--   @auth basic username password
--   @auth bearer token123
--   @auth apikey X-API-Key mykey123
--   @auth digest username password
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

-- Parse authentication directive from a single line (request-scoped)
-- Syntax: @auth <type> <params...>
-- Examples:
--   @auth basic username password
--   @auth bearer token123
--   @auth apikey X-API-Key mykey123
--   @auth digest username password
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

-- Apply authentication to request
-- Modifies request.headers and returns error if validation fails
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

  -- Encode credentials in base64
  local credentials = username .. ':' .. password
  local encoded = vim.fn.system('echo -n "' .. credentials .. '" | base64'):gsub('\n', '')

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
