--- Completion support for .http files
--- Provides omnifunc-based autocompletion for HTTP methods, headers, variables, and auth directives
--- @module nrest.completion

local M = {}

-- HTTP methods with descriptions
local HTTP_METHODS = {
  { word = "GET", menu = "Retrieve data" },
  { word = "POST", menu = "Send data" },
  { word = "PUT", menu = "Update/replace data" },
  { word = "PATCH", menu = "Partial update" },
  { word = "DELETE", menu = "Remove data" },
  { word = "HEAD", menu = "Get headers only" },
  { word = "OPTIONS", menu = "Get supported methods" },
  { word = "CONNECT", menu = "Establish tunnel" },
  { word = "TRACE", menu = "Echo request" },
}

-- Common HTTP headers with descriptions
local HTTP_HEADERS = {
  -- Authentication & Authorization
  { word = "Authorization", menu = "Auth credentials" },
  { word = "WWW-Authenticate", menu = "Auth method" },

  -- Content negotiation
  { word = "Accept", menu = "Acceptable response types" },
  { word = "Accept-Encoding", menu = "Acceptable encodings" },
  { word = "Accept-Language", menu = "Acceptable languages" },
  { word = "Content-Type", menu = "Request body type" },
  { word = "Content-Length", menu = "Body length in bytes" },
  { word = "Content-Encoding", menu = "Body encoding" },

  -- Caching
  { word = "Cache-Control", menu = "Caching directives" },
  { word = "ETag", menu = "Resource version" },
  { word = "If-None-Match", menu = "Conditional request" },
  { word = "If-Modified-Since", menu = "Conditional request" },

  -- CORS
  { word = "Access-Control-Allow-Origin", menu = "CORS origin" },
  { word = "Access-Control-Allow-Methods", menu = "CORS methods" },
  { word = "Access-Control-Allow-Headers", menu = "CORS headers" },

  -- Request metadata
  { word = "User-Agent", menu = "Client identifier" },
  { word = "Referer", menu = "Previous page URL" },
  { word = "Host", menu = "Target host" },
  { word = "Origin", menu = "Request origin" },

  -- Custom headers
  { word = "X-API-Key", menu = "API authentication key" },
  { word = "X-Request-ID", menu = "Request identifier" },
  { word = "X-Forwarded-For", menu = "Original client IP" },
}

-- Content-Type values
local CONTENT_TYPES = {
  { word = "application/json", menu = "JSON data" },
  { word = "application/xml", menu = "XML data" },
  { word = "application/x-www-form-urlencoded", menu = "Form data" },
  { word = "multipart/form-data", menu = "File upload" },
  { word = "text/plain", menu = "Plain text" },
  { word = "text/html", menu = "HTML document" },
  { word = "application/octet-stream", menu = "Binary data" },
}

-- Auth directive completions
local AUTH_DIRECTIVES = {
  { word = "@auth basic ", menu = "Basic auth (user pass)" },
  { word = "@auth bearer ", menu = "Bearer token auth" },
  { word = "@auth digest ", menu = "Digest auth (user pass)" },
  { word = "@auth apikey ", menu = "API key (header value)" },
}

--- Parse variables from current buffer
--- @return table List of variables with word and menu fields
local function get_buffer_variables()
  local variables = {}
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  for _, line in ipairs(lines) do
    -- Match @variable = value
    local var_name = line:match("^@(%w+)%s*=")
    if var_name then
      table.insert(variables, {
        word = "{{" .. var_name .. "}}",
        menu = "User variable",
      })
    end
  end

  return variables
end

--- Get system environment variables
--- @param prefix string Prefix to filter by (e.g., "AP" for "API_TOKEN")
--- @return table List of environment variables
local function get_env_variables(prefix)
  local env_vars = {}

  -- Get common environment variables
  local common_vars = {
    "HOME", "USER", "PATH", "SHELL",
    "API_TOKEN", "API_KEY", "AUTH_TOKEN",
    "DATABASE_URL", "DB_HOST", "DB_USER",
    "GITLAB_TOKEN", "GITHUB_TOKEN",
  }

  for _, var in ipairs(common_vars) do
    if not prefix or var:lower():find("^" .. prefix:lower()) then
      local value = vim.env[var] or os.getenv(var)
      table.insert(env_vars, {
        word = "$" .. var,
        menu = value and "Set" or "Not set",
      })
    end
  end

  return env_vars
end

--- Determine completion context based on cursor position
--- @param line string Current line text
--- @param col number Cursor column (0-indexed)
--- @return string|nil Context type: "method", "header_name", "header_value", "variable", "env_var", "auth"
local function get_completion_context(line, col)
  local before_cursor = line:sub(1, col)

  -- Check for @auth directive
  if before_cursor:match("^%s*@auth%s+%w*$") then
    return "auth"
  end

  -- Check for variable completion {{...
  if before_cursor:match("{{%w*$") then
    return "variable"
  end

  -- Check for environment variable $...
  if before_cursor:match("%$%w*$") then
    return "env_var"
  end

  -- Check if we're at the start of a line (HTTP method)
  if before_cursor:match("^%s*%w*$") then
    -- Could be HTTP method or continuation
    -- Check previous line to determine if we're in a request
    local line_num = vim.fn.line(".")
    if line_num > 1 then
      local prev_line = vim.fn.getline(line_num - 1)
      -- If previous line is empty or a separator, we're starting a new request
      if prev_line:match("^%s*$") or prev_line:match("^###") then
        return "method"
      end
    else
      return "method"
    end
  end

  -- Check for header name (after HTTP method line, before colon)
  if not before_cursor:match(":") then
    -- Look back to see if we're after a method line
    local line_num = vim.fn.line(".")
    if line_num > 1 then
      local prev_lines = vim.fn.getline(math.max(1, line_num - 5), line_num - 1)
      for _, prev_line in ipairs(vim.fn.reverse(prev_lines)) do
        if prev_line:match("^%s*(%u+)%s+") then
          -- Found method line, we're in header section
          return "header_name"
        end
        if prev_line:match("^###") or prev_line:match("^%s*$") then
          break
        end
      end
    end
  end

  -- Check for header value (after colon)
  local header_name = before_cursor:match("^%s*([%w-]+):%s*%w*$")
  if header_name then
    if header_name:lower() == "content-type" then
      return "content_type"
    end
    return "header_value"
  end

  return nil
end

--- Omnifunc completion function
--- @param findstart number 0 = find start of word, 1 = return completions
--- @param base string The text to match against
--- @return number|table Column position or list of completions
function M.omnifunc(findstart, base)
  if findstart == 1 then
    -- Find the start of the word to complete
    local line = vim.fn.getline(".")
    local col = vim.fn.col(".") - 1

    -- For variables {{...
    local var_start = line:sub(1, col):match(".*{{()")
    if var_start then
      return var_start - 1
    end

    -- For env vars $...
    local env_start = line:sub(1, col):match(".*%$()")
    if env_start then
      return env_start - 1
    end

    -- For @auth directives
    if line:match("^%s*@auth") then
      return line:match("()%S+$") - 1 or col
    end

    -- Default: find start of current word
    local start = col
    while start > 0 and line:sub(start, start):match("[%w-]") do
      start = start - 1
    end
    return start
  else
    -- Return completion list
    local line = vim.fn.getline(".")
    local col = vim.fn.col(".") - 1
    local context = get_completion_context(line, col)

    if context == "method" then
      return vim.tbl_filter(function(item)
        return vim.startswith(item.word:lower(), base:lower())
      end, HTTP_METHODS)

    elseif context == "header_name" then
      return vim.tbl_filter(function(item)
        return vim.startswith(item.word:lower(), base:lower())
      end, HTTP_HEADERS)

    elseif context == "content_type" then
      return vim.tbl_filter(function(item)
        return vim.startswith(item.word:lower(), base:lower())
      end, CONTENT_TYPES)

    elseif context == "variable" then
      local vars = get_buffer_variables()
      return vim.tbl_filter(function(item)
        return vim.startswith(item.word:lower(), base:lower())
      end, vars)

    elseif context == "env_var" then
      -- Remove $ prefix from base if present
      local prefix = base:gsub("^%$", "")
      return get_env_variables(prefix)

    elseif context == "auth" then
      return vim.tbl_filter(function(item)
        return vim.startswith(item.word:lower(), base:lower())
      end, AUTH_DIRECTIVES)
    end

    return {}
  end
end

--- Set up completion for current buffer
function M.setup()
  vim.bo.omnifunc = "v:lua.require('nrest.completion').omnifunc"

  -- Enable completion options
  vim.bo.completopt = "menu,menuone,noselect"
end

return M
