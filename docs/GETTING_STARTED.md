# Getting Started with Claude Code Container

## 🚀 Quick Setup (< 5 minutes)

### 1. Clone and Setup
```bash
git clone https://github.com/yourusername/claude-code-container.git
cd claude-code-container
chmod +x setup.sh
./setup.sh
```

### 2. Restart Terminal
```bash
# Close and reopen terminal, or:
source ~/.zshrc  # or ~/.bashrc
```

### 3. Start Container
```bash
claude-container
# You're now inside the secure environment!
```

## 📁 Working with Files

### Your Workspace Structure
```
~/ClaudeCodeWorkspace/
├── Projects/        # Your code goes here
├── Documentation/   # Docs and presets
├── Research/       # Research materials
├── shared/         # Files shared with your Mac
├── imports/        # Drop files here to use in container
└── exports/        # Container puts files here for you
```

### Moving Files In/Out

**Import files to container:**
```bash
# On your Mac:
cp myfile.txt ~/ClaudeCodeWorkspace/imports/

# Inside container:
ls /workspace/imports/
```

**Export files from container:**
```bash
# Inside container:
cp myproject.zip /workspace/exports/

# On your Mac:
ls ~/ClaudeCodeWorkspace/exports/
```

## 🎯 Common Tasks

### Start a Python Project
```bash
# Inside container
proj                           # Go to Projects folder
mkdir my-app && cd my-app
py -m venv venv               # Create virtual environment
source venv/bin/activate
pip install requests pandas
```

### Use Claude Code
```bash
# Inside container
cc                            # Start Claude Code
cc --project my-app          # Start with specific project context
cc --research                # Research mode with MCP servers
```

### Git Workflow
```bash
# Inside container
gs                           # git status
ga .                        # git add all
gc -m "Initial commit"      # git commit
gp                          # git push
```

## 🛠️ Container Management

### From your Mac (outside container):

**Check status:**
```bash
./manage.sh status
```

**Stop container:**
```bash
./manage.sh stop
```

**Backup workspace:**
```bash
./manage.sh backup
```

**Import a file:**
```bash
./manage.sh import ~/Downloads/data.csv
```

**Reset container (keeps your files):**
```bash
./manage.sh reset
```

## 💡 Pro Tips

### 1. Use Aliases
Inside the container, use these shortcuts:
- `proj` - Jump to Projects folder
- `docs` - Jump to Documentation
- `py` - Python 3.11
- `cc` - Claude Code

### 2. Persistent Work
Your work persists between sessions. The container can be stopped and restarted without losing files.

### 3. MCP Servers
The Sequential Thinking and Zen MCP servers are pre-configured. Claude Code will automatically use them for enhanced capabilities.

### 4. Custom Presets
Add your own prompt templates to:
```
~/ClaudeCodeWorkspace/Documentation/presets/
```

### 5. Multiple Projects
Create separate folders in `/workspace/Projects/` for different projects:
```bash
/workspace/Projects/
├── web-app/
├── data-analysis/
└── ml-model/
```

## 🆘 Troubleshooting

### Container won't start
```bash
./manage.sh status          # Check what's wrong
./manage.sh reset          # Reset if needed
./setup.sh                 # Re-run setup
```

### Can't find imported files
Files go to: `~/ClaudeCodeWorkspace/imports/`
Inside container: `/workspace/imports/`

### Permission issues
```bash
# On your Mac:
chmod -R 755 ~/ClaudeCodeWorkspace
```

### Out of space
```bash
# Check space usage
./manage.sh status

# Clean up Docker
docker system prune -a
```

## 📚 Next Steps

1. **Explore the presets** in `/workspace/Documentation/presets/`
2. **Configure git** with your credentials inside the container
3. **Install additional tools** as needed with `apt-get` or `pip`
4. **Create your first project** in `/workspace/Projects/`

## 🔗 Useful Links

- [Claude Code Documentation](https://docs.claude.com)
- [MCP Servers Documentation](https://github.com/modelcontextprotocol)
- [Docker Documentation](https://docs.docker.com)

---

**Need help?** Check the full README.md or open an issue on GitHub.
