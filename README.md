# nrest.nvim

A fast and lightweight HTTP REST client for Neovim, inspired by VS Code's REST Client extension.

## Features

- 🚀 Execute HTTP requests directly from `.http` files
- 📝 Simple and intuitive syntax (inspired by VS Code REST Client)
- 🎨 Syntax highlighting for requests and responses
- ⚡ Asynchronous request execution with timeout support
- 📊 Clean response display in split windows
- 🔧 Configurable keybindings and behavior
- 🔒 SSL certificate verification control
- 🔐 Authentication presets (Basic, Bearer, API Key, Digest)
- 🔑 Environment variable support (user-defined and system)
- ✅ Request validation (method, URL scheme)
- 🔄 Automatic redirect handling
- 📦 Zero external dependencies (uses curl)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'yourusername/nrest.nvim',
  ft = 'http',
  config = function()
    require('nrest').setup({
      -- Optional configuration (defaults shown)
      result_split_horizontal = false,  -- Vertical split
      skip_ssl_verification = false,    -- Verify SSL certificates
      timeout = 30000,                  -- Request timeout (30s)
      highlight = {
        enabled = true,
        timeout = 150,
      },
      keybindings = {
        run_request = '<leader>hr',
        run_request_under_cursor = '<leader>hc',
      },
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'yourusername/nrest.nvim',
  ft = 'http',
  config = function()
    require('nrest').setup()
  end,
}
```

## Usage

### Creating HTTP Request Files

Create a file with the `.http` extension and write your HTTP requests:

```http
### Simple GET request
GET https://api.github.com/users/github

### POST request with headers
POST https://httpbin.org/post
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com"
}

### Request with custom headers
GET https://api.example.com/data
Authorization: Bearer your-token-here
Accept: application/json
```

### Executing Requests

- **Run request under cursor**: Press `<leader>hc` (or use `:NrestRunCursor`)
- **Run first request in file**: Press `<leader>hr` (or use `:NrestRun`)

The response will be displayed in a split window with:
- HTTP status line
- Response headers
- Response body

### Request Separators

Use `###` to separate multiple requests in the same file:

```http
### First request
GET https://api.example.com/users

### Second request
GET https://api.example.com/posts
```

### Authentication Presets

nrest.nvim supports common authentication methods with simple directives:

**Basic Authentication:**
```http
@auth basic username password

GET https://api.example.com/protected
```

**Bearer Token Authentication:**
```http
@auth bearer your-token-here

GET https://api.example.com/protected
```

**API Key Authentication:**
```http
@auth apikey X-API-Key your-api-key-here

GET https://api.example.com/protected
```

**Digest Authentication:**
```http
@auth digest username password

GET https://api.example.com/protected
```

**Authentication with Variables:**
```http
@token = my-secret-token
@auth bearer {{token}}

GET https://api.example.com/protected
```

**Authentication with System Environment Variables:**
```http
# Using system env vars directly in auth
@auth bearer $API_TOKEN

# Or combining with variables
@myToken = Bearer $API_TOKEN
@auth bearer {{myToken}}

GET https://api.example.com/protected
```

**Supported Authentication Types:**
- `basic` - HTTP Basic Authentication (username/password encoded in base64)
- `bearer` - Bearer token (commonly used for JWT tokens)
- `apikey` - Custom API key header (specify header name and value)
- `digest` - HTTP Digest Authentication (uses curl's --digest flag)

**Notes:**
- Auth directives apply to ALL requests in the file (global scope)
- Auth is applied before variables are substituted
- For request-specific auth, use separate files or manual headers
- Digest auth is handled by curl and supports standard digest challenges

### Environment Variables

Define and use variables in your `.http` files:

```http
# Define variables
@baseUrl = https://api.example.com
@token = Bearer abc123

### Use variables in requests
GET {{baseUrl}}/users
Authorization: {{token}}

### Variables work in URLs, headers, and body
POST {{baseUrl}}/users
Content-Type: application/json
Authorization: {{token}}

{
  "api": "{{baseUrl}}",
  "authenticated": true
}
```

**Variable Features:**
- Define with `@name = value`
- Use with `{{name}}`
- System environment variables: `$VAR` or `${VAR}`
- Works in URLs, headers, and request bodies
- Buffer variables override environment file variables
- Load from external file (e.g., `.env.http`)

**Variable Types:**
1. **User-defined variables**: `@name = value` → use with `{{name}}`
   - Defined in `.http` file or `.env.http`
   - Always use double curly braces: `{{variableName}}`
   - Can reference system env vars: `@token = Bearer $USER`
2. **System environment variables**: Use with `$VAR` or `${VAR}`
   - Examples: `$USER`, `$HOME`, `${API_TOKEN}`
   - Read from your shell environment
   - Use dollar sign syntax
   - Substituted when parsing variable definitions

**Important:** Don't mix syntaxes! Use `{{var}}` for user-defined, `$VAR` for system env.

**Combining variables:**
```http
# User variable can reference system env
@apiKey = Bearer $USER
@dataPath = ${HOME}/api-data

GET https://api.example.com/data
Authorization: {{apiKey}}
X-Path: {{dataPath}}
```

**System environment variable example:**
```http
# Set in shell: export API_TOKEN=secret123
GET https://api.example.com/data
Authorization: Bearer $API_TOKEN
X-User: $USER

{
  "home": "${HOME}",
  "shell": "$SHELL"
}
```

**Using environment files:**
```lua
-- Specific path
require('nrest').setup({
  env_file = '.env.http',  -- Load variables from file in current directory
})

-- Auto-discover .env.http in directory hierarchy
require('nrest').setup({
  env_file = 'auto',  -- Search for .env.http starting from buffer directory up to root
})

-- Absolute path
require('nrest').setup({
  env_file = vim.fn.getcwd() .. '/.env.http',  -- Project-specific env file
})
```

**Auto-discovery behavior:**
- Starts searching from the directory of the current `.http` file
- Walks up the directory tree until `.env.http` is found
- Stops at the root directory if not found
- Perfect for monorepos or nested project structures

## Configuration

All configuration options with their defaults:

```lua
require('nrest').setup({
  -- Split direction for result window
  result_split_horizontal = false,  -- false = vertical split, true = horizontal split

  -- Request execution
  skip_ssl_verification = false,    -- Skip SSL certificate verification (curl -k)
  timeout = 10000,                  -- Request timeout in milliseconds (10 seconds)

  -- Response formatting
  format_response = true,           -- Format response body (JSON with jq)

  -- Environment variables
  env_file = nil,                   -- Path to environment file
                                    -- nil = disabled
                                    -- 'auto' = auto-discover in directory hierarchy
                                    -- 'path' = specific path (e.g., '.env.http')

  -- Syntax highlighting
  highlight = {
    enabled = true,
    timeout = 150,
  },

  -- Result display options
  result = {
    show_url = true,        -- Show request URL
    show_http_info = true,  -- Show HTTP status line
    show_headers = true,    -- Show response headers
    show_body = true,       -- Show response body
  },

  -- Keybindings
  keybindings = {
    run_request = '<leader>hr',              -- Run first request in file
    run_request_under_cursor = '<leader>hc', -- Run request under cursor
  },
})
```

### Response Formatting

nrest.nvim automatically formats JSON responses using `jq` when available:

**Features:**
- Automatically detects JSON responses (by Content-Type header or content)
- Pretty-prints JSON with proper indentation
- Falls back to raw response if jq is not available
- Can be disabled with `format_response = false`

**Requirements:**
- `jq` must be installed and in PATH for JSON formatting

**Example:**
```lua
-- Disable automatic formatting
require('nrest').setup({
  format_response = false,  -- Show raw responses
})
```

### Configuration Examples

**Skip SSL verification for development:**
```lua
require('nrest').setup({
  skip_ssl_verification = true,
})
```

**Change timeout to 10 seconds:**
```lua
require('nrest').setup({
  timeout = 10000,  -- 10 seconds in milliseconds
})
```

**Use horizontal split for results:**
```lua
require('nrest').setup({
  result_split_horizontal = true,
})
```

**Load variables from environment file:**
```lua
-- Auto-discover .env.http (recommended)
require('nrest').setup({
  env_file = 'auto',  -- Searches up directory tree from current .http file
})

-- Specific path
require('nrest').setup({
  env_file = '.env.http',  -- Current working directory
})
```

## Commands

- `:NrestRun` - Execute the first HTTP request in the current buffer
- `:NrestRunCursor` - Execute the HTTP request under the cursor

## Supported HTTP Methods

All standard HTTP methods are supported:

- `GET` - Retrieve data
- `POST` - Send data
- `PUT` - Update/replace data
- `PATCH` - Partial update
- `DELETE` - Remove data
- `HEAD` - Get headers only
- `OPTIONS` - Get supported methods
- `CONNECT` - Establish tunnel
- `TRACE` - Echo request

## Requirements

- **Neovim** >= 0.8.0 (for modern Lua APIs)
- **curl** - Must be available in PATH for executing HTTP requests
- **jq** (optional) - For JSON response formatting (pretty-printing)

## How It Works

1. Parses `.http` files to extract requests (method, URL, headers, body)
2. Validates requests (checks HTTP method and URL scheme)
3. Builds and executes curl command asynchronously
4. Handles redirects automatically (follows and shows final response)
5. Displays formatted response in a split window with syntax highlighting

**Technical Details:**
- Uses Neovim's `jobstart()` for non-blocking execution
- Implements request timeout with timer-based termination
- Caches result buffer for performance
- Compatible with AstroNvim, LazyVim, and other distributions

## Roadmap

**Planned Features:**
- [ ] Request/response history
- [ ] File references (`< ./file.json`)
- [ ] XML response formatting
- [ ] GraphQL support
- [ ] WebSocket support
- [ ] Import from Postman/Insomnia collections
- [ ] Custom response handlers/hooks
- [ ] Request-scoped authentication (per-request auth directives)

**Recently Completed:**
- [x] JSON response formatting with jq
- [x] Authentication presets (Basic, Bearer, API Key, Digest)
- [x] Environment variable support (`@variable = value`, `{{variable}}`)
- [x] System environment variable support (`$VAR`, `${VAR}`)
- [x] Environment file loading (`.env.http`)
- [x] Request timeout implementation
- [x] SSL certificate verification control
- [x] Request validation (method, URL)
- [x] Automatic redirect handling
- [x] Modern Neovim API migration

## Development

For contributors and developers:

- See `CLAUDE.md` for architecture and development guidelines
- See `.ai-assistant/RULES.md` for critical development rules
- Run manual tests with `test.http` file before commits
- Follow modern Neovim API conventions (`vim.bo`, `vim.api`, etc.)

## Contributing

Contributions are welcome! Please:
1. Read `CLAUDE.md` and `.ai-assistant/RULES.md` first
2. Test changes with `.http` files
3. Ensure compatibility with Neovim >= 0.8.0
4. Submit a Pull Request with clear description

## License

MIT License - see LICENSE file for details

## Similar Projects

- [rest.nvim](https://github.com/rest-nvim/rest.nvim) - Another REST client for Neovim
- VS Code REST Client - The inspiration for this plugin

## Acknowledgments

Inspired by the VS Code REST Client extension.
