# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is BMAD?

This is the **BMAD (Business, Management, Architecture, Development) Method v4.44.3** - a comprehensive AI-driven software development methodology. BMAD provides structured workflows, specialized agents, and templates for planning and executing software projects using AI assistance.

## Core Architecture

### Directory Structure

```
.bmad-core/
├── agents/           # Specialized AI agent personas (PM, Architect, Dev, QA, etc.)
├── agent-teams/      # Pre-configured agent combinations for different project types
├── tasks/            # Executable workflow tasks (create-doc, shard-doc, etc.)
├── templates/        # Document templates (PRD, Architecture, Story, etc.)
├── workflows/        # Project workflows (greenfield/brownfield, fullstack/service/UI)
├── checklists/       # Quality gates and validation checklists
├── data/             # Reference data (technical preferences, test frameworks, KB)
├── utils/            # Utility scripts and helpers
└── core-config.yaml  # Critical project configuration
```

### Configuration: core-config.yaml

This is the **most critical file** - it configures how BMAD operates in your project:

```yaml
markdownExploder: true              # Enables document sharding
prd:
  prdFile: docs/prd.md
  prdVersion: v4
  prdSharded: true                  # PRD is split into epics/stories
  prdShardedLocation: docs/prd
architecture:
  architectureFile: docs/architecture.md
  architectureSharded: true
  architectureShardedLocation: docs/architecture
devLoadAlwaysFiles:                 # Files Dev agent MUST load on activation
  - docs/architecture/coding-standards.md
  - docs/architecture/tech-stack.md
  - docs/architecture/source-tree.md
devStoryLocation: docs/stories      # Where user stories are stored
```

**Key concept**: `devLoadAlwaysFiles` contains the minimal context files that define coding standards for your project. Keep these lean and focused.

## Agent System

BMAD uses specialized AI agents, each with distinct responsibilities:

### Core Agents

- **bmad-orchestrator** (`agents/bmad-orchestrator.md`): Master coordinator that transforms into other agents
- **pm** (`agents/pm.md`): Product Manager - creates PRDs, manages requirements
- **architect** (`agents/architect.md`): System architect - designs technical architecture
- **dev** (`agents/dev.md`): Developer - implements stories, writes code
- **qa** (`agents/qa.md`): Test Architect ("Quinn") - quality assurance, test strategy
- **po** (`agents/po.md`): Product Owner - validates alignment, shards documents
- **sm** (`agents/sm.md`): Scrum Master - creates stories from epics
- **analyst** (`agents/analyst.md`): Business analyst - market research, requirements
- **ux-expert** (`agents/ux-expert.md`): UX/UI specialist

### Agent Activation Pattern

Each agent file is self-contained with YAML configuration:

```yaml
activation-instructions:
  - Read entire agent file
  - Adopt persona from 'agent' and 'persona' sections
  - Load .bmad-core/core-config.yaml
  - Greet user and auto-run *help
  - ONLY load dependency files when executing specific commands
```

**Critical rules**:
- Agents load resources **lazily** (only when needed)
- Never pre-load dependencies during activation
- Commands require `*` prefix (e.g., `*help`, `*create-prd`)
- Each agent has specific `dependencies` (tasks/templates/checklists they can use)

## Workflow Patterns

### Greenfield vs Brownfield

- **Greenfield**: New projects from scratch
  - `workflows/greenfield-fullstack.yaml`
  - `workflows/greenfield-service.yaml`
  - `workflows/greenfield-ui.yaml`

- **Brownfield**: Existing codebases
  - `workflows/brownfield-fullstack.yaml`
  - `workflows/brownfield-service.yaml`
  - `workflows/brownfield-ui.yaml`
  - Special tasks: `brownfield-create-epic.md`, `brownfield-create-story.md`

### Standard Development Flow

1. **Planning Phase** (Web UI or IDE):
   - Analyst: Research, brainstorming (optional)
   - PM: Create PRD → `tasks/create-doc.md` + `templates/prd-tmpl.yaml`
   - Architect: Create architecture → `templates/fullstack-architecture-tmpl.yaml`
   - PO: Validate alignment → `checklists/po-master-checklist.md`
   - PO: Shard documents → `tasks/shard-doc.md`

2. **Development Cycle** (IDE):
   - SM: Draft next story → `tasks/create-next-story.md`
   - QA (optional): Risk assessment → `tasks/risk-profile.md`, `tasks/test-design.md`
   - PO (optional): Validate story → `tasks/validate-next-story.md`
   - Dev: Implement story → Follow `dev.md` agent's `*develop-story` command
   - QA (optional): Mid-dev checks → `tasks/trace-requirements.md`, `tasks/nfr-assess.md`
   - QA: Review → `tasks/review-story.md`
   - QA: Quality gate → `tasks/qa-gate.md`

3. **Commit & Continue**

## Key Tasks

### Document Creation (`tasks/create-doc.md`)
Creates documents from templates. Used by PM/Architect/Analyst for PRDs, Architecture, etc.

### Document Sharding (`tasks/shard-doc.md`)
Splits large PRD/Architecture documents into epics and stories in `docs/epics/`, `docs/stories/`, `docs/architecture/`.

### Story Creation (`tasks/create-next-story.md`)
SM agent creates next implementable story from sharded epic + architecture.

### Story Execution (`dev.md` agent's `*develop-story`)
Developer's core workflow:
1. Read task → Implement → Write tests → Run validations
2. Mark task checkbox `[x]` only when ALL validations pass
3. Update story's File List, Change Log, Debug Log
4. Repeat for all tasks
5. Run `story-dod-checklist.md` checklist
6. Set status to "Ready for Review"

**Critical rule**: Dev agent ONLY modifies these story sections:
- Task checkboxes
- Dev Agent Record section (Debug Log, Completion Notes, Change Log)
- File List
- Status

### Test Architect Commands (QA Agent)

**Short forms** (documentation aliases):
- `*risk` → `*risk-profile` (`tasks/risk-profile.md`)
- `*design` → `*test-design` (`tasks/test-design.md`)
- `*trace` → `*trace-requirements` (`tasks/trace-requirements.md`)
- `*nfr` → `*nfr-assess` (`tasks/nfr-assess.md`)
- `*review` → `*review-story` (`tasks/review-story.md`)
- `*gate` → `*qa-gate` (`tasks/qa-gate.md`)

**Usage**:
- Before dev: `*risk`, `*design` (identify risks, plan tests)
- During dev: `*trace`, `*nfr` (verify coverage, check quality)
- After dev: `*review` (comprehensive assessment)
- Post-review: `*gate` (update quality decision)

**Outputs**: All QA tasks generate files in `docs/qa/assessments/` and `docs/qa/gates/`

## Command System

All BMAD commands use `*` prefix:

```bash
*help                    # Show available commands for current agent
*agent <name>            # Transform orchestrator into specialist
*task <name>             # Execute specific task
*create-prd              # PM: Create PRD document
*shard-prd               # PO: Split PRD into epics/stories
*develop-story <story>   # Dev: Implement story
*risk <story>            # QA: Risk assessment
*review <story>          # QA: Comprehensive review
*exit                    # Exit agent persona
```

## Document Sharding Concept

**Problem**: Large documents (100+ pages) overwhelm AI context.

**Solution**: "Markdown Exploder" breaks documents into focused files:
- `docs/prd.md` → `docs/prd/epic-1-auth.md`, `docs/prd/epic-2-payments.md`
- `docs/architecture.md` → `docs/architecture/coding-standards.md`, `docs/architecture/tech-stack.md`
- Stories: `docs/stories/epic-1.story-1-login.md`

Each sharded piece is self-contained but references parent document structure.

## Critical Development Rules

1. **Lazy Loading**: Agents only load files when executing specific commands, never during activation
2. **Context Discipline**: Dev agent reads ONLY story + `devLoadAlwaysFiles`, nothing else unless explicitly told
3. **Story Authority**: Stories contain ALL implementation info; dev doesn't need to read PRD/architecture
4. **Numbered Lists**: Agents always present choices as numbered lists
5. **Lean Documentation**: Keep `devLoadAlwaysFiles` minimal - agent infers patterns from existing code
6. **Sequential Execution**: Dev follows exact order - implement → test → validate → mark complete
7. **Regression Safety**: All validations must pass before marking tasks complete
8. **File Updates**: Dev only updates authorized sections of story files

## Test Architect (QA) Philosophy

Quinn (QA agent) is not just a reviewer - a **Test Architect** with:
- Risk-based testing (probability × impact scoring 1-9)
- Test level guidance (unit/integration/E2E)
- Active refactoring during review
- Quality gates: PASS/CONCERNS/FAIL/WAIVED

**Critical for brownfield**: QA prevents regressions by mapping dependencies and integration points.

## Brownfield-Specific Patterns

When working with existing code:

1. **Document First**: Use `architect` agent's `*document-project` task to create context
2. **PRD-First Approach** (large codebases): Create PRD → Document only affected areas
3. **Document-First Approach** (small codebases): Document everything → Create PRD
4. **Risk Assessment Required**: Always run `*risk` on brownfield stories
5. **Regression Focus**: QA emphasizes backward compatibility and integration safety

## Installation & Setup

BMAD installs via:
```bash
npx bmad-method install
```

Supports multiple IDEs:
- **Cursor/Windsurf**: Uses `@agent` syntax with rules files
- **Claude Code**: Uses `/agent` slash commands
- **OpenCode**: Integration via `opencode.jsonc`
- **Codex**: Integration via `AGENTS.md`
- **Trae**: Current installation uses Trae IDE

## Technical Preferences

Edit `.bmad-core/data/technical-preferences.md` to bias PM/Architect recommendations toward your preferred:
- Design patterns
- Technology choices
- Architectural styles
- Coding conventions

## Common Pitfalls

1. **Don't pre-load resources** during agent activation
2. **Don't scan filesystem** automatically
3. **Don't load KB** (`bmad-kb.md`) unless `*kb-mode` command used
4. **Don't skip user interaction** in tasks marked `elicit=true`
5. **Don't modify unauthorized story sections** (dev agent)
6. **Don't commit changes** to `.bmad-core/` without understanding framework

## Key Files Reference

- **Must read**: `user-guide.md` - Complete BMAD methodology overview
- **Workflows**: `enhanced-ide-development-workflow.md` - Step-by-step dev cycle
- **Brownfield**: `working-in-the-brownfield.md` - Existing codebase guidance
- **Config**: `core-config.yaml` - Project-specific settings
- **KB**: `data/bmad-kb.md` - Full knowledge base (load only with `*kb-mode`)

## Version

Current version: **4.44.3**
Installed: 2025-12-22
IDE: Trae
