# BaseProject Integration Guide

## Overview

ClaudeCodeContainer v1.0.1+ includes full integration with [BaseProject](https://github.com/AutumnsGrove/BaseProject), providing comprehensive workflow guides, best practices, and project templates for Claude Code development.

## What's Included

### Workflow Guides (18+ Guides)

Located at `~/ClaudeUsage/` inside the container:

- **Git Workflow** (`git_workflow.md`, `git_commit_guide.md`) - Version control best practices
- **Secrets Management** (`secrets_management.md`, `secrets_advanced.md`) - API key handling
- **Code Quality** (`code_style_guide.md`, `code_quality.md`) - Style guidelines
- **Testing** (`testing_strategies.md`) - Test patterns and strategies
- **Package Management** (`uv_usage.md`) - Python UV package manager guide
- **Docker** (`docker_guide.md`) - Containerization best practices
- **CI/CD** (`ci_cd_patterns.md`) - GitHub Actions workflows
- **House Agents** (`house_agents.md`) - Specialized agent usage
- **Research** (`research_workflow.md`) - Code exploration patterns
- **Documentation** (`documentation_standards.md`) - Writing maintainable docs
- **Database** (`database_setup.md`) - Database configuration
- **Multi-Language** (`multi_language_guide.md`) - Python, JS, Go, Rust support
- **Project Setup** (`project_setup.md`, `project_structure.md`) - Initialization patterns

### House Agents

Located at `~/.claude/agents/` inside the container:

1. **house-research** - Codebase search (95% context savings)
   - Search across 20+ files
   - Find patterns, TODOs, API endpoints
   - Returns condensed summaries

2. **house-git** - Git analysis (98% context savings)
   - Analyze large diffs (100+ lines)
   - Review commit history
   - Branch comparisons

3. **house-bash** - Command execution (97% context savings)
   - Run tests and builds
   - Process verbose output
   - Return actionable summaries

4. **house-coder** - Quick code patches
   - Implement 0-250 line changes
   - Fix imports and bugs
   - Fast, surgical modifications
   - Custom agent by AutumnsGrove

### Templates

- **TEMPLATE_CLAUDE.md** - Main project instructions template
- **secrets_template.json** - Common API key placeholders
- **.gitignore_template** - Comprehensive gitignore

## First-Run Experience

When you first start the container, an initialization script automatically:

1. Copies all BaseProject guides to `~/ClaudeUsage/`
2. Installs house-agents to `~/.claude/agents/`
3. Sets up helpful bash aliases
4. Creates example documentation
5. Displays welcome message with quick start info

## Using the Guides

### Quick Reference

Inside the container, use these aliases:

```bash
# List all available guides
claude-guides

# View a specific guide
cat ~/ClaudeUsage/git_workflow.md

# Check house agents
claude-agents

# View secrets template
claude-secrets
```

### Reading Order for New Projects

1. `project_structure.md` - Understand directory layouts
2. `git_workflow.md` - Learn version control patterns
3. `secrets_management.md` - Handle API keys safely
4. `uv_usage.md` - Python dependency management (if using Python)
5. `testing_strategies.md` - Set up tests
6. `house_agents.md` - Use specialized agents

## Creating New Projects with BaseProject

Tell Claude Code:

```
Clone https://github.com/AutumnsGrove/BaseProject (master branch) to /tmp, copy to /workspace/[PROJECT NAME] excluding (.git/), rename TEMPLATE_CLAUDE.md to CLAUDE.md, customize CLAUDE.md sections (Project Purpose, Tech Stack, API Keys List, Architecture Notes) and README.md (title, description, features) with my project details [ASK ME: name, description, tech stack, API keys needed], init language-specific dependencies (uv for Python, npm for JS, go mod for Go), create proper directory structure (src/ with __init__.py or index.js, tests/ with __init__.py), generate secrets_template.json with my API key placeholders, write TODOS.md with 3-5 initial tasks derived from project description, git init with user.name and user.email from global git config, make initial commit "feat: initialize [PROJECT] from BaseProject template", display project summary and next steps
```

Claude will interactively:
- Ask for your project details
- Set up proper directory structure
- Initialize language-specific dependencies
- Create git repository
- Generate documentation

## House Agents Usage

### When to Use

Use house agents proactively when:

- **house-research**: Searching 20+ files for patterns
- **house-git**: Reviewing diffs over 100 lines
- **house-bash**: Running tests or builds with verbose output
- **house-coder**: Making focused 0-250 line code changes

### Examples

```
# Research
Use house-research to find all authentication functions in the codebase

# Git Analysis
Use house-git to analyze the changes in the last 5 commits

# Build Execution
Use house-bash to run the test suite and analyze failures

# Quick Code Fix
Use house-coder to add error handling to the login function
```

## Secrets Management

### Setup

1. Copy the template:
   ```bash
   cp ~/secrets_template.json /workspace/myproject/secrets.json
   ```

2. Fill in your API keys:
   ```json
   {
     "ANTHROPIC_API_KEY": "sk-ant-api03-your-actual-key",
     "OPENAI_API_KEY": "sk-your-actual-key",
     ...
   }
   ```

3. Ensure `.gitignore` includes `secrets.json`:
   ```bash
   echo "secrets.json" >> .gitignore
   ```

### Supported Services

The template includes placeholders for:
- Anthropic (Claude)
- OpenAI (GPT)
- GitHub
- Hugging Face
- Replicate
- Groq
- Together AI
- AWS
- Google Cloud
- Azure
- Pinecone
- Supabase
- Database URLs
- Redis

## Git Workflow Integration

BaseProject includes comprehensive git guides:

### Commit Message Format

```
[Action] [Brief description]

- [Specific change 1 with technical detail]
- [Specific change 2 with technical detail]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Action Verbs**: Add, Update, Fix, Refactor, Remove, Enhance

### Branch Strategy

For production projects, consider using dev/main strategy:
- `dev` - Development work
- `main` - Stable releases

See `git_workflow.md` for full details.

## Best Practices

### Daily Workflow

1. Check `TODOS.md` for pending tasks
2. Use house-research for codebase exploration
3. Follow git commit standards
4. Update TODOS.md as you progress
5. Run tests before commits

### Managing Large Codebases

1. Use house-research for searches (not grep/ripgrep directly)
2. Use house-git for diff analysis (not git diff directly)
3. Break complex tasks into subagents
4. Keep context clean with specialized agents

### Security

1. Never commit `secrets.json`
2. Use environment variable fallbacks
3. Provide `secrets_template.json` for team
4. Run pre-commit hooks (optional, see guides)

## Updating BaseProject Content

To get the latest guides from BaseProject:

```bash
# Inside container
cd /tmp
git clone https://github.com/AutumnsGrove/BaseProject.git
cp -r BaseProject/ClaudeUsage/* ~/ClaudeUsage/
```

Review changes before overwriting:
```bash
diff -r BaseProject/ClaudeUsage ~/ClaudeUsage
```

## Credits

- **BaseProject**: https://github.com/AutumnsGrove/BaseProject
- **House Agents**: https://github.com/houseworthe/house-agents by @houseworthe
- **house-coder**: Custom agent by AutumnsGrove (pending PR to house-agents)

See `~/CREDITS.md` inside the container for full credits.

## Troubleshooting

### Guides Not Available

If `~/ClaudeUsage/` is empty:

```bash
# Manually run first-run script
/opt/claude-config/first-run.sh
```

### House Agents Not Working

Check installation:
```bash
ls -la ~/.claude/agents/
```

Should show: `house-research.md`, `house-git.md`, `house-bash.md`, `house-coder.md`

### Aliases Not Working

Reload bashrc:
```bash
source ~/.bashrc
```

## Example Projects

### Python with FastAPI

```
Set up a new Python project called 'my-api' using FastAPI and UV package manager
```

### Node.js with Express

```
Set up a new Node.js project called 'my-app' using Express and npm
```

### Go REST API

```
Set up a new Go project called 'my-service' as a REST API with proper project structure
```

## Next Steps

1. Enter the container: `make enter`
2. View welcome message (shown on first run)
3. Read example setup: `cat /workspace/.examples/NEW_PROJECT_SETUP.md`
4. Browse guides: `claude-guides`
5. Create your first project using BaseProject template

## Support

- **Container Issues**: See main README.md
- **BaseProject Questions**: https://github.com/AutumnsGrove/BaseProject
- **House Agents Help**: https://github.com/houseworthe/house-agents
- **Claude Code Docs**: https://docs.anthropic.com/

---

**Version**: 1.0.1
**Last Updated**: 2025-10-30
**Integrated Projects**: BaseProject, House Agents
