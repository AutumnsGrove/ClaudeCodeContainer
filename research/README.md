# Research Directory

This directory contains research documentation for the Apple container framework.

## Purpose

Before implementing the container solution, comprehensive research must be conducted to understand Apple's container framework and create actionable documentation for development.

## How to Use

### Step 1: Run Research Session

Use **RESEARCH_PROMPT.md** with Claude in research mode:

1. Open a new Claude conversation (NOT Claude Code)
2. Paste or reference the RESEARCH_PROMPT.md content
3. Let Claude deploy subagents and conduct parallel research
4. Claude will create comprehensive documentation in this directory

### Step 2: Review Research Output

After research is complete, this directory should contain:

- ✅ `FRAMEWORK_OVERVIEW.md` - High-level understanding
- ✅ `API_REFERENCE.md` - Complete API documentation
- ✅ `IMPLEMENTATION_GUIDE.md` - Step-by-step implementation guide
- ✅ `EXAMPLES/` - Working code samples
- ✅ `ARCHITECTURE_DECISION.md` - Recommended approach
- ✅ `TROUBLESHOOTING.md` - Common issues and solutions

### Step 3: Begin Implementation

Once research is complete, start Claude Code in planning mode and use the documentation to begin implementation.

## Directory Structure

```
research/
├── README.md                    # This file
├── RESEARCH_PROMPT.md           # Metaprompt for research phase
│
├── FRAMEWORK_OVERVIEW.md        # [TO BE CREATED BY RESEARCH]
├── API_REFERENCE.md             # [TO BE CREATED BY RESEARCH]
├── IMPLEMENTATION_GUIDE.md      # [TO BE CREATED BY RESEARCH]
├── ARCHITECTURE_DECISION.md     # [TO BE CREATED BY RESEARCH]
├── TROUBLESHOOTING.md           # [TO BE CREATED BY RESEARCH]
│
└── EXAMPLES/                    # [TO BE CREATED BY RESEARCH]
    ├── minimal-container.swift
    ├── container-with-workspace.swift
    ├── container-with-network.swift
    └── full-example.swift
```

## Current Status

📋 **Status:** Research not yet conducted

**Next Action:** Run RESEARCH_PROMPT.md with Claude in research mode

## Notes

- Research documentation should be comprehensive enough that implementation can begin without further research
- All code examples should be tested and working
- If Apple's container framework is not viable, research should document alternative approaches
