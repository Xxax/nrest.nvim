# Changelog

All notable changes to nrest.nvim will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-10-19

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

---

## Version History Notes

**0.1.0**: Initial release with comprehensive features, security hardening, and test infrastructure

---

## Migration Guides

This is the initial release of nrest.nvim. No migration needed.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## Links

- [Homepage](https://gitlab.ttu.ch/matthias/nrest)
- [Issue Tracker](https://gitlab.ttu.ch/matthias/nrest/-/issues)
- [Documentation](README.md)
