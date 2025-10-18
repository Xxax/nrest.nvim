# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## ⚠️ CRITICAL: Read Rules First

**BEFORE making ANY changes, read:** `.ai-assistant/RULES.md`

This file contains CRITICAL rules for:
- Buffer/Window management (prevents crashes with snacks.nvim/AstroNvim)
- Async operations & callback safety
- Modern Neovim API usage
- Compatibility requirements
- Testing procedures

**All rules in RULES.md are MANDATORY and take precedence over suggestions in this file.**

---

## Project Overview

**nrest.nvim** is a Neovim plugin that provides a REST client for executing HTTP requests directly from `.http` files. It's inspired by VS Code's REST Client extension and uses curl for request execution with zero Lua dependencies.

**Requirements:**
- Neovim >= 0.8.0
- curl in PATH

## Architecture

### Module Structure

The plugin follows standard Neovim plugin architecture with clear separation of concerns:

```
lua/nrest/
├── init.lua      - Main entry point, config management, orchestrates parser/executor/ui
├── parser.lua    - Parses .http files into request objects
├── executor.lua  - Executes HTTP requests via curl (async with jobstart)
├── ui.lua        - Manages result buffer and split windows
├── auth.lua      - Authentication preset handling (Basic, Bearer, API Key, Digest)
├── variables.lua - Variable parsing and substitution (user-defined and system env vars)
└── keymaps.lua   - Buffer-local keymap setup

plugin/
└── nrest.lua     - Plugin initialization, commands, filetype detection

syntax/
└── http.vim      - Syntax highlighting for .http files

ftplugin/
└── http.vim      - Filetype-specific settings
```

### Data Flow

1. User triggers `:NrestRun` or `:NrestRunCursor` (or keybindings)
2. **init.lua** gets buffer content
3. **variables.lua** parses variables from buffer and env file
4. **parser.lua** extracts HTTP method, URL, headers, body from .http file
5. **variables.lua** substitutes variables in request (system env vars first, then user vars)
6. **auth.lua** parses auth directive and applies authentication to request
7. **init.lua** validates request (method, URL scheme)
8. **executor.lua** builds curl command (including digest auth if needed) and executes asynchronously
9. **executor.lua** parses curl response (handles redirects, finds final status)
10. **ui.lua** creates/reuses result buffer and displays response in split

### Key Implementation Details

**Request Parsing (parser.lua):**
- Detects request separators (`###`)
- Parses HTTP method line: `METHOD URL`
- Extracts headers: `Header-Name: value`
- Body starts after empty line, ends at next request/separator
- Tracks line ranges for cursor-based execution
- Skips auth directives (`@auth`) and variable definitions (`@var =`) during parsing

**Authentication (auth.lua):**
- Parses auth directives: `@auth <type> <params...>`
- Supported types: `basic`, `bearer`, `apikey`, `digest`
- **Basic Auth**: Encodes username:password in base64, adds `Authorization: Basic <encoded>` header
- **Bearer Token**: Adds `Authorization: Bearer <token>` header
- **API Key**: Adds custom header with specified name and value
- **Digest Auth**: Sets metadata in request for executor to use curl's `--digest` flag
- Auth is applied globally to all requests in the file (file-level scope)
- **Variable substitution in auth**: Auth parameters are substituted in init.lua before applying auth
  - System env vars: `@auth bearer $GITLAB_TOKEN`
  - User vars: `@auth bearer {{myToken}}`
  - Substitution happens after variable parsing, before auth application

**Variable Handling (variables.lua):**
- Parses user-defined variables: `@name = value`
- Loads variables from optional env file
- **Auto-discovery**: When `env_file = 'auto'`, searches for `.env.http` from buffer directory up to root
- Uses `vim.fn.expand('%:p:h')` to get buffer directory for auto-discovery
- Substitutes system env vars: `$VAR` or `${VAR}` using `vim.env` and `os.getenv()`
- Substitutes user vars: `{{name}}` using regex replacement
- **Substitution order**: System env vars first, then user vars (allows user vars to reference system vars)
- **Priority**: Buffer vars > env file vars > system env vars
- **Search behavior**: Walks up directory tree max 20 iterations to prevent infinite loops

**Request Execution (executor.lua):**
- Uses `vim.fn.jobstart()` for async execution
- Builds curl command: `-i` (include headers), `-s` (silent), `-L` (follow redirects)
- Supports SSL verification skip with `-k` flag
- Adds digest auth with `--digest -u user:pass` when `request.digest_auth` is set
- Implements timeout using `vim.fn.timer_start()` + `jobstop()`
- Parses response by finding last HTTP status line (handles redirects)
- URL-encodes query parameters to handle spaces and special characters

**Response Formatting (ui.lua):**
- Detects JSON responses by Content-Type header or content inspection
- Formats JSON with `jq` if available (via `vim.fn.system()`)
- Falls back to raw response if jq is not installed or formatting fails
- Can be disabled with `format_response = false` config option
- Uses `vim.v.shell_error` to check jq exit code
- Handles both `Content-Type: application/json` and `application/*+json` patterns

**Buffer Management (ui.lua):**
- Caches result buffer in module-local variable
- Uses `nvim_create_buf(true, false)` to prevent dashboard interference
- Sets `eventignore = 'all'` during split creation to avoid autocmd conflicts
- Clears cache on BufDelete event
- Buffer options: `buftype=nofile`, `buflisted=false`, `bufhidden=hide`
- **Folding**: Uses marker-based folding (`{{{`, `}}}`) for headers section
  - `foldmethod=marker` for efficient folding
  - `foldlevel=0` to start with headers folded
  - Configurable via `result.folding` option

**Configuration Flow:**
- Config defined in init.lua with defaults
- Passed to executor (for SSL, timeout, digest auth) and ui (for display options, formatting)
- Merged via `vim.tbl_deep_extend()` in setup()

## Testing the Plugin

**Manual testing:**
1. Create a test file: `test.http` (ignored by git)
2. Add a request:
   ```http
   ### Test
   GET https://httpbin.org/get
   ```
3. Open in Neovim: `nvim test.http`
4. Execute with `<leader>hc` or `:NrestRunCursor`
5. Check result buffer displays correctly

**Testing specific features:**
- SSL skip: Set `skip_ssl_verification = true` in setup()
- Timeout: Set `timeout = 5000` and test with slow endpoint
- Redirects: Test with URL that redirects (e.g., http → https)
- Multiple requests: Use `###` separators, test cursor positioning
- **Auth testing**:
  - Basic: Test with `https://httpbin.org/basic-auth/user/pass`
  - Bearer: Test with `https://httpbin.org/bearer`
  - API Key: Test with custom header on any endpoint
  - Digest: Test with `https://httpbin.org/digest-auth/auth/user/pass`
  - Variables in auth: Use `@auth bearer {{token}}` with `@token = test123`

## Known Issues & Workarounds

**snacks.nvim Dashboard Interference:**
The plugin temporarily disables all events (`eventignore = 'all'`) during split creation to prevent dashboard from showing when switching buffers. This is critical for compatibility with AstroNvim and similar distributions.

**Buffer Validation:**
Always validate buffer with `vim.api.nvim_buf_is_valid()` before operations. The result buffer can be deleted by user actions (`:bd`, window close).

**Timeout Race Condition:**
Current implementation has potential for callback to be called twice (timeout + on_exit). Consider wrapping callback with guard flag if issues arise.

## Development Notes

**Adding new HTTP methods:**
Update `VALID_METHODS` table in `parser.lua:4-14`

**Changing curl behavior:**
Modify `build_curl_command()` in `executor.lua:64-92`

**Response format:**
Customize `format_response()` in `ui.lua:148-172`

**Modern Neovim APIs:**
- Use `vim.bo[buf]` instead of deprecated `nvim_buf_set_option()`
- Use `vim.api.nvim_create_autocmd()` for autocommands
- Prefer Lua APIs over vim.cmd() where possible

## Config Options

**Currently implemented:**
- `result_split_horizontal` - Split direction (default: false = vertical)
- `skip_ssl_verification` - Pass `-k` to curl (default: false)
- `timeout` - Request timeout in ms (default: 10000)
- `format_response` - Format JSON with jq (default: true)
- `env_file` - Path to environment file for variables (default: nil)
  - `nil` - Disabled
  - `'auto'` - Auto-discover .env.http in directory hierarchy
  - `'path'` - Specific file path
- `highlight.enabled` - Enable syntax highlighting (default: true)
- `result.show_*` - Control what's displayed in results
- `keybindings.*` - Customize keymaps

**Not implemented (in config but unused):**
- `result_split_in_place` - Not implemented, should be removed or implemented
- `highlight.timeout` - Not used, should be removed or implemented

## Environment Variables

**Syntax:**
- Define: `@variableName = value`
- Use: `{{variableName}}`
- System env: `$VAR` or `${VAR}`
- Works in: URLs, headers, body

**Implementation (variables.lua):**
- Parses `@name = value` lines
- Loads from optional env_file
- Substitutes `{{name}}` patterns with regex
- Substitutes `$VAR` and `${VAR}` with system environment variables
- Uses `vim.env` and `os.getenv()` for system vars
- Buffer variables override env file variables

**Variable types and priority (highest to lowest):**
1. User-defined variables in `.http` buffer (`@var = value`)
2. Variables from `env_file`
3. System environment variables (`$VAR`, `${VAR}`)

**Substitution order:**
1. First: System environment variables (`$VAR`, `${VAR}`)
2. Then: User-defined variables (`{{name}}`)
This allows user vars to reference system vars

**Usage in init.lua:**
- Parse variables from buffer and env file
- Merge with buffer vars taking precedence
- Substitute in request before validation
- System vars substituted directly from environment

## Commit Conventions

Based on git history, use descriptive commit messages with context:
```
Initial commit: nrest.nvim - HTTP REST client for Neovim

Add complete implementation of nrest.nvim...
[detailed description of changes]
```

Include Co-Authored-By when working with Claude Code.
