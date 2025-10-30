#!/bin/bash
# Claude Code Container - First Run Initialization
# This script runs on first container startup to help users set up their environment

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Welcome to Claude Code Container v1.0.1${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if this is first run
MARKER_FILE="/home/claude/.claude-container-initialized"

if [ -f "$MARKER_FILE" ]; then
    echo -e "${GREEN}Container already initialized. Welcome back!${NC}"
    echo ""
    echo "Quick commands:"
    echo "  - Create new project: Use the BaseProject template setup"
    echo "  - View guides: ls ~/ClaudeUsage/"
    echo "  - House agents: Available at ~/.claude/agents/"
    echo ""
    exit 0
fi

echo -e "${GREEN}First-time setup detected. Let's get you started!${NC}"
echo ""

# Copy BaseProject files to user home
echo -e "${BLUE}Installing BaseProject workflow guides...${NC}"
cp -r /opt/claude-config/ClaudeUsage /home/claude/
cp /opt/claude-config/TEMPLATE_CLAUDE.md /home/claude/
cp /opt/claude-config/secrets_template.json /home/claude/
cp /opt/claude-config/template.gitignore /home/claude/.gitignore_template
echo -e "${GREEN}✓ BaseProject guides installed to ~/ClaudeUsage/${NC}"

# Install house-agents
echo -e "${BLUE}Installing house-agents...${NC}"
mkdir -p /home/claude/.claude/agents
cp -r /opt/claude-config/.claude/agents/* /home/claude/.claude/agents/
cp /opt/claude-config/CREDITS.md /home/claude/
echo -e "${GREEN}✓ House agents installed to ~/.claude/agents/${NC}"
echo -e "  ${YELLOW}Credits: house-agents by @houseworthe, house-coder by AutumnsGrove${NC}"

# Create helpful aliases
echo -e "${BLUE}Setting up helpful aliases...${NC}"
cat >> /home/claude/.bashrc << 'BASHRC_EOF'

# Claude Code Container Aliases
alias claude-new-project='echo "Use: Clone https://github.com/AutumnsGrove/BaseProject to set up a new project"'
alias claude-guides='ls -la ~/ClaudeUsage/ && echo -e "\nRead guides with: cat ~/ClaudeUsage/[guide-name].md"'
alias claude-agents='ls -la ~/.claude/agents/ && echo -e "\nHouse agents are ready to use!"'
alias claude-secrets='cat ~/secrets_template.json && echo -e "\nCopy to secrets.json and fill in your API keys"'

BASHRC_EOF
echo -e "${GREEN}✓ Aliases added to ~/.bashrc${NC}"

# Create example project structure
echo -e "${BLUE}Creating example workspace structure...${NC}"
mkdir -p /workspace/.examples
cat > /workspace/.examples/NEW_PROJECT_SETUP.md << 'SETUP_EOF'
# Setting Up a New Project in Claude Code Container

## Quick Start

Tell Claude Code:

```
Clone https://github.com/AutumnsGrove/BaseProject (master branch) to /tmp, copy to /workspace/[PROJECT NAME] excluding (.git/), rename TEMPLATE_CLAUDE.md to CLAUDE.md, customize CLAUDE.md sections (Project Purpose, Tech Stack, API Keys List, Architecture Notes) and README.md (title, description, features) with my project details [ASK ME: name, description, tech stack, API keys needed], init language-specific dependencies (uv for Python, npm for JS, go mod for Go), create proper directory structure (src/ with __init__.py or index.js, tests/ with __init__.py), generate secrets_template.json with my API key placeholders, write TODOS.md with 3-5 initial tasks derived from project description, git init with user.name and user.email from global git config, make initial commit "feat: initialize [PROJECT] from BaseProject template", display project summary and next steps
```

Claude will interactively set up your project with:
- Proper directory structure
- Language-specific dependency management
- Git repository initialization
- Workflow documentation
- TODO tracking

## Available Resources

- **Workflow Guides**: `~/ClaudeUsage/` - 18+ comprehensive guides
- **House Agents**: `~/.claude/agents/` - Context-saving specialized agents
- **Secrets Template**: `~/secrets_template.json` - Common API key template
- **Git Ignore Template**: `~/.gitignore_template` - Comprehensive .gitignore

## Example Project Types

### Python Project
```bash
cd /workspace
# Tell Claude: "Set up a new Python project called 'my-api' using FastAPI"
```

### Node.js Project
```bash
cd /workspace
# Tell Claude: "Set up a new Node.js project called 'my-app' using Express"
```

### Go Project
```bash
cd /workspace
# Tell Claude: "Set up a new Go project called 'my-service' as a REST API"
```

## House Agents

Use specialized agents for heavy operations:

- `house-research` - Search across many files (saves 95% context)
- `house-git` - Analyze large diffs (saves 98% context)
- `house-bash` - Process command output (saves 97% context)

Example:
```
Use house-research to find all authentication-related functions in the codebase
```

## Next Steps

1. Review available guides: `claude-guides`
2. Check house agents: `claude-agents`
3. Set up secrets: Copy `~/secrets_template.json` to your project
4. Start coding with Claude Code!

---

**Container Version**: 1.0.1
**BaseProject**: https://github.com/AutumnsGrove/BaseProject
**House Agents**: https://github.com/houseworthe/house-agents
SETUP_EOF
echo -e "${GREEN}✓ Example docs created at /workspace/.examples/${NC}"

# Mark as initialized
touch "$MARKER_FILE"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Initialization complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Quick Start:${NC}"
echo "  1. Read setup guide: cat /workspace/.examples/NEW_PROJECT_SETUP.md"
echo "  2. View workflow guides: claude-guides"
echo "  3. Check house agents: claude-agents"
echo "  4. Create a new project: Tell Claude to use BaseProject template"
echo ""
echo -e "${GREEN}Happy coding with Claude! 🤖${NC}"
echo ""
