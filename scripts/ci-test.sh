#!/usr/bin/env bash
# ci-test.sh - Continuous integration test runner

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXIT_CODE=0

echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Anthonyware CI Test Suite                                ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo

# Test 1: Shellcheck
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test: Shellcheck"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ -x "$REPO_ROOT/scripts/shellcheck-all.sh" ]]; then
  if bash "$REPO_ROOT/scripts/shellcheck-all.sh"; then
    echo "✓ Shellcheck passed"
  else
    echo "✗ Shellcheck failed"
    EXIT_CODE=1
  fi
else
  echo "⊘ Shellcheck test not found"
fi
echo

# Test 2: Syntax validation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test: Syntax Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SYNTAX_ERRORS=0
while IFS= read -r script; do
  if ! bash -n "$script" 2>/dev/null; then
    echo "✗ Syntax error: $script"
    ((SYNTAX_ERRORS++))
    EXIT_CODE=1
  fi
done < <(find "$REPO_ROOT" -name "*.sh" -type f)

if [[ $SYNTAX_ERRORS -eq 0 ]]; then
  echo "✓ All scripts have valid syntax"
else
  echo "✗ $SYNTAX_ERRORS script(s) with syntax errors"
fi
echo

# Test 3: Framework tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test: Framework Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ -x "$REPO_ROOT/tests/test-framework.sh" ]]; then
  if bash "$REPO_ROOT/tests/test-framework.sh"; then
    echo "✓ Framework tests passed"
  else
    echo "✗ Framework tests failed"
    EXIT_CODE=1
  fi
else
  echo "⊘ Framework tests not found"
fi
echo

# Test 4: Profile validation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test: Profile Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
PROFILE_ERRORS=0
while IFS= read -r profile; do
  # Check that referenced scripts exist
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^@include ]] && continue
    
    if [[ ! -f "$REPO_ROOT/install/$line" ]]; then
      echo "✗ Profile references missing script: $profile -> $line"
      ((PROFILE_ERRORS++))
      EXIT_CODE=1
    fi
  done < "$profile"
done < <(find "$REPO_ROOT/profiles" -name "*.conf" -type f 2>/dev/null)

if [[ $PROFILE_ERRORS -eq 0 ]]; then
  echo "✓ All profiles valid"
else
  echo "✗ $PROFILE_ERRORS profile error(s)"
fi
echo

# Test 5: Markdown linting
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test: Markdown Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
MD_COUNT=$(find "$REPO_ROOT" -name "*.md" -type f | wc -l)
echo "Found $MD_COUNT markdown file(s)"
if command -v markdownlint >/dev/null 2>&1; then
  if markdownlint "$REPO_ROOT"/**/*.md 2>/dev/null; then
    echo "✓ Markdown files passed linting"
  else
    echo "⚠ Markdown linting warnings (non-fatal)"
  fi
else
  echo "⊘ markdownlint not installed, skipping"
fi
echo

# Summary
echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Test Summary                                              ║"
echo "╚══════════════════════════════════════════════════════════╝"
if [[ $EXIT_CODE -eq 0 ]]; then
  echo "✓ All tests passed"
else
  echo "✗ Some tests failed"
fi
echo

exit $EXIT_CODE
