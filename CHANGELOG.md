# Changelog

All notable changes to nrest.nvim will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive test suite with plenary.nvim for parser, variables, and auth modules (69 tests)
- LuaDoc API documentation for all public functions
- Health check support (`:checkhealth nrest`)
- GitLab CI/CD pipeline (.gitlab-ci.yml) for automated testing
  - Tests on stable Neovim (Alpine packages)
  - Tests on latest Neovim from source (main/develop only)
  - Optional luacheck linting on merge requests
- GitHub Actions CI/CD pipeline (.github/workflows/test.yml) for automated testing
  - Tests across Neovim 0.8.0, 0.9.0, 0.10.0, stable, nightly
- Header value validation to prevent command injection

### Changed
- **BREAKING**: Removed unused `result_split_in_place` configuration option
- Refactored `init.lua` to eliminate code duplication (~100 LOC reduction)
- Improved callback safety with race condition guard in executor

### Security
- **CRITICAL FIX**: Replaced shell-based Base64 encoding with pure Lua implementation to prevent shell injection vulnerability in Basic Auth
- Added header value validation to prevent potential command injection via newline characters

### Fixed
- Callback race condition between timeout and on_exit handlers
- Potential double invocation of response callback

## [1.0.0] - 2025-01-XX (Estimated from git history)

### Added
- Request-scoped authentication support (per-request `@auth` directives)
- Header folding support for response display
- Auto-discovery feature for `.env.http` files
- JSON response formatting with `jq`
- Environment variable support (user-defined and system)
- Authentication presets (Basic, Bearer, API Key, Digest)
- Request timeout implementation
- SSL certificate verification control
- Automatic redirect handling
- Modern Neovim API usage (0.8.0+)
- Syntax highlighting for `.http` files
- Multiple request support with `###` separators
- Cursor-based request execution
- Variable substitution in URLs, headers, and body

### Features
- HTTP methods: GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS, CONNECT, TRACE
- Asynchronous request execution with `vim.fn.jobstart()`
- Result buffer caching for performance
- snacks.nvim and AstroNvim compatibility
- Zero Lua dependencies (only requires curl)

## [0.1.0] - 2025-01-XX (Initial Release)

### Added
- Initial implementation of nrest.nvim
- Basic HTTP request parsing from `.http` files
- curl-based request execution
- Response display in split windows
- Basic syntax highlighting
- Configurable keybindings

---

## Version History Notes

**Unreleased**: Security fixes, test infrastructure, and code quality improvements
**1.0.0**: Full-featured REST client with auth, variables, and advanced features
**0.1.0**: Initial proof-of-concept

---

## Migration Guides

### Upgrading to Unreleased (from 1.0.0)

**Configuration Changes:**
```lua
-- REMOVED: result_split_in_place option (was not implemented)
require('nrest').setup({
  result_split_in_place = false,  -- Remove this line
})
```

**Security Notes:**
- Basic Auth now uses pure Lua Base64 encoding (no external dependencies)
- No user action required, but credentials are now safer from shell injection

**Testing:**
- New test suite available in `tests/` directory
- Run with: `nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/"`

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## Links

- [Homepage](https://gitlab.ttu.ch/matthias/nrest)
- [Issue Tracker](https://gitlab.ttu.ch/matthias/nrest/-/issues)
- [Documentation](README.md)
