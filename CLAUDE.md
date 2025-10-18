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
2. **init.lua** gets buffer content and calls **parser.lua**
3. **parser.lua** extracts HTTP method, URL, headers, body from .http file
4. **init.lua** validates request (method, URL scheme)
5. **executor.lua** builds curl command and executes asynchronously
6. **executor.lua** parses curl response (handles redirects, finds final status)
7. **ui.lua** creates/reuses result buffer and displays response in split

### Key Implementation Details

**Request Parsing (parser.lua):**
- Detects request separators (`###`)
- Parses HTTP method line: `METHOD URL`
- Extracts headers: `Header-Name: value`
- Body starts after empty line, ends at next request/separator
- Tracks line ranges for cursor-based execution

**Request Execution (executor.lua):**
- Uses `vim.fn.jobstart()` for async execution
- Builds curl command: `-i` (include headers), `-s` (silent), `-L` (follow redirects)
- Supports SSL verification skip with `-k` flag
- Implements timeout using `vim.fn.timer_start()` + `jobstop()`
- Parses response by finding last HTTP status line (handles redirects)

**Buffer Management (ui.lua):**
- Caches result buffer in module-local variable
- Uses `nvim_create_buf(true, false)` to prevent dashboard interference
- Sets `eventignore = 'all'` during split creation to avoid autocmd conflicts
- Clears cache on BufDelete event
- Buffer options: `buftype=nofile`, `buflisted=false`, `bufhidden=hide`

**Configuration Flow:**
- Config defined in init.lua with defaults
- Passed to executor (for SSL, timeout) and ui (for display options)
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
- `env_file` - Path to environment file for variables (default: nil)
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
