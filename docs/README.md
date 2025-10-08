# Claude Code Secure Container Environment

A secure, containerized development environment for Claude Code using Apple's native container framework. This solution provides file system isolation, persistent workspaces, and pre-configured development tools.

> **Implementation Note:** This project uses [Apple's container framework](https://github.com/apple/container), not Docker. The implementation is currently in development.

## 🎯 Features

- **Secure File Access**: Isolated container environment with controlled access to your file system
- **Pre-installed Tools**:
  - Git
  - Python 3.11
  - Claude Code with MCP servers (Sequential Thinking & Zen)
  - Homebrew
  - UV (fast Python package manager)
  - Custom prompt presets for enhanced workflows
- **Organized Workspace**: Pre-structured directories for Projects, Documentation, and Research
- **Persistent Storage**: Keep your work across sessions until you're ready to start fresh
- **Easy Setup**: Get started in less than 5 minutes

## 📋 Prerequisites

- macOS 13.0 or later
- Xcode Command Line Tools
- At least 8GB of available RAM
- 50GB of free disk space

## 🚀 Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/claude-code-container.git
   cd claude-code-container
   ```

2. **Run the setup script**:
   ```bash
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```

3. **Start the container**:
   ```bash
   claude-container
   # or
   cc-container
   ```

That's it! You're now in a secure Claude Code environment.

## 📁 Workspace Structure

Your workspace is created at `~/ClaudeCodeWorkspace/` with the following structure:

```
ClaudeCodeWorkspace/
├── Projects/        # Your coding projects
├── Documentation/   # Documentation and prompt presets
│   └── presets/    # Claude Code prompt templates
├── Research/       # Research materials
├── shared/         # Bidirectional file sharing with host
├── exports/        # Files to export from container
└── imports/        # Files to import into container
```

## 🔧 Container Management

### Starting the Container
```bash
claude-container     # Start and attach to container
```

### Inside the Container
- `cc` - Launch Claude Code
- `proj` - Navigate to Projects directory
- `docs` - Navigate to Documentation directory
- `research` - Navigate to Research directory

### File Sharing
- Place files in `~/ClaudeCodeWorkspace/imports/` to access them in the container
- Export files by placing them in `/workspace/exports/` within the container
- Use `/workspace/shared/` for bidirectional file access

## 🤖 MCP Servers

The following MCP (Model Context Protocol) servers are pre-installed:

### Sequential Thinking
Enables step-by-step problem-solving workflows
- [GitHub Repository](https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking)

### Zen MCP Server
Provides enhanced mindfulness and focused development patterns
- [GitHub Repository](https://github.com/BeehiveInnovations/zen-mcp-server)

## 📝 Preset Prompts

The container includes curated prompt templates for:
- Git commit message guidelines
- Agentic workflow patterns
- Research subagent configurations
- And more...

Find these in `/workspace/Documentation/presets/` within the container.

## 🔄 Persistence & Cleanup

### Data Persistence
Your work persists across container sessions by default. The workspace directory on your host machine maintains all your files.

### Starting Fresh
To completely reset your environment:

1. Export any important work:
   ```bash
   # Inside container
   cp -r /workspace/Projects/* /workspace/exports/
   ```

2. Stop the container:
   ```bash
   # Exit the container
   exit
   ```

3. Clean the workspace:
   ```bash
   # On host machine
   rm -rf ~/ClaudeCodeWorkspace/*
   ```

4. Re-run setup:
   ```bash
   ./scripts/setup.sh
   ```

## 🛠️ Customization

### Adding Your Own Presets
Place markdown files in the `presets/` directory before running setup, or add them to `~/ClaudeCodeWorkspace/Documentation/presets/` after setup.

### Modifying Installed Packages
Edit `scripts/install-base.sh` to add or remove packages before running the setup.

### Adjusting Container Resources
Modify the container configuration in `src/init-container.swift`:
- Memory allocation (default: 8GB)
- Storage size (default: 50GB)
- CPU cores

## 🐛 Troubleshooting

### Container Won't Start
- Ensure you have sufficient disk space and RAM
- Check that virtualization is enabled in your Mac's settings
- Try restarting the setup: `./scripts/setup.sh --reset`

### File Permissions Issues
- Ensure files in the shared directories have appropriate permissions
- Use `chmod` to adjust as needed

### MCP Servers Not Working
- Check the configuration at `~/.config/claude-code/mcp-config.json`
- Verify Node.js installation: `node --version` (should be v20+)

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- [Claude Code](https://claude.ai) by Anthropic
- [Apple Container Framework](https://github.com/apple/container)
- [Apple Virtualization Framework](https://developer.apple.com/documentation/virtualization)
- MCP Server developers
- The Claude community
- Initial architecture designed with Claude 4.1 Opus

## 📞 Support

For issues or questions:
- Open an issue on GitHub
- Check the [Discussions](https://github.com/yourusername/claude-code-container/discussions) tab
- Review closed issues for common problems

---

**Note**: This project is not officially affiliated with Anthropic. It's a community tool designed to enhance the Claude Code experience with better security and organization.
