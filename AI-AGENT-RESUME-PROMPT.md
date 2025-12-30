# 🤖 AI Agent Resume Prompt for UPSC PrepX-AI

**Purpose:** Copy-paste this prompt to any AI agent to instantly resume this project without confusion

---

## THE PROMPT (Copy Everything Below This Line)

```
I need you to help me continue developing my UPSC PrepX-AI platform. This is a partially-built enterprise application following the BMAD (Business, Management, Architecture, Development) methodology.

**CRITICAL INSTRUCTIONS - READ THESE FIRST:**

1. **Read these files IN ORDER before doing anything:**
   - E:\BMAD method\BMAD 4\PROJECT-STATE-COMPLETE.md (MUST READ FIRST - complete context)
   - E:\BMAD method\BMAD 4\CLAUDE.md (project-specific guidance)
   - E:\BMAD method\BMAD 4\.bmad-core\user-guide.md (BMAD methodology)
   - E:\BMAD method\BMAD 4\UPSC COMPLETE ENTERPRISE BUILD SPECIFICATION v4.md (product spec)

2. **Follow BMAD methodology strictly:**
   - Use BMAD agents (.bmad-core/agents/) for all work
   - Commands require * prefix (e.g., *help, *create-next-story)
   - Load resources lazily (only when executing specific commands)
   - Do NOT scan filesystem or pre-load files during agent activation

3. **Understand project structure:**
   - Monorepo with Turborepo + pnpm workspaces
   - apps/web/ = Next.js 14 user app (partially built)
   - packages/ = shared packages (queue-worker, supabase, etc.)
   - docs/stories/ = 122 user stories (6-7 complete, 115 pending)
   - VPS deployed at 89.117.60.144 with 11 services running

4. **Current state:**
   - ✅ MVP COMPLETE: Users can signup, submit doubts, get AI video explanations
   - ✅ Infrastructure: All VPS services operational
   - ✅ Database: 8 core tables + 10 advanced tables deployed
   - ✅ Authentication: Email/password + Google OAuth working
   - ✅ Queue system: Docker worker processing video jobs
   - ⚠️ Frontend: 15+ routes exist but most are empty
   - ⚠️ Payments: RevenueCat/Razorpay NOT integrated yet
   - ⚠️ Tests: Minimal coverage (1-5%)

5. **What I need you to do:**

[CHOOSE ONE - User will specify which option they want]

Option A: **Use BMAD SM Agent to suggest next story**
- Activate SM agent: Read .bmad-core/agents/sm.md
- Run *create-next-story
- SM will analyze priorities and suggest next implementation
- Get my approval before starting

Option B: **Implement a specific story I choose**
- I'll tell you which story (e.g., "Story 5.1 - RevenueCat Integration")
- Activate Dev agent: Read .bmad-core/agents/dev.md
- Run *develop-story <story-file>
- Follow BMAD development workflow

Option C: **Fix critical issues first**
- Add missing @tanstack/react-query dependency to apps/web
- Deploy web app to VPS production
- Setup automated database backups
- Enable firewall on VPS

Option D: **Create comprehensive test suite**
- Activate QA agent: Read .bmad-core/agents/qa.md
- Run *risk-profile for existing stories
- Add Jest unit tests
- Add Playwright E2E tests

**IMPORTANT RULES:**

❌ DO NOT:
- Pre-load files during agent activation
- Scan filesystem automatically
- Load .bmad-core/data/bmad-kb.md unless *kb-mode is used
- Skip reading PROJECT-STATE-COMPLETE.md (you MUST read it first)
- Make changes to .bmad-core/ directory
- Commit code without running validations
- Deviate from BMAD methodology

✅ DO:
- Read PROJECT-STATE-COMPLETE.md before anything else
- Use BMAD agents for all work
- Follow numbered list patterns for user choices
- Load resources lazily (only when needed)
- Mark tasks complete ONLY when all validations pass
- Ask for clarification if requirements unclear
- Update story Dev Agent Record section with changes

**What option would you like me to pursue? (A, B, C, or D)**

If Option B, please specify which story you want implemented.
```

---

## USAGE INSTRUCTIONS

### For the User (Project Owner)

1. **Copy the entire prompt** from "THE PROMPT" section above
2. **Paste it to a fresh AI agent** (Claude, GPT-4, etc.)
3. **Specify which option** you want (A, B, C, or D)
4. **Let the agent read** PROJECT-STATE-COMPLETE.md first
5. **Follow BMAD workflow** - agent will guide you

### What Happens Next

**If you choose Option A (BMAD SM Agent):**
- Agent reads sm.md agent file
- Agent analyzes docs/stories/ directory
- Agent suggests highest-priority unimplemented story
- You approve or ask for alternatives
- Agent hands off to Dev agent for implementation

**If you choose Option B (Specific Story):**
- Agent reads dev.md agent file
- Agent reads the story file you specified
- Agent implements following BMAD workflow:
  1. Read story acceptance criteria
  2. Implement each task sequentially
  3. Write tests
  4. Run validations
  5. Mark complete when passing
  6. Update story Dev Agent Record section

**If you choose Option C (Critical Fixes):**
- Agent fixes technical debt issues
- Adds missing dependencies
- Deploys web app
- Sets up backups
- Configures firewall

**If you choose Option D (Testing):**
- Agent activates QA agent (Quinn)
- Agent runs risk assessment
- Agent writes comprehensive test suite
- Agent adds Jest + Playwright tests

### Example Conversation

```
You: [Paste prompt]
     I want Option B. Please implement Story 5.1 - RevenueCat Integration.

Agent: I'll start by reading PROJECT-STATE-COMPLETE.md to understand the current state...
       [Agent reads file]

       Now reading .bmad-core/agents/dev.md to activate Dev agent...
       [Agent activates]

       Reading docs/stories/5.1.revenuecat-integration-setup-configuration.md...
       [Agent reads story]

       I'll implement this story following BMAD workflow:
       1. Install RevenueCat SDK
       2. Configure API keys
       3. Create entitlement sync functions
       4. Test subscription flow

       Starting Task 1: Install RevenueCat SDK...
       [Agent executes]
```

---

## QUICK REFERENCE FOR AI AGENTS

### Must-Read Files (In Order)
1. `PROJECT-STATE-COMPLETE.md` ← START HERE
2. `CLAUDE.md` ← Project guidance
3. `.bmad-core/user-guide.md` ← BMAD methodology
4. `UPSC COMPLETE ENTERPRISE BUILD SPECIFICATION v4.md` ← Product spec

### Key BMAD Agents
- **sm.md** - Scrum Master (creates next story)
- **dev.md** - Developer (implements stories)
- **qa.md** - Test Architect (reviews quality)
- **architect.md** - System Architect (designs solutions)
- **pm.md** - Product Manager (creates PRDs)

### Command Patterns
All commands require `*` prefix:
- `*help` - Show available commands
- `*agent <name>` - Transform orchestrator
- `*create-next-story` - SM: Generate next story
- `*develop-story <file>` - Dev: Implement story
- `*review-story <file>` - QA: Review code
- `*exit` - Exit agent persona

### Story Locations
- All stories: `docs/stories/`
- Format: `<epic>.<number>-<name>.md`
- Example: `5.1.revenuecat-integration-setup-configuration.md`

### Critical Constraints
- ⚠️ Load resources lazily (only when executing commands)
- ⚠️ Never pre-load during agent activation
- ⚠️ Never modify .bmad-core/ files
- ⚠️ Follow exact BMAD workflow patterns
- ⚠️ Mark tasks complete only when validated

---

## TROUBLESHOOTING

### If Agent Gets Confused

**Problem:** Agent asks "What project is this?"
**Solution:** Agent didn't read PROJECT-STATE-COMPLETE.md. Say:
```
Please read E:\BMAD method\BMAD 4\PROJECT-STATE-COMPLETE.md first.
This file contains complete project context.
```

**Problem:** Agent scans filesystem or pre-loads files
**Solution:** Remind agent of BMAD lazy loading:
```
Stop. BMAD agents load resources lazily.
Only load files when executing specific commands.
Read .bmad-core/user-guide.md for correct pattern.
```

**Problem:** Agent says "I don't see any stories"
**Solution:** Point to correct location:
```
Stories are in docs/stories/ directory.
There are 122 story files (6-7 complete, 115 pending).
List files with: ls docs/stories/
```

**Problem:** Agent modifies .bmad-core/ files
**Solution:** Stop immediately:
```
STOP! Never modify .bmad-core/ directory.
This contains BMAD methodology files.
Only modify application code (apps/, packages/).
```

### If Agent Implements Wrong Thing

**Problem:** Agent builds feature not in stories
**Solution:** Redirect to BMAD process:
```
We follow BMAD methodology strictly.
All features must have corresponding stories in docs/stories/.
If story doesn't exist, use SM agent to create it first.
```

**Problem:** Agent skips tests
**Solution:** Enforce test-first approach:
```
BMAD requires tests for all implementations.
Add tests before marking tasks complete.
See .bmad-core/checklists/story-dod-checklist.md
```

---

## EXPECTED OUTCOMES

### After Option A (BMAD SM Agent)
- ✅ Next story identified and prioritized
- ✅ Story file created/updated in docs/stories/
- ✅ Acceptance criteria clear
- ✅ Ready to hand off to Dev agent

### After Option B (Implement Story)
- ✅ All story tasks implemented
- ✅ Tests written and passing
- ✅ Code committed to git
- ✅ Story marked "Ready for Review"
- ✅ Dev Agent Record section updated

### After Option C (Critical Fixes)
- ✅ Dependencies installed
- ✅ Web app deployed to VPS
- ✅ Automated backups configured
- ✅ Firewall enabled
- ✅ Technical debt reduced

### After Option D (Testing)
- ✅ Risk assessment completed
- ✅ Test strategy documented
- ✅ Jest unit tests added (60%+ coverage)
- ✅ Playwright E2E tests added
- ✅ CI pipeline configured

---

**Status:** AI AGENT RESUME PROMPT READY ✅
**Last Updated:** December 26, 2025

**Copy the prompt above whenever you need to resume this project with a fresh AI agent!** 🚀
