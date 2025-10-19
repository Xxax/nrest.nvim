# nrest.nvim

[![GitLab Pipeline](https://gitlab.ttu.ch/matthias/nrest/badges/main/pipeline.svg)](https://gitlab.ttu.ch/matthias/nrest/-/commits/main)
[![GitHub Mirror](https://img.shields.io/badge/mirror-GitHub-blue)](https://github.com/Xxax/nrest.nvim)

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
- ✅ Request validation (method, URL scheme, headers)
- 🔄 Automatic redirect handling
- 📦 Zero Lua dependencies (only requires curl)
- 🧪 Comprehensive test suite with 33+ test cases
- 🏥 Built-in health check (`:checkhealth nrest`)
- 🔐 Security-hardened (pure Lua Base64, header validation)
- 📚 Full LuaDoc API documentation

## 📍 Repository Information

**Primary development:** [GitLab](https://gitlab.ttu.ch/matthias/nrest) (private development, auto-synced to GitHub)
**GitHub Mirror:** [github.com/Xxax/nrest.nvim](https://github.com/Xxax/nrest.nvim) (public mirror with issues/PRs)

- 🐛 **Issues:** [GitHub Issues](https://github.com/Xxax/nrest.nvim/issues) - Report bugs and request features
- 🔀 **Pull Requests:** [GitHub PRs](https://github.com/Xxax/nrest.nvim/pulls) - Contribute code (synced to GitLab)
- 📦 **Releases:** Available on both platforms (synced automatically)

You can install from either repository - both URLs work with all Neovim plugin managers!

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

**Option 1: GitLab (primary)**
```lua
{
  'https://gitlab.ttu.ch/matthias/nrest.git',
  ft = 'http',
  config = function()
    require('nrest').setup({
      -- Split direction for result window
      result_split_horizontal = false,  -- false = vertical, true = horizontal

      -- Request execution
      skip_ssl_verification = false,    -- Skip SSL certificate verification (curl -k)
      timeout = 10000,                  -- Request timeout in milliseconds (10s)

      -- Response formatting
      format_response = true,           -- Format JSON responses with jq

      -- Environment variables
      env_file = nil,                   -- nil = disabled, 'auto' = auto-discover, or path

      -- Syntax highlighting
      highlight = {
        enabled = true,
        timeout = 150,
      },

      -- Result display options
      result = {
        show_url = true,
        show_http_info = true,
        show_headers = true,
        show_body = true,
        folding = true,                 -- Enable header folding
      },

      -- Keybindings
      keybindings = {
        run_request = '<leader>rr',
        run_request_under_cursor = '<leader>rc',
      },
    })
  end,
}
```

**Option 2: GitHub (mirror)**
```lua
{
  'Xxax/nrest.nvim',
  ft = 'http',
  config = function()
    require('nrest').setup({
      -- Same configuration as above
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

**Option 1: GitLab (primary)**
```lua
use {
  'https://gitlab.ttu.ch/matthias/nrest.git',
  ft = 'http',
  config = function()
    require('nrest').setup({
      -- All options are optional, these are the defaults
      result_split_horizontal = false,
      skip_ssl_verification = false,
      timeout = 10000,
      format_response = true,
      env_file = nil,
      highlight = {
        enabled = true,
        timeout = 150,
      },
      result = {
        show_url = true,
        show_http_info = true,
        show_headers = true,
        show_body = true,
        folding = true,
      },
      keybindings = {
        run_request = '<leader>rr',
        run_request_under_cursor = '<leader>rc',
      },
    })
  end,
}
```

**Option 2: GitHub (mirror)**
```lua
use {
  'Xxax/nrest.nvim',
  ft = 'http',
  config = function()
    require('nrest').setup({
      -- Same configuration as above
    })
  end,
}
```

### Manual Installation

Clone the repository into your Neovim plugin directory:

**Option 1: GitLab (primary)**
```bash
# For Unix/Linux/macOS
git clone https://gitlab.ttu.ch/matthias/nrest.git ~/.local/share/nvim/site/pack/plugins/start/nrest.nvim

# For Windows
git clone https://gitlab.ttu.ch/matthias/nrest.git %LOCALAPPDATA%\nvim-data\site\pack\plugins\start\nrest.nvim
```

**Option 2: GitHub (mirror)**
```bash
# For Unix/Linux/macOS
git clone https://github.com/Xxax/nrest.nvim.git ~/.local/share/nvim/site/pack/plugins/start/nrest.nvim

# For Windows
git clone https://github.com/Xxax/nrest.nvim.git %LOCALAPPDATA%\nvim-data\site\pack\plugins\start\nrest.nvim
```

Then add to your `init.lua`:

```lua
require('nrest').setup({
  -- Your configuration here
})
```

## 🐳 Try with Docker

Want to test nrest.nvim without installing anything? Use our Docker demo environment:

```bash
# Pull and run the demo container
docker pull gitlab.ttu.ch:5050/matthias/nrest/demo:latest
docker run -it gitlab.ttu.ch:5050/matthias/nrest/demo:latest

# The container starts with Neovim and 80+ example requests ready to execute
# Press <Space>hc to run a request under cursor
```

**What's included:**
- ✅ Neovim + nrest.nvim pre-configured
- ✅ 80+ example HTTP requests (GET, POST, auth, variables, etc.)
- ✅ All dependencies (curl, jq)
- ✅ Interactive tutorial files

See [docker/README.md](docker/README.md) for detailed usage instructions.

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

- **Run request under cursor**: Press `<leader>rc` (or use `:NrestRunCursor`)
- **Run first request in file**: Press `<leader>rr` (or use `:NrestRun`)

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

nrest.nvim supports common authentication methods with simple directives. Authentication can be applied per-request or globally to all requests in a file.

#### Request-Scoped Authentication

Apply authentication to individual requests by placing the `@auth` directive after the HTTP method line:

**Basic Authentication:**
```http
### Authenticated request
GET https://api.example.com/protected
@auth basic username password

### Public request (no auth)
GET https://api.example.com/public
```

**Bearer Token Authentication:**
```http
### Request with bearer token
GET https://api.example.com/user/profile
@auth bearer your-token-here
```

**API Key Authentication:**
```http
### Request with API key
GET https://api.example.com/data
@auth apikey X-API-Key your-api-key-here
```

**Digest Authentication:**
```http
### Request with digest auth
GET https://api.example.com/protected
@auth digest username password
```

**Authentication with Variables:**
```http
@token = my-secret-token

### Uses the variable defined above
GET https://api.example.com/protected
@auth bearer {{token}}
```

**Authentication with System Environment Variables:**
```http
# Using system env vars directly in auth
GET https://api.example.com/protected
@auth bearer $API_TOKEN

# Or combining with variables
@myToken = Bearer $API_TOKEN

GET https://api.example.com/user
@auth bearer {{myToken}}
```

#### File-Level Authentication

For backward compatibility, you can define authentication at the file level. The `@auth` directive will apply to ALL requests in the file:

```http
@auth bearer global-token-123

### Request 1 (uses global auth)
GET https://api.example.com/users

### Request 2 (also uses global auth)
GET https://api.example.com/posts
```

**Supported Authentication Types:**
- `basic` - HTTP Basic Authentication (username/password encoded in base64)
- `bearer` - Bearer token (commonly used for JWT tokens)
- `apikey` - Custom API key header (specify header name and value)
- `digest` - HTTP Digest Authentication (uses curl's --digest flag)

**Notes:**
- **Priority**: Request-scoped auth overrides file-level auth
- Auth directives can use variables (`{{var}}`) and system env vars (`$VAR`)
- Variables are substituted before auth is applied
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
    folding = true,         -- Enable folding for headers (use 'za' to toggle)
  },

  -- Keybindings
  keybindings = {
    run_request = '<leader>rr',              -- Run first request in file
    run_request_under_cursor = '<leader>rc', -- Run request under cursor
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

### Response Folding

Headers can be folded to reduce clutter in the response buffer:

**Usage:**
- `za` - Toggle fold under cursor
- `zR` - Open all folds
- `zM` - Close all folds
- `zo` - Open fold
- `zc` - Close fold

**Configuration:**
```lua
require('nrest').setup({
  result = {
    folding = true,  -- Enable header folding (default: true)
  },
})
```

**Note:** By default, headers are folded (collapsed) when the response is displayed. Use `za` to expand them.

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

**Check your setup:**
```vim
:checkhealth nrest
```

This will verify all dependencies and show your current configuration.

## How It Works

1. Parses `.http` files to extract requests (method, URL, headers, body)
2. Validates requests (checks HTTP method and URL scheme)
3. Builds and executes curl command asynchronously
4. Handles redirects automatically (follows and shows final response)
5. Displays formatted response in a split window with syntax highlighting

**Technical Details:**
- Uses Neovim's `jobstart()` for non-blocking execution
- Implements request timeout with timer-based termination and race condition guards
- Caches result buffer for performance
- Pure Lua Base64 encoding (no shell dependencies)
- Header value validation prevents command injection
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

**Recently Completed:**
- [x] Comprehensive test suite (33+ test cases with plenary.nvim)
- [x] Health check system (`:checkhealth nrest`)
- [x] Security hardening (pure Lua Base64, header validation)
- [x] Full LuaDoc API documentation
- [x] Request-scoped authentication (per-request auth directives)
- [x] JSON response formatting with jq
- [x] Authentication presets (Basic, Bearer, API Key, Digest)
- [x] Environment variable support (`@variable = value`, `{{variable}}`)
- [x] System environment variable support (`$VAR`, `${VAR}`)
- [x] Environment file loading (`.env.http`)
- [x] Request timeout implementation
- [x] SSL certificate verification control
- [x] Request validation (method, URL, headers)
- [x] Automatic redirect handling
- [x] Modern Neovim API migration

## Development

For contributors and developers:

- See `CLAUDE.md` for architecture and development guidelines
- See `.ai-assistant/RULES.md` for critical development rules
- See `CHANGELOG.md` for version history and migration guides
- Follow modern Neovim API conventions (`vim.bo`, `vim.api`, etc.)

**Running Tests:**
```bash
# Install plenary.nvim for testing
git clone https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim

# Run test suite
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
```

**Test Coverage:**
- Parser module: 25 test cases
- Variables module: 24 test cases
- Auth module: 20 test cases
- Total: 69 automated tests (all passing)

**CI/CD:**
- GitLab CI/CD pipeline runs tests on every push/MR
- Tests against stable Neovim from Alpine packages
- Optional: Tests against latest Neovim from source (main branch only)
- Optional: Luacheck linting on merge requests

## Contributing

Contributions are welcome! Please:
1. Read `CLAUDE.md` and `.ai-assistant/RULES.md` first
2. Run the test suite and ensure all tests pass
3. Add tests for new features
4. Test changes manually with `.http` files
5. Run `:checkhealth nrest` to verify setup
6. Ensure compatibility with Neovim >= 0.8.0
7. Update `CHANGELOG.md` with your changes
8. Submit a Pull Request with clear description

**Before submitting:**
```bash
# Run tests
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/"

# Check health
nvim -c "checkhealth nrest" -c "qa"
```

## License

MIT License - see LICENSE file for details

## Similar Projects

- [rest.nvim](https://github.com/rest-nvim/rest.nvim) - Another REST client for Neovim
- VS Code REST Client - The inspiration for this plugin

## Acknowledgments

Inspired by the VS Code REST Client extension.
