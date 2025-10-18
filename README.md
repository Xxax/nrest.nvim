# nrest.nvim

A fast and lightweight HTTP REST client for Neovim, inspired by VS Code's REST Client extension.

## Features

- 🚀 Execute HTTP requests directly from `.http` files
- 📝 Simple and intuitive syntax
- 🎨 Syntax highlighting for requests and responses
- ⚡ Asynchronous request execution
- 📊 Clean response display in split windows
- 🔧 Configurable keybindings and behavior
- 📦 Zero external dependencies (uses curl)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'yourusername/nrest.nvim',
  ft = 'http',
  config = function()
    require('nrest').setup({
      -- Optional configuration
      result_split_horizontal = false,
      skip_ssl_verification = false,
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

## Configuration

Default configuration:

```lua
require('nrest').setup({
  -- Split direction for result window
  result_split_horizontal = false,  -- false = vertical split, true = horizontal split
  result_split_in_place = false,    -- Open in current window
  skip_ssl_verification = false,    -- Skip SSL certificate verification

  -- Highlighting
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
  },

  -- Keybindings
  keybindings = {
    run_request = '<leader>hr',
    run_request_under_cursor = '<leader>hc',
  },
})
```

## Commands

- `:NrestRun` - Execute the first HTTP request in the current buffer
- `:NrestRunCursor` - Execute the HTTP request under the cursor

## Supported HTTP Methods

- GET
- POST
- PUT
- PATCH
- DELETE
- HEAD
- OPTIONS

## Requirements

- Neovim >= 0.8.0
- curl (must be available in PATH)

## Roadmap

- [ ] Environment variable support
- [ ] Request/response history
- [ ] GraphQL support
- [ ] WebSocket support
- [ ] Authentication presets
- [ ] Import from Postman/Insomnia collections
- [ ] Response body formatting (JSON, XML, etc.)
- [ ] Custom response handlers

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Similar Projects

- [rest.nvim](https://github.com/rest-nvim/rest.nvim) - Another REST client for Neovim
- VS Code REST Client - The inspiration for this plugin

## Acknowledgments

Inspired by the VS Code REST Client extension.
