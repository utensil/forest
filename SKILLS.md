# Recommended Skills for Agents

Essential skills organized by category for efficient task completion.

## Core Installation Commands

```bash
# Install with global and universal flags
bunx openskills install --global --universal <skill-name>
```

## Essential Skills by Category

### 📄 Document Processing
- **docx/pdf/pptx/xlsx**: Word/Excel/PDF operations
- **technical-writing**: PRD/RFC/technical documentation
- **obsidian-vault**: Obsidian vault management

### 🍎 macOS Exclusive
- **apple-calendar**: Natural language macOS calendar operations

### 🎨 UI/UX Design
- **ui-ux-pro-max-skill**: Full UI/UX design workflow

### 🔧 Development & Debugging
- **test-driven-development**: TDD workflow guidance
- **explain-code**: Code visualization and analysis
- **code-refactor**: Code refactoring with SOLID principles

### 📋 Project Management
- **planning-with-files**: Long task persistence management
- **file-organizer**: Automated file organization

### 🤖 Automation & Efficiency
- **agent-browser**: Web automation and interaction
- **github-tools**: GitHub natural language operations

### 📊 Data Processing
- **polars-data-analysis**: High-performance data processing
- **data-visualization**: Automated chart generation

### 🔍 Skill Management
- **find-skills**: Skill discovery and recommendation
- **skill-creator**: Interactive skill creation

## Quick Install Commands

```bash
# Core essentials
bunx openskills install --global --universal anthropics/skills openclaw/skills/obsidian-vault openclaw/skills/apple-calendar nextlevelbuilder/ui-ux-pro-max-skill OthmanAdi/planning-with-files clawdhub/file-organizer vercel-labs/skills@find-skills

# Additional as needed
bunx openskills install --global --universal clawdhub/agent-browser clawdhub/github-tools polars-data-analysis data-visualization code-refactor
```

## Skill Usage Instructions

### How to Use Skills
- **Read skill content**: `bunx openskills read <skill-name>`
- **Multiple skills**: `bunx openskills read skill-one,skill-two`
- Skill content loads with detailed instructions for task completion
- Base directory provided for resolving bundled resources (references/, scripts/, assets/)

### Usage Notes
- Only use skills listed in available skills
- Do not invoke a skill that is already loaded in your context
- Each skill invocation is stateless

## Usage Guidelines
1. Always check SKILLS.md first when starting a task
2. Use `bunx openskills` with `--global --universal` flags
3. Install only skills needed for current task
4. Refer to skill documentation for specific capabilities