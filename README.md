# Claude Code Container

A secure, containerized development environment for Claude Code using Apple's native container framework.

> **Note:** This project uses [Apple's container framework](https://github.com/apple/container) for native macOS virtualization, not Docker.

## 🎯 Project Status

This project is in **early development**. Initial scaffolding and architecture planning completed in a single session with Claude 4.1 Opus.

## 📋 Features (Planned)

- **Native macOS Virtualization**: Built on Apple's container framework
- **Secure File Access**: Isolated container environment with controlled workspace access
- **Pre-configured Development Tools**:
  - Git
  - Python 3.11
  - Claude Code with MCP servers
  - Homebrew
  - UV (fast Python package manager)
- **Organized Workspace**: Pre-structured directories for Projects, Documentation, and Research
- **Persistent Storage**: Workspace persists across container sessions

## 📁 Project Structure

```
ClaudeCodeContainer/
├── src/                    # Source code (Swift)
│   └── init-container.swift
├── scripts/                # Setup and management scripts
│   ├── setup.sh
│   ├── setup-unified.sh
│   └── manage.sh
├── docs/                   # Documentation
│   ├── README.md
│   ├── GETTING_STARTED.md
│   ├── SECURITY.md
│   └── GIT_COMMIT_STYLE.md
└── README.md              # This file
```

## 🚀 Quick Start

**Prerequisites:**
- macOS 13.0 or later
- Xcode Command Line Tools
- Apple's container framework

**Setup:**
```bash
# Clone the repository
git clone <your-repo-url>
cd ClaudeCodeContainer

# Run setup (when implementation is complete)
./scripts/setup.sh
```

## 🔧 Development

This project follows [Conventional Commits](docs/GIT_COMMIT_STYLE.md) style for commit messages.

See [CLAUDE_NEXT_STEPS.md](CLAUDE_NEXT_STEPS.md) for implementation roadmap and next steps.

## 📚 Documentation

- [Getting Started Guide](docs/GETTING_STARTED.md)
- [Security Overview](docs/SECURITY.md)
- [Git Commit Style Guide](docs/GIT_COMMIT_STYLE.md)

## 🛠️ Technical Details

Built with:
- **Swift** - Container implementation using Apple's Virtualization framework
- **Bash** - Setup and management scripts
- **Apple Container Framework** - [GitHub Repository](https://github.com/apple/container)

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- [Claude Code](https://claude.ai) by Anthropic
- [Apple Container Framework](https://github.com/apple/container)
- Initial architecture designed with Claude 4.1 Opus

---

**Note**: This project is in early development. Contributions and feedback welcome!
