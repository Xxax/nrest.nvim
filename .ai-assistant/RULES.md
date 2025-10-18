# CRITICAL RULES - nrest.nvim

**PRIORITY: CRITICAL** - These rules MUST be followed at all times.

---

## 🚨 Neovim Plugin Development Rules

### Buffer & Window Management

**ALWAYS:**
- Validate buffers with `vim.api.nvim_buf_is_valid(buf)` before ANY operation
- Validate windows with `vim.api.nvim_win_is_valid(win)` before ANY operation
- Use `pcall()` when creating splits or opening windows (autocmds can interfere)
- Cache buffer/window references but always validate before use

**NEVER:**
- Use `0` or `nil` as window/buffer ID without validation
- Assume a cached buffer still exists
- Create splits without `eventignore` protection (breaks with snacks.nvim/dashboard plugins)
- Use deprecated APIs: `nvim_buf_set_option()`, `nvim_win_set_option()`, `nvim_set_option()`

**Modern API Usage:**
```lua
-- CORRECT (modern):
vim.bo[buf].modifiable = false
vim.wo[win].wrap = true
vim.opt.timeout = 1000

-- WRONG (deprecated):
vim.api.nvim_buf_set_option(buf, 'modifiable', false)
vim.api.nvim_win_set_option(win, 'wrap', true)
```

### Async Operations & Callbacks

**ALWAYS:**
- Use `vim.fn.jobstart()` for async execution (never blocking `vim.fn.system()`)
- Implement timeout with `vim.fn.timer_start()` + `vim.fn.jobstop()`
- Clean up timers in callbacks (`vim.fn.timer_stop()`)
- Guard against double-callback execution (timeout + on_exit race condition)

**Pattern for safe callbacks:**
```lua
local callback_called = false
local safe_callback = function(result)
  if not callback_called then
    callback_called = true
    original_callback(result)
  end
end
```

### Configuration Management

**ALWAYS:**
- Pass config through all module calls (init → executor, init → ui)
- Use `vim.tbl_deep_extend('force', defaults, user_config)` for merging
- Document ALL config options in CLAUDE.md
- Remove unused config options or implement them (no dead config)

**NEVER:**
- Access config from global state in sub-modules
- Hardcode values that should be configurable
- Add config options without updating README.md and CLAUDE.md

### Error Handling

**ALWAYS:**
- Use `vim.notify()` with appropriate log levels:
  - `vim.log.levels.ERROR` - Request failures, invalid input
  - `vim.log.levels.WARN` - Deprecated features, non-critical issues
  - `vim.log.levels.INFO` - User feedback (e.g., "Executing request...")
- Provide actionable error messages (tell user what's wrong AND how to fix)
- Use `pcall()` for operations that might fail (window creation, buffer operations)

**Error message format:**
```lua
-- GOOD: Specific + actionable
vim.notify('Invalid request: URL must start with http:// or https://', vim.log.levels.ERROR)

-- BAD: Vague
vim.notify('Request failed', vim.log.levels.ERROR)
```

---

## 🔧 Code Quality Rules

### Validation & Safety

**ALWAYS validate:**
1. HTTP method against `VALID_METHODS` whitelist
2. URL has valid scheme (http:// or https://)
3. Buffers/windows before operations
4. Config parameters before using (check for nil)

**Parser validation chain:**
```lua
-- 1. Parse
local request = parser.parse_request(lines)
if not request then return end

-- 2. Validate
local valid, error_msg = parser.validate_request(request)
if not valid then
  vim.notify('Invalid request: ' .. error_msg, vim.log.levels.ERROR)
  return
end

-- 3. Execute
executor.execute(request, callback, config)
```

### Module Structure

**Each module MUST:**
- Start with `local M = {}`
- End with `return M`
- Have clear, single responsibility
- Use module-local variables for state (e.g., `result_buffer` in ui.lua)
- Document complex logic with inline comments

**File-local state pattern:**
```lua
local M = {}
local cached_state = nil  -- Module-local, not exported

function M.public_function()
  -- Use cached_state
end

return M
```

### Naming Conventions

**Functions:**
- Use snake_case: `parse_request()`, `build_curl_command()`
- Prefix internal helpers with underscore: `_parse_headers()`
- Descriptive names that explain purpose

**Variables:**
- Descriptive: `result_buffer` not `buf`, `current_request` not `req`
- Constants in SCREAMING_CASE: `VALID_METHODS`, `DEFAULT_TIMEOUT`

---

## 📦 Compatibility Rules

### snacks.nvim / AstroNvim Compatibility

**CRITICAL for split creation:**
```lua
-- Disable events during split to prevent dashboard interference
local eventignore = vim.o.eventignore
vim.o.eventignore = 'all'

vim.cmd('split')  -- or 'vsplit'

-- Re-enable events BEFORE setting buffer
vim.o.eventignore = eventignore
vim.api.nvim_win_set_buf(win, buf)
```

**Buffer creation to prevent dashboard:**
```lua
-- Create listed buffer first, then hide from list
local buf = vim.api.nvim_create_buf(true, false)
vim.bo[buf].buftype = 'nofile'
vim.bo[buf].buflisted = false
```

### Neovim Version Support

**Minimum: Neovim 0.8.0**
- Use modern APIs (vim.bo, vim.wo, vim.opt)
- Avoid deprecated functions
- Test with `:checkhealth` if available

---

## 🧪 Testing Requirements

### Before ANY Commit

**MUST manually test:**
1. Basic request execution (GET with `:NrestRunCursor`)
2. Request with headers and body (POST)
3. Multiple requests separated by `###`
4. Buffer reuse (execute twice, check same buffer)
5. Window switching (Ctrl-o back to .http file, execute again)
6. Error cases (invalid method, malformed URL)

**Test file template:**
```http
### Test GET
GET https://httpbin.org/get

### Test POST
POST https://httpbin.org/post
Content-Type: application/json

{"test": "data"}

### Test invalid (should error)
INVALID https://example.com
```

### Regression Prevention

**After fixing a bug:**
1. Document the issue in CLAUDE.md "Known Issues & Workarounds"
2. Add inline comment at fix location referencing the issue
3. Test the specific scenario that triggered the bug

---

## 📝 Documentation Rules

### Code Comments

**ALWAYS comment:**
- Non-obvious workarounds (e.g., eventignore for snacks.nvim)
- Complex parsing logic
- Race condition protections
- Performance optimizations

**Example:**
```lua
-- Skip intermediate responses (redirects, 100 Continue, etc.)
-- Find the last HTTP status line before the body
local last_status_index = 1
for idx, line in ipairs(lines) do
  if line:match('^HTTP/%S+%s+%d+') then
    last_status_index = idx
  end
end
```

### README.md Updates

**MUST update when:**
- Adding new config options
- Changing default behavior
- Adding new commands
- Changing requirements (Neovim version, dependencies)

### CLAUDE.md Updates

**MUST update when:**
- Fixing known issues (move from "Known Issues" to resolved)
- Changing architecture or data flow
- Adding new modules
- Discovering new compatibility issues

---

## ⚠️ Common Pitfalls to AVOID

1. **Buffer invalidation**: Never assume cached buffer is valid
2. **Double callbacks**: Always guard timeout + on_exit race
3. **Autocmd interference**: Use `eventignore` for split creation
4. **Hardcoded values**: Make configurable or use named constants
5. **Blocking operations**: Never use `vim.fn.system()` for HTTP requests
6. **Empty body matching**: Use `([^\n]*)\n` not `[^\n]+` for gmatch
7. **Unordered headers**: Use `pairs()` carefully, document if order matters
8. **Global state**: Prefer module-local or passed parameters

---

## 🔄 Refactoring Guidelines

**When refactoring:**
1. Run all manual tests BEFORE committing
2. Update CLAUDE.md if architecture changes
3. Keep backwards compatibility for config options
4. Add deprecation warnings before removing features
5. Test with clean Neovim config (no other plugins)

**Safe refactoring checklist:**
- [ ] All manual tests pass
- [ ] No new deprecation warnings
- [ ] CLAUDE.md updated
- [ ] README.md updated if user-facing
- [ ] Inline comments explain complex changes

---

**Last Updated:** 2025-10-18
**Version:** 1.0
