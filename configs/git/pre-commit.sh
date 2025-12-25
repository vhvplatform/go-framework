#!/bin/bash
#
# Git pre-commit hook for go-devtools
# This hook runs before each commit to ensure code quality
#
# Installation:
#   cp configs/git/pre-commit.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# To bypass this hook temporarily (not recommended):
#   git commit --no-verify
#

set -e

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Running pre-commit checks...${NC}\n"

# Track if any checks fail
CHECKS_FAILED=0

# Function to print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print error
print_error() {
    echo -e "${RED}✗${NC} $1"
    CHECKS_FAILED=1
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check 1: Prevent commits to main/master branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
    print_error "Direct commits to $BRANCH branch are not allowed"
    echo "  Please create a feature branch and submit a pull request"
    exit 1
fi
print_success "Branch check passed ($BRANCH)"

# Check 2: Check for debug statements
echo ""
echo "Checking for debug statements..."
if git diff --cached --name-only | grep -E '\.(go|sh)$' | xargs grep -n -E '(console\.log|print\(|fmt\.Println.*TODO|DEBUG)' 2>/dev/null; then
    print_warning "Found potential debug statements (review before committing)"
else
    print_success "No debug statements found"
fi

# Check 3: Check for TODO/FIXME without issue reference
echo ""
echo "Checking for TODO/FIXME comments..."
if git diff --cached --name-only | grep -E '\.(go|sh|md)$' | xargs grep -n -E '(TODO|FIXME)(?!.*#[0-9]+)' 2>/dev/null; then
    print_warning "Found TODO/FIXME without issue reference"
    echo "  Consider referencing an issue: TODO(#123): description"
else
    print_success "TODO/FIXME checks passed"
fi

# Check 4: Check Go files if any are staged
GO_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.go$' || true)
if [ -n "$GO_FILES" ]; then
    echo ""
    echo "Running Go checks..."
    
    # Go fmt check
    echo "  Checking Go formatting..."
    UNFORMATTED=$(gofmt -l $GO_FILES)
    if [ -n "$UNFORMATTED" ]; then
        print_error "Go files are not formatted:"
        echo "$UNFORMATTED"
        echo "  Run: gofmt -w $GO_FILES"
        exit 1
    fi
    print_success "Go formatting is correct"
    
    # Go vet check
    echo "  Running go vet..."
    if ! go vet ./...; then
        print_error "go vet found issues"
        exit 1
    fi
    print_success "go vet passed"
    
    # Run tests for modified packages
    echo "  Running tests for modified packages..."
    PACKAGES=$(echo "$GO_FILES" | xargs -I {} dirname {} | sort -u | xargs -I {} echo ./{})
    if [ -n "$PACKAGES" ]; then
        if ! go test $PACKAGES; then
            print_error "Tests failed"
            exit 1
        fi
        print_success "Tests passed"
    fi
    
    # Run golangci-lint if available
    if command -v golangci-lint &> /dev/null; then
        echo "  Running golangci-lint..."
        if ! golangci-lint run --new-from-rev=HEAD~ $GO_FILES; then
            print_error "golangci-lint found issues"
            echo "  Fix issues or run: golangci-lint run --fix"
            exit 1
        fi
        print_success "golangci-lint passed"
    else
        print_warning "golangci-lint not installed (recommended)"
        echo "  Install: brew install golangci-lint"
    fi
fi

# Check 5: Check shell scripts if any are staged
SHELL_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$' || true)
if [ -n "$SHELL_FILES" ]; then
    echo ""
    echo "Running shell script checks..."
    
    # Check for bash shebang
    for file in $SHELL_FILES; do
        if ! head -n 1 "$file" | grep -q '^#!/bin/bash'; then
            print_warning "$file: Missing or incorrect shebang (should be #!/bin/bash)"
        fi
    done
    
    # Check for set -e
    for file in $SHELL_FILES; do
        if ! grep -q 'set -e' "$file"; then
            print_warning "$file: Missing 'set -e' for error handling"
        fi
    done
    
    # Run shellcheck if available
    if command -v shellcheck &> /dev/null; then
        echo "  Running shellcheck..."
        if ! shellcheck $SHELL_FILES; then
            print_error "shellcheck found issues"
            exit 1
        fi
        print_success "shellcheck passed"
    else
        print_warning "shellcheck not installed (recommended)"
        echo "  Install: brew install shellcheck"
    fi
fi

# Check 6: Check for large files
echo ""
echo "Checking for large files..."
LARGE_FILES=$(git diff --cached --name-only | xargs ls -l 2>/dev/null | awk '$5 > 1048576 {print $9}' || true)
if [ -n "$LARGE_FILES" ]; then
    print_error "Large files detected (>1MB):"
    echo "$LARGE_FILES"
    echo "  Consider using Git LFS or removing these files"
    exit 1
fi
print_success "No large files detected"

# Check 7: Check for secrets/credentials
echo ""
echo "Checking for potential secrets..."
STAGED_FILES=$(git diff --cached --name-only)
SECRET_PATTERNS=(
    "password\s*=\s*['\"][^'\"]{3,}"
    "api[_-]?key\s*=\s*['\"][^'\"]{10,}"
    "secret\s*=\s*['\"][^'\"]{10,}"
    "token\s*=\s*['\"][^'\"]{10,}"
    "private[_-]?key"
    "BEGIN.*PRIVATE.*KEY"
)

SECRETS_FOUND=0
for pattern in "${SECRET_PATTERNS[@]}"; do
    if echo "$STAGED_FILES" | xargs grep -i -E "$pattern" 2>/dev/null; then
        SECRETS_FOUND=1
    fi
done

if [ $SECRETS_FOUND -eq 1 ]; then
    print_error "Potential secrets detected in staged files"
    echo "  Review the highlighted lines above"
    exit 1
fi
print_success "No secrets detected"

# Final result
echo ""
if [ $CHECKS_FAILED -eq 1 ]; then
    echo -e "${RED}❌ Pre-commit checks failed${NC}"
    echo "  Fix the issues above before committing"
    echo "  Or use --no-verify to skip (not recommended)"
    exit 1
else
    echo -e "${GREEN}✅ All pre-commit checks passed!${NC}"
    exit 0
fi
