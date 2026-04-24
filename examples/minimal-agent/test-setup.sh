#!/bin/bash

# Integration tests for minimal-agent setup
# Validates all required files and configurations

set -e

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

FAILED=0

echo "========================================="
echo "Minimal Agent Setup Integration Tests"
echo "========================================="
echo ""

# Test 1: Validate docker-compose.yml structure
test_compose_valid() {
    echo -n "Test 1: Validating docker-compose.yml... "

    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "  - docker-compose.yml not found"
        return 1
    fi

    # Check for required services
    if ! grep -q "services:" docker-compose.yml; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Missing 'services:' section"
        return 1
    fi

    if ! grep -q "minimal-agent:" docker-compose.yml; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Missing 'minimal-agent' service"
        return 1
    fi

    # Check for required volumes
    if ! grep -q "./skills:" docker-compose.yml; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Missing skills volume mount"
        return 1
    fi

    if ! grep -q "./servers.json:/app/servers.json:ro" docker-compose.yml; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Missing servers.json volume mount"
        return 1
    fi

    # Check for environment configuration
    if ! grep -q "environment:" docker-compose.yml; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Missing environment configuration"
        return 1
    fi

    echo -e "${GREEN}PASSED${NC}"
    return 0
}

# Test 2: Validate .env.example has required variables
test_env_example() {
    echo -n "Test 2: Validating .env.example... "

    if [ ! -f ".env.example" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "  - .env.example not found"
        return 1
    fi

    # Check for required variables
    if ! grep -q "ANTHROPIC_API_KEY=" .env.example; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Missing ANTHROPIC_API_KEY"
        return 1
    fi

    if ! grep -q "RUNTIME_AGENT=" .env.example; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Missing RUNTIME_AGENT"
        return 1
    fi

    echo -e "${GREEN}PASSED${NC}"
    return 0
}

# Test 3: Validate skills directory and example skill
test_skills_exist() {
    echo -n "Test 3: Validating skills directory... "

    if [ ! -d "skills" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "  - skills/ directory not found"
        return 1
    fi

    if [ ! -f "skills/hello-world/skill.md" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "  - skills/hello-world/skill.md not found"
        return 1
    fi

    # Check skill.md has valid skill structure
    if ! grep -q "^# " skills/hello-world/skill.md; then
        echo -e "${RED}FAILED${NC}"
        echo "  - skills/hello-world/skill.md missing skill header"
        return 1
    fi

    # Check for frontmatter with name
    if ! grep -q "^name: hello-world" skills/hello-world/skill.md; then
        echo -e "${RED}FAILED${NC}"
        echo "  - skills/hello-world/skill.md missing name in frontmatter"
        return 1
    fi

    echo -e "${GREEN}PASSED${NC}"
    return 0
}

# Test 4: Validate mcp-servers.json structure
test_mcp_config() {
    echo -n "Test 4: Validating servers.json... "

    if [ ! -f "servers.json" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "  - servers.json not found"
        return 1
    fi

    # Check for valid JSON structure
    if ! command -v jq &> /dev/null; then
        echo -e "${GREEN}PASSED${NC} (jq not available, skipping JSON validation)"
        return 0
    fi

    if ! jq empty servers.json 2>/dev/null; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Invalid JSON in servers.json"
        return 1
    fi

    # Check for mcpServers key
    if ! jq -e '.mcpServers' servers.json >/dev/null 2>&1; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Missing 'mcpServers' key"
        return 1
    fi

    echo -e "${GREEN}PASSED${NC}"
    return 0
}

# Test 5: Validate .gitignore has required entries
test_gitignore() {
    echo -n "Test 5: Validating .gitignore... "

    if [ ! -f ".gitignore" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "  - .gitignore not found"
        return 1
    fi

    # Check for required entries
    if ! grep -q "^\.env$" .gitignore; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Missing .env entry"
        return 1
    fi

    if ! grep -q ".*\.keys\.json$" .gitignore; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Missing *.keys.json entry"
        return 1
    fi

    echo -e "${GREEN}PASSED${NC}"
    return 0
}

# Test 6: Validate helper scripts exist and are executable
test_scripts_exist() {
    echo -n "Test 6: Validating helper scripts... "

    if [ ! -f "start.sh" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "  - start.sh not found"
        return 1
    fi

    if [ ! -x "start.sh" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "  - start.sh not executable"
        return 1
    fi

    if [ ! -f "stop.sh" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "  - stop.sh not found"
        return 1
    fi

    if [ ! -x "stop.sh" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "  - stop.sh not executable"
        return 1
    fi

    echo -e "${GREEN}PASSED${NC}"
    return 0
}

# Test 7: Validate README.md has required sections (optional)
test_readme() {
    echo -n "Test 7: Validating README.md... "

    if [ ! -f "README.md" ]; then
        echo -e "${GREEN}SKIPPED${NC} (README.md not present - optional)"
        return 0
    fi

    # Check for required sections
    if ! grep -q "# Minimal Agent" README.md; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Missing title"
        return 1
    fi

    if ! grep -q "## Quick Start" README.md && ! grep -q "## Getting Started" README.md; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Missing Quick Start or Getting Started section"
        return 1
    fi

    echo -e "${GREEN}PASSED${NC}"
    return 0
}

# Run all tests
test_compose_valid || FAILED=$((FAILED+1))
test_env_example || FAILED=$((FAILED+1))
test_skills_exist || FAILED=$((FAILED+1))
test_mcp_config || FAILED=$((FAILED+1))
test_gitignore || FAILED=$((FAILED+1))
test_scripts_exist || FAILED=$((FAILED+1))
test_readme || FAILED=$((FAILED+1))

echo ""
echo "========================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    echo "========================================="
    exit 0
else
    echo -e "${RED}$FAILED test(s) failed${NC}"
    echo "========================================="
    exit 1
fi
