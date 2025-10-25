#!/bin/bash
# Setup script for security tools and git hooks
# Usage: ./scripts/setup-security.sh

set -e

echo "🔒 Setting up security tools for nrest.nvim"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "lua/nrest/init.lua" ]; then
    echo -e "${RED}Error: Please run this script from the nrest.nvim root directory${NC}"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Install git hooks
echo "📌 Step 1: Installing git hooks"
if [ -f ".githooks/pre-commit" ]; then
    ln -sf ../../.githooks/pre-commit .git/hooks/pre-commit
    chmod +x .githooks/pre-commit
    echo -e "${GREEN}✓${NC} Git hook installed: .git/hooks/pre-commit"
else
    echo -e "${YELLOW}⚠${NC}  Git hook not found: .githooks/pre-commit"
fi
echo ""

# Step 2: Check for gitleaks
echo "📌 Step 2: Checking for gitleaks"
if command_exists gitleaks; then
    GITLEAKS_VERSION=$(gitleaks version)
    echo -e "${GREEN}✓${NC} gitleaks is installed: $GITLEAKS_VERSION"
else
    echo -e "${YELLOW}⚠${NC}  gitleaks is not installed"
    echo ""
    echo "To install gitleaks:"
    echo "  macOS:    brew install gitleaks"
    echo "  Linux:    Download from https://github.com/gitleaks/gitleaks/releases"
    echo "  Go:       go install github.com/gitleaks/gitleaks/v8@latest"
    echo ""
fi
echo ""

# Step 3: Check for pre-commit framework (optional)
echo "📌 Step 3: Checking for pre-commit framework (optional)"
if command_exists pre-commit; then
    PRECOMMIT_VERSION=$(pre-commit --version)
    echo -e "${GREEN}✓${NC} pre-commit is installed: $PRECOMMIT_VERSION"

    read -p "Install pre-commit hooks? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pre-commit install
        echo -e "${GREEN}✓${NC} Pre-commit hooks installed"
    fi
else
    echo -e "${YELLOW}⚠${NC}  pre-commit framework is not installed (optional)"
    echo ""
    echo "To install pre-commit:"
    echo "  pip install pre-commit"
    echo "  Then run: pre-commit install"
    echo ""
fi
echo ""

# Step 4: Test the setup
echo "📌 Step 4: Testing security setup"
if command_exists gitleaks; then
    echo "Running gitleaks scan..."
    if gitleaks detect --no-git --redact 2>&1 | head -20; then
        echo -e "${GREEN}✓${NC} Gitleaks scan completed"
    else
        echo -e "${YELLOW}⚠${NC}  Gitleaks found potential issues (see above)"
    fi
else
    echo -e "${YELLOW}⚠${NC}  Skipping gitleaks test (not installed)"
fi
echo ""

# Step 5: Check .gitignore
echo "📌 Step 5: Verifying .gitignore configuration"
if grep -q "\.env\.http" .gitignore; then
    echo -e "${GREEN}✓${NC} .gitignore includes .env.http"
else
    echo -e "${RED}✗${NC} .gitignore does not include .env.http"
    echo "Adding .env.http to .gitignore..."
    echo "" >> .gitignore
    echo "# Environment files (may contain secrets)" >> .gitignore
    echo ".env.http" >> .gitignore
    echo "*.env.http" >> .gitignore
    echo -e "${GREEN}✓${NC} Added .env.http to .gitignore"
fi
echo ""

# Step 6: Create .env.http.example if needed
echo "📌 Step 6: Checking for .env.http.example"
if [ -f "examples/.env.http.example" ]; then
    echo -e "${GREEN}✓${NC} Example file exists: examples/.env.http.example"
else
    echo -e "${YELLOW}⚠${NC}  Example file not found"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Security setup complete!"
echo ""
echo "✅ What's configured:"
echo "  • Git pre-commit hook (blocks commits with secrets)"
echo "  • .gitignore (prevents committing .env.http files)"
if command_exists gitleaks; then
    echo "  • Gitleaks (scans for secrets in code)"
fi
if command_exists pre-commit; then
    echo "  • Pre-commit framework (automated checks)"
fi
echo ""
echo "📚 Next steps:"
echo "  1. Copy examples/.env.http.example to .env.http"
echo "  2. Add your real tokens to .env.http"
echo "  3. Configure nrest to use it: env_file = 'auto'"
echo ""
echo "📖 Read the security guide: SECURITY.md"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
