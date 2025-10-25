# Security Setup Guide

Quick guide to set up secret protection for nrest.nvim development.

## Quick Setup (Recommended)

```bash
# 1. Install gitleaks
brew install gitleaks  # macOS
# or
go install github.com/gitleaks/gitleaks/v8@latest

# 2. Install pre-commit (optional but recommended)
pip install pre-commit
pre-commit install

# 3. Set up git hook (alternative to pre-commit)
ln -s ../../.githooks/pre-commit .git/hooks/pre-commit
chmod +x .githooks/pre-commit

# 4. Test the setup
gitleaks detect --verbose
```

## What's Protected

✅ `.env.http` files (except examples)
✅ GitLab tokens (glpat-*)
✅ API keys and secrets
✅ Private keys
✅ Hardcoded passwords

## Daily Usage

### Creating Request Files

**❌ Don't do this:**
```http
GET https://api.gitlab.com/api/v4/projects
Authorization: Bearer glpat-abc123xyz789
```

**✅ Do this instead:**
```http
GET https://api.gitlab.com/api/v4/projects
Authorization: Bearer $GITLAB_TOKEN
```

### Using .env.http

```bash
# 1. Copy example file
cp examples/.env.http.example .env.http

# 2. Add your real tokens
vim .env.http

# 3. Configure nrest to use it
# In your Neovim config:
require('nrest').setup({
  env_file = 'auto',  -- Auto-discovers .env.http
})
```

## Troubleshooting

### Hook blocking commit with false positive?

```bash
# Temporarily skip hook (NOT RECOMMENDED)
git commit --no-verify

# Better: Add to allowlist
echo "path/to/file:pattern" >> .gitleaksignore
```

### Check what would be scanned

```bash
# See what gitleaks will check
gitleaks protect --staged --verbose

# Scan entire repo
gitleaks detect --verbose
```

### Pre-commit hook not running?

```bash
# Check hook is executable
ls -la .git/hooks/pre-commit

# Re-install
ln -sf ../../.githooks/pre-commit .git/hooks/pre-commit
chmod +x .githooks/pre-commit
```

## CI/CD Integration

### GitLab CI

Add to `.gitlab-ci.yml`:

```yaml
secrets-scan:
  stage: test
  image: zricethezav/gitleaks:latest
  script:
    - gitleaks detect --verbose --no-git
  allow_failure: false
```

### GitHub Actions

Add to `.github/workflows/security.yml`:

```yaml
name: Security Scan
on: [push, pull_request]
jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
```

## What Files Are Safe to Commit?

✅ **Safe:**
- `*.http` files using variables (`{{VAR}}`, `$VAR`)
- `.env.http.example` with placeholders
- `docker/examples/.env.http` with demo values
- Documentation files

❌ **Never commit:**
- `.env.http` with real tokens
- `*.http` files with hardcoded secrets
- Configuration files with real credentials

## Emergency: Secret Committed

See [SECURITY.md](../SECURITY.md#-if-you-accidentally-commit-a-secret) for full instructions.

**Quick steps:**
1. Revoke the token immediately
2. Rotate credentials
3. Contact security team
4. Clean git history (if needed)

## Resources

- [Full Security Policy](../SECURITY.md)
- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [Pre-commit Hooks](https://pre-commit.com/)
