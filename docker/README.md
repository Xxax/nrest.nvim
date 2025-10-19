# 🐳 nrest.nvim Docker Demo

Try **nrest.nvim** without installing anything on your system! This Docker container provides a fully configured Neovim environment with nrest.nvim pre-installed and ready to use.

## 🚀 Quick Start

### Using Docker

```bash
# Pull and run the container
docker run -it ghcr.io/matthias/nrest-demo:latest

# Or build locally
cd docker
docker build -t nrest-demo .
docker run -it nrest-demo
```

### Using Docker Compose

```bash
# Start the container
docker-compose up -d

# Attach to the running container
docker-compose exec nrest nvim

# Stop the container
docker-compose down
```

## 📚 What's Included

- **Neovim** (latest stable from Alpine Linux)
- **nrest.nvim** (v0.1.1) - Pre-configured and ready to use
- **Dependencies**: curl, jq, git
- **Plugin Manager**: lazy.nvim
- **Theme**: Tokyo Night
- **Status Line**: lualine.nvim
- **Example Files**: 5+ demo .http files with 40+ request examples

## 🎯 Features You Can Test

### ✅ Core Features
- Execute HTTP requests (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS)
- Syntax highlighting for .http files
- JSON response formatting with jq
- Asynchronous request execution
- Multiple requests per file
- Request timeout handling

### 🔐 Authentication
- Basic Authentication
- Bearer Token
- API Key (custom headers)
- Digest Authentication

### 🔧 Variables
- User-defined variables (`{{variableName}}`)
- System environment variables (`$VAR`, `${VAR}`)
- Environment file support (`.env.http`)
- Variable substitution in URLs, headers, and body

### 📊 Response Display
- Foldable headers section
- Pretty-printed JSON
- HTTP status and headers
- Configurable display options

## 📖 Getting Started

When you start the container, Neovim opens with `welcome.http`:

### Basic Commands

```vim
" Execute request under cursor
<leader>hc        " Space + h + c

" Execute first request in file
<leader>hr        " Space + h + r

" Or use commands
:NrestRunCursor
:NrestRun

" Check plugin health
:checkhealth nrest

" Show quick reference
:NrestHelp
```

### Example Files

The container includes these demo files in `/home/nvim/demo/`:

1. **welcome.http** - Quick start guide with 14 basic examples
2. **variables-demo.http** - Variable usage (user-defined and system)
3. **auth-examples.http** - All authentication methods with examples
4. **advanced.http** - 40+ advanced features and real-world examples
5. **.env.http** - Example environment variables file

### Navigation

```bash
# Open a different example file
:e variables-demo.http
:e auth-examples.http
:e advanced.http

# File explorer
:e .

# List files
:!ls -la
```

## ⌨️ Key Bindings

### nrest.nvim
| Key | Action |
|-----|--------|
| `<leader>hc` | Run request under cursor |
| `<leader>hr` | Run first request in file |

### General Neovim
| Key | Action |
|-----|--------|
| `<leader>q` | Quit all |
| `<leader>w` | Save file |
| `<leader>e` | File explorer |
| `Ctrl+h/j/k/l` | Navigate between windows |

### Response Buffer
| Key | Action |
|-----|--------|
| `za` | Toggle fold |
| `zR` | Open all folds |
| `zM` | Close all folds |
| `zo` | Open fold |
| `zc` | Close fold |

## 🔧 Configuration

The Neovim configuration is located at `/home/nvim/.config/nvim/init.lua`:

```lua
require('nrest').setup({
  result_split_horizontal = false,  -- Vertical split
  skip_ssl_verification = false,
  timeout = 10000,                  -- 10 seconds
  format_response = true,           -- Format JSON with jq
  env_file = 'auto',                -- Auto-discover .env.http
  result = {
    show_url = true,
    show_http_info = true,
    show_headers = true,
    show_body = true,
    folding = true,
  },
})
```

## 🎓 Tutorial: Your First Request

1. **Start the container**:
   ```bash
   docker run -it ghcr.io/matthias/nrest-demo:latest
   ```

2. **Place cursor on a request** (welcome.http opens automatically):
   ```http
   ### Simple GET Request
   GET https://httpbin.org/get
   Accept: application/json
   ```

3. **Execute**: Press `<Space>hc` (leader + h + c)

4. **View Response**: The response appears in a split window with:
   - HTTP status line
   - Response headers (foldable)
   - Formatted JSON body

5. **Navigate**: Use `Ctrl+h/l` to switch between request and response windows

6. **Try more examples**: Scroll down and execute other requests!

## 🌟 Example Requests to Try

### Simple GET
```http
GET https://httpbin.org/get
```

### POST with JSON
```http
POST https://httpbin.org/post
Content-Type: application/json

{
  "message": "Hello from nrest.nvim!",
  "version": "0.1.1"
}
```

### Using Variables
```http
@baseUrl = https://httpbin.org
@token = my-secret-token

GET {{baseUrl}}/bearer
Authorization: Bearer {{token}}
```

### Authentication
```http
GET https://httpbin.org/basic-auth/user/passwd
@auth basic user passwd
```

## 🐛 Troubleshooting

### Container won't start
```bash
# Check if port is already in use
docker ps -a

# Remove old containers
docker container prune
```

### Plugin not working
```vim
" Check health
:checkhealth nrest

" Verify curl and jq are installed
:!which curl
:!which jq
```

### Response not showing
```vim
" Try different split direction
:lua require('nrest').setup({ result_split_horizontal = true })

" Check for errors
:messages
```

### Can't execute requests
```vim
" Verify you're in an .http file
:set filetype?

" Should output: filetype=http
```

## 🔍 Advanced Usage

### Persistent Data

Mount a volume to persist your .http files:

```bash
docker run -it \
  -v $(pwd)/my-requests:/home/nvim/my-requests \
  nrest-demo

# Inside container
cd my-requests
nvim my-api.http
```

### Custom Environment Variables

Pass environment variables for use in requests:

```bash
docker run -it \
  -e API_TOKEN=your-secret-token \
  -e API_URL=https://api.example.com \
  nrest-demo

# In your .http file
GET $API_URL/data
Authorization: Bearer $API_TOKEN
```

### Network Access

The container needs internet access to make HTTP requests. If you're behind a proxy:

```bash
docker run -it \
  -e HTTP_PROXY=http://proxy:8080 \
  -e HTTPS_PROXY=http://proxy:8080 \
  nrest-demo
```

## 📦 Building Locally

```bash
# Clone the repository
git clone https://gitlab.ttu.ch/matthias/nrest.git
cd nrest/docker

# Build the image
docker build -t nrest-demo .

# Run the container
docker run -it nrest-demo

# Or use docker-compose
docker-compose up -d
docker-compose exec nrest nvim
```

## 🤝 Contributing

Found an issue or want to improve the demo?

1. Check existing issues: https://gitlab.ttu.ch/matthias/nrest/-/issues
2. Submit a merge request with your improvements
3. Read CLAUDE.md and .ai-assistant/RULES.md first

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Links

- **Repository**: https://gitlab.ttu.ch/matthias/nrest
- **Issues**: https://gitlab.ttu.ch/matthias/nrest/-/issues
- **Release**: https://gitlab.ttu.ch/matthias/nrest/-/releases/v0.1.1
- **Documentation**: Run `:help nrest` in the container

## 💡 Next Steps

After trying the demo:

1. ⭐ Star the project if you like it!
2. 📖 Read the full documentation: `:help nrest`
3. 🔧 Install on your system: See main README.md
4. 🐛 Report issues: Use the issue tracker
5. 🤝 Contribute: Submit merge requests

---

**Enjoy testing nrest.nvim!** 🚀

For more information, visit: https://gitlab.ttu.ch/matthias/nrest
