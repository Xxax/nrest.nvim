# Changelog

All notable changes to nrest.nvim will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-10-25

### Added - VS Code REST Client Compatibility 🎉

#### Request Naming
- Support for `# @name requestName` and `// @name requestName` directives
- Request names are displayed in response buffer for easy identification
- Fully compatible with VS Code REST Client syntax

#### Multiline Query Parameters
- Lines starting with `?` or `&` after the HTTP method are parsed as query parameters
- Cleaner, more readable request files
- Parameters are automatically combined into the final URL
- Example:
  ```http
  GET https://api.example.com/search
  ?query=neovim
  &category=plugins
  &limit=10
  ```

#### File References
- Include file content in request bodies using `< ./file.json` syntax
- Works for entire body replacement or inline (e.g., multipart uploads)
- Supports relative paths (to .http file) and absolute paths
- Compatible with VS Code REST Client file inclusion

#### Standard Authorization Headers
- `Authorization: Basic user:password` - automatically base64 encoded
- `Authorization: Digest user password` - sets up curl digest auth
- `Authorization: Bearer token` - passes through unchanged
- Works alongside existing `@auth` directives
- Priority: `@auth` directive > file-level `@auth` > standard Authorization header

#### .rest File Extension Support
- Plugin now recognizes both `.http` and `.rest` file extensions
- Full compatibility with VS Code REST Client file naming

### Changed

#### Parser Enhancements
- `lua/nrest/parser.lua`:
  - Added `_resolve_file_references()` function for file inclusion
  - Added multiline query parameter parsing after method line
  - Added request naming support with `# @name` and `// @name`
  - Request objects now include `name` field

#### Authentication Improvements
- `lua/nrest/auth.lua`:
  - Added `parse_standard_auth_header()` for VS Code compatible headers
  - Standard Authorization headers are automatically detected and processed
  - Basic Auth headers are base64 encoded automatically
  - Digest Auth headers set up curl digest authentication

#### UI Updates
- `lua/nrest/ui.lua`:
  - Request names are displayed in response buffer when present
  - Format: `# Request: requestName` at the top of response

#### Plugin Initialization
- `plugin/nrest.lua`:
  - Added `.rest` extension to filetype detection
  - Both `.http` and `.rest` files now use `http` filetype

### Testing

#### New Tests
- **Parser**: 6 new tests for multiline query params and request naming (31 total)
- **Auth**: 5 new tests for standard Authorization headers (25 total)
- **Total**: 80 automated tests (all passing)

### Documentation

#### Updated Documentation
- `README.md`:
  - Added VS Code compatibility section
  - Documented all new features with examples
  - Updated feature list and roadmap
  - Added "Recently Completed (v0.2.0)" section

- `CLAUDE.md`:
  - Updated architecture documentation
  - Added implementation details for new features
  - Updated test coverage statistics

- `doc/nrest.txt`:
  - Added sections for all VS Code compatible features
  - Updated examples and usage instructions
  - Version bumped to 0.2.0

#### Docker Demo Updates
- Added `docker/examples/vscode-compatible.http` - comprehensive VS Code features showcase
- Added `docker/examples/file-references.http` - file inclusion examples
- Added `docker/examples/sample-data.json` - sample data for file reference demos
- Updated `docker/examples/welcome.http` with v0.2.0 feature overview
- Updated `docker/README.md` with new features and examples

### Backward Compatibility

All changes are backward compatible:
- Existing `@auth` directives continue to work
- All existing `.http` files work without modifications
- New features are optional and don't affect existing functionality
- Both syntaxes can be mixed in the same file

### Migration Guide

No migration required! All existing `.http` files continue to work.

To use new features:
- Rename files to `.rest` if desired (optional)
- Add `# @name` directives for better organization (optional)
- Use standard `Authorization` headers if preferred (optional)
- Use `?` and `&` for multiline query params (optional)
- Use `< ./file.json` for file references (optional)

### VS Code Compatibility Status

✅ **Implemented:**
- Request naming (`# @name`, `// @name`)
- Multiline query parameters (`?` and `&`)
- File references (`< ./file.json`)
- Standard Authorization headers (Basic, Digest, Bearer)
- `.rest` file extension

⏳ **Planned:**
- Response variables (`{{requestName.response.body.$}}`)
- GraphQL support

## [0.1.3] - 2025-10-19

### Changed
- **BREAKING:** Default keybindings changed from `<leader>h` to `<leader>r`
  - `<leader>rr` - Run first request in file (was `<leader>hr`)
  - `<leader>rc` - Run request under cursor (was `<leader>hc`)
  - Rationale: Avoid conflicts with help plugins, `r` = **R**EST/**R**equest is more intuitive

### Documentation
- Updated all documentation with new keybindings
- Updated README.md, doc/nrest.txt, CLAUDE.md, ARCHITECTURE.adoc
- Updated all example files (docker/examples/*.http)
- Updated Docker demo configuration (docker/nvim/init.lua)

## [0.1.2] - 2025-10-19

### Changed
- **Community Contributions:** GitHub Issues and Pull Requests now primary (removed redirect templates)
- README.md updated to direct users to GitHub for issues and PRs
- Lower barrier for contributors - no GitLab account required

### Removed
- GitHub issue redirect template (`.github/ISSUE_TEMPLATE.md`)
- GitHub pull request redirect template (`.github/PULL_REQUEST_TEMPLATE.md`)

### Documentation
- Added GitLab settings guide (`temp/gitlab-settings.md`)
- Documented workflow for GitHub-based community contributions
- Issues: https://github.com/Xxax/nrest.nvim/issues
- Pull Requests: https://github.com/Xxax/nrest.nvim/pulls

## [0.1.1] - 2025-10-19

### Added
- GitHub mirror setup with automatic synchronization from GitLab
- GitHub issue and pull request templates redirecting to GitLab
- Repository information section in README with both installation options
- Project logos (doc/nrest-logo*.png) for documentation

### Changed
- README.md now includes both GitLab (primary) and GitHub (mirror) installation instructions
- Updated installation examples for lazy.nvim, packer.nvim, and manual installation
- Added GitHub mirror badge to README

### Removed
- GitHub Actions workflow (`.github/workflows/test.yml`) - GitLab CI/CD is primary
- Simplified mirror setup by removing `workflow` scope requirement for GitHub tokens

### Infrastructure
- GitLab Push Mirror configured for automatic sync to GitHub
- temp/ directory excluded from git via .gitignore
- GitHub repository serves as read-only mirror at https://github.com/Xxax/nrest.nvim

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

**0.1.3**: Changed default keybindings to `<leader>r` (BREAKING CHANGE)
**0.1.2**: Enable GitHub Issues and Pull Requests for community contributions
**0.1.1**: GitHub mirror setup and infrastructure improvements
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
