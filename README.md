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
- Works in URLs, headers, and request bodies
- Buffer variables override environment file variables
- Load from external file (e.g., `.env.http`)

**Using environment files:**
```lua
require('nrest').setup({
  env_file = '.env.http',  -- Load variables from file
})
```

## Configuration

All configuration options with their defaults:

```lua
require('nrest').setup({
  -- Split direction for result window
  result_split_horizontal = false,  -- false = vertical split, true = horizontal split

  -- Request execution
  skip_ssl_verification = false,    -- Skip SSL certificate verification (curl -k)
  timeout = 10000,                  -- Request timeout in milliseconds (10 seconds)

  -- Environment variables
  env_file = nil,                   -- Path to environment file (e.g., '.env.http')

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
require('nrest').setup({
  env_file = vim.fn.getcwd() .. '/.env.http',  -- Project-specific env file
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
- [ ] Authentication presets (Basic, Bearer, etc.)
- [ ] Response body formatting (JSON pretty-print, XML)
- [ ] GraphQL support
- [ ] WebSocket support
- [ ] Import from Postman/Insomnia collections
- [ ] Custom response handlers/hooks

**Recently Completed:**
- [x] Environment variable support (`@variable = value`, `{{variable}}`)
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
