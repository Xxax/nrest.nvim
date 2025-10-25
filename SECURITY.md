# Security Policy

## Protecting Secrets in nrest.nvim

### ⚠️ Never Commit Secrets

**IMPORTANT**: `.http` files may contain sensitive data like API tokens, passwords, and private keys.

### 🛡️ Best Practices

#### 1. Use Environment Variables

**Instead of hardcoding:**
```http
GET https://api.example.com/data
Authorization: Bearer glpat-abc123xyz789
```

**Use environment variables:**
```http
GET https://api.example.com/data
Authorization: Bearer $GITLAB_TOKEN
```

#### 2. Use .env.http Files (Gitignored)

Create a `.env.http` file (automatically ignored by git):

```http
# .env.http (NOT committed to git)
@GITLAB_TOKEN = glpat-your-real-token-here
@API_KEY = your-real-api-key
```

Then reference in your `.http` files:
```http
# api.http (safe to commit)
GET https://api.example.com/data
Authorization: Bearer {{GITLAB_TOKEN}}
```

#### 3. Use .example Files for Templates

Commit `.env.http.example` files with placeholder values:

```http
# .env.http.example (safe to commit)
@GITLAB_TOKEN = glpat-your-token-here
@API_KEY = your-api-key-here
```

Users copy to `.env.http` and add real values.

### 🔒 Security Tools

#### Pre-commit Hooks

Install pre-commit hooks to prevent committing secrets:

```bash
# Install pre-commit (if not already installed)
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

#### Manual Git Hook

```bash
# Symlink the pre-commit hook
ln -s ../../.githooks/pre-commit .git/hooks/pre-commit

# Make it executable
chmod +x .githooks/pre-commit
```

#### Gitleaks

Scan for secrets in git history:

```bash
# Install gitleaks
brew install gitleaks  # macOS
# or
go install github.com/gitleaks/gitleaks/v8@latest

# Scan repository
gitleaks detect --verbose

# Scan before commit
gitleaks protect --staged
```

### 📋 .gitignore Configuration

Ensure your `.gitignore` includes:

```gitignore
# Environment files (may contain secrets)
.env.http
*.env.http
!docker/examples/.env.http  # Only allow demo files
!**/*.env.http.example      # Template files are safe
```

### 🚨 If You Accidentally Commit a Secret

1. **Immediately revoke/rotate the secret**
   - GitLab: Settings → Access Tokens → Revoke
   - API keys: Regenerate in service dashboard

2. **Remove from git history** (destructive):
   ```bash
   # Using BFG Repo-Cleaner (recommended)
   git clone --mirror <repo-url>
   bfg --delete-files .env.http repo.git
   cd repo.git
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   git push --force

   # Or using git filter-branch
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch path/to/secret-file" \
     --prune-empty --tag-name-filter cat -- --all
   git push --force --all
   ```

3. **Notify team members**
   - They must re-clone the repository
   - Old clones contain the secret in history

### 🔍 Regular Security Audits

Run these commands regularly:

```bash
# Scan for secrets
gitleaks detect --verbose

# Check .gitignore is working
git status --ignored

# List all tracked .env.http files (should be none except examples)
git ls-files | grep ".env.http"

# Check for accidentally staged secrets
git diff --cached | grep -i "token\|secret\|password"
```

### 📚 Configuration Files

This repository includes:

- **`.pre-commit-config.yaml`** - Pre-commit hook configuration
- **`.gitleaks.toml`** - Gitleaks configuration with custom rules
- **`.gitleaksignore`** - Allowlist for false positives
- **`.githooks/pre-commit`** - Manual git hook script
- **`.gitignore`** - Prevents committing .env.http files

### ✅ Checklist Before Committing

- [ ] No hardcoded tokens or passwords
- [ ] Using `{{variables}}` or `$ENV_VARS` for secrets
- [ ] `.env.http` files are gitignored
- [ ] Only `.env.http.example` files are committed
- [ ] Pre-commit hooks are installed and passing
- [ ] Reviewed `git diff` before commit

### 📞 Reporting Security Issues

If you discover a security vulnerability:

1. **DO NOT** open a public issue
2. Email: security@example.com (or create a confidential GitLab issue)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### 🔗 Resources

- [GitLab Token Security](https://docs.gitlab.com/ee/security/token_overview.html)
- [OWASP Secrets Management](https://owasp.org/www-community/vulnerabilities/Use_of_hard-coded_password)
- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [Pre-commit Framework](https://pre-commit.com/)

---

**Remember**: Prevention is better than remediation. Use the tools above to prevent secrets from ever entering your git history.
