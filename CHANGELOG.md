# Changelog

All notable changes to nrest.nvim will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
