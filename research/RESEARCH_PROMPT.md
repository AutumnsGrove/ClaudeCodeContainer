# Apple Container Framework Research Metaprompt

> **For Claude in Research Mode**
>
> This prompt guides comprehensive research of Apple's container framework to create actionable documentation for development.

---

## 🎯 Mission

Research and document Apple's container framework (https://github.com/apple/container) to create comprehensive, actionable reference materials that enable immediate development of a native macOS container solution for Claude Code.

## 📋 Your Task

You are Claude in **research mode**. Your goal is to deeply understand Apple's container framework and create documentation that will allow Claude Code (in a future session) to implement a secure containerized environment **without** needing to do additional research.

## 🔬 Research Strategy

### Use Multiple Subagents in Parallel

Deploy specialized subagents to research different aspects simultaneously:

1. **Repository Analysis Subagent**
   - Clone and examine https://github.com/apple/container
   - Analyze directory structure and code organization
   - Identify key source files and their purposes
   - Map out the architecture and components
   - Document build process and dependencies

2. **API Documentation Subagent**
   - Extract all public APIs and interfaces
   - Document function signatures, parameters, return types
   - Identify Swift/Objective-C interop requirements
   - Map API usage patterns and common workflows
   - Document configuration options and defaults

3. **Examples & Usage Patterns Subagent**
   - Find example code in the repository
   - Search for tests that demonstrate usage
   - Look for documentation or README files
   - Identify common patterns and best practices
   - Extract minimal working examples

4. **Integration Research Subagent**
   - Research how this relates to Apple's Virtualization.framework
   - Investigate macOS version requirements
   - Document required entitlements and permissions
   - Research file system sharing mechanisms (VirtioFS, etc.)
   - Investigate network configuration options

5. **Alternative Approaches Subagent**
   - If the container framework is incomplete/unstable, research fallback options
   - Investigate using Virtualization.framework directly
   - Research other native macOS container solutions
   - Document pros/cons of each approach

## 📊 Expected Deliverables

Create the following documentation in the `research/` directory:

### 1. `FRAMEWORK_OVERVIEW.md`
**Purpose:** High-level understanding of what the framework is and how it works

**Contents:**
- What is Apple's container framework?
- How does it differ from Docker/containerd?
- Relationship to Virtualization.framework
- System requirements (macOS version, architecture)
- Current maturity level and stability assessment
- Recommended use cases

### 2. `API_REFERENCE.md`
**Purpose:** Complete API documentation for implementation

**Contents:**
- All public classes and protocols
- Key functions with full signatures
- Configuration structures and options
- Error types and handling
- Code examples for each major API
- Swift vs. Objective-C usage notes

### 3. `IMPLEMENTATION_GUIDE.md`
**Purpose:** Step-by-step guide to implementing containers

**Contents:**
- Prerequisites and setup
- Container lifecycle (create → start → stop → destroy)
- Workspace mounting and file sharing
- Network configuration for internet access
- Resource limits (CPU, memory, storage)
- Security configuration
- Logging and debugging
- Complete minimal working example

### 4. `EXAMPLES/`
**Purpose:** Working code samples

**Contents:**
- `minimal-container.swift` - Simplest possible container
- `container-with-workspace.swift` - Container with mounted directories
- `container-with-network.swift` - Container with network access
- `full-example.swift` - Complete implementation with all features
- Each example should be self-contained and runnable

### 5. `ARCHITECTURE_DECISION.md`
**Purpose:** Recommendation on best approach

**Contents:**
- Assessment of Apple container framework viability
- If viable: implementation roadmap
- If not viable: recommended alternative approach
- Trade-offs and considerations
- Risk assessment and mitigation strategies

### 6. `TROUBLESHOOTING.md`
**Purpose:** Common issues and solutions

**Contents:**
- Known limitations of the framework
- Common error messages and fixes
- Debugging techniques
- Performance considerations
- Platform-specific gotchas

## 🔍 Research Methodology

### Phase 1: Reconnaissance (Parallel)
- **All subagents start simultaneously**
- Each focuses on their specialized area
- Time limit: Comprehensive but efficient
- Goal: Broad understanding of the framework

### Phase 2: Deep Dive (Sequential)
- **Consolidate findings from Phase 1**
- Identify gaps in knowledge
- Deploy targeted research to fill gaps
- Goal: Complete technical understanding

### Phase 3: Synthesis (Single Focus)
- **Create comprehensive documentation**
- Write all deliverable documents
- Ensure consistency across documents
- Validate with working examples
- Goal: Production-ready documentation

### Phase 4: Validation (Final Check)
- **Review all documentation**
- Ensure Claude Code can implement without further research
- Check for completeness and clarity
- Add any missing pieces
- Goal: Ready-to-implement documentation set

## ✅ Success Criteria

Your research is complete when:

1. ✅ All deliverable documents are created
2. ✅ At least one working code example exists
3. ✅ Implementation path is clear and actionable
4. ✅ Alternative approach documented if primary approach not viable
5. ✅ Claude Code could start implementation immediately after reading docs
6. ✅ No additional research would be needed during implementation

## 🎯 Key Questions to Answer

### Technical Questions:
- What are the exact Swift/Objective-C APIs for creating containers?
- How do you mount host directories into containers?
- How do you configure network access?
- How do you set resource limits?
- What's the container image format?
- How do you execute commands in containers?
- How do you attach to a running container?

### Practical Questions:
- What's the minimum macOS version required?
- What entitlements/permissions are needed?
- Can this run without sudo/root?
- What's the performance compared to Docker?
- Is the framework stable enough for production use?
- Are there any major bugs or limitations?

### Decision Questions:
- Should we use this framework or fall back to Virtualization.framework?
- What's the learning curve?
- What are the risks?
- What's the maintenance burden?

## 💡 Research Tips

1. **Start with the Repository**
   - README and docs are gold
   - Tests show real usage
   - Look for example directories

2. **Check Git History**
   - Recent commits show active development
   - Issue tracker shows problems and solutions
   - PRs show how contributors use the framework

3. **Look for Related Projects**
   - Search GitHub for projects using the framework
   - Check Apple Developer forums
   - Look for blog posts or articles

4. **Be Pragmatic**
   - If the framework is too immature, say so
   - Recommend alternatives if needed
   - Don't force a solution that won't work

5. **Think Like a Developer**
   - What would you need to know to implement this?
   - What examples would be most helpful?
   - What pitfalls should be avoided?

## 📝 Documentation Style

- **Be concise but complete** - No fluff, all substance
- **Code over prose** - Show, don't just tell
- **Practical examples** - Real code that works
- **Clear structure** - Easy to navigate and reference
- **Actionable** - Every doc should enable immediate action

## 🚀 Getting Started

1. **Read this entire prompt carefully**
2. **Deploy your subagents** (use Task tool with multiple agents in parallel)
3. **Coordinate findings** as subagents complete
4. **Synthesize documentation** based on all research
5. **Validate with examples** - ensure everything works
6. **Create final deliverables** in `research/` directory

## ⚠️ Important Notes

- **This is research, not implementation** - Don't write production code yet
- **Focus on Apple's framework** - Not Docker, not other solutions (unless fallback needed)
- **Be thorough** - Future Claude Code session depends on this
- **Be honest** - If framework won't work, say so and recommend alternatives
- **Create examples** - Working code is worth 1000 words

## 🎬 Final Output

When complete, the `research/` directory should contain everything needed to:
1. Understand the Apple container framework
2. Implement a container solution
3. Troubleshoot issues
4. Make architectural decisions

Future Claude Code session should be able to read these docs and start coding immediately without any additional research.

---

**Ready? Start your research! Deploy those subagents and dive deep into Apple's container framework. The future of this project depends on the quality of your research.**

Good hunting! 🔍
