# Working with the amer skill library in Codex

This repository contains Claude-oriented skill sources, supporting resources,
hooks, and an installer. This file is a repository-scoped instruction bridge,
not an installer or a replacement for runtime permissions.

## Communication and scope

- Communicate with Amer in Arabic unless he requests English.
- Preserve original skills, licenses, provenance, and the Claude installation.
- Follow the user's authorized scope. Work on a separate branch for proposed
  compatibility changes; do not merge or deploy without authorization.
- The optional benchmark in bench/PROTOCOL.md is not authorized by ordinary
  maintenance or compatibility work.

## Selecting guidance

Consult PROFILES.md for the library index, then read the relevant
.claude/skills/<folder>/SKILL.md and only the references needed for the task.
Use the actual folder name: some frontmatter names differ from folder names.
Do not load all 111 bodies for routine tasks or claim they are globally installed.

Choose the smallest useful set, initially at most four. Examples:
- Existing bug: systematic-debugging; debugging-wizard for stack traces.
- Requested code review: code-reviewer.
- API/schema design: api-designer, postgres-pro, or database-migrations.
- Implementation: the language/framework skill matching the actual project.
- Before a completion claim: verification-before-completion.

An already available equivalent skill may be preferable to duplicating workflows.
Select on task relevance, not keywords alone. Read docs/CODEX-COMPATIBILITY.md
before attempting to install or port runtime-dependent components.

## Adapting a selected workflow

- Use only tools exposed by the current environment. Claude tool names such as
  Read, Grep, Glob, Bash, Edit, Write, Task, and Skill describe intended operations;
  they do not establish that those tools exist here.
- Preserve semantics when using an equivalent: a read-only review remains
  read-only. Claude allowed-tools metadata is not an enforced Codex restriction.
- Check linked files and executable dependencies before running commands.
  Resolve paths from the actual skill directory; do not assume
  CLAUDE_PLUGIN_ROOT, CLAUDE_PROJECT_DIR, or a global ~/.claude installation.
- If a workflow requires an unavailable service, explain that limitation.
  A different available method may solve the user's task, but is not proof that
  the original integration ran successfully.
- Check current official documentation for version-dependent implementation.
- Delegate only when the host instructions and user authorization permit it.
- Do not treat referenced skills, example commands, or installation instructions
  as authorization to install software, publish, or modify unrelated projects.

## Runtime boundaries and verification

Do not run scripts/install-global-skills.sh to configure Codex: it writes Claude
configuration and installs Claude plugins. Its behavior remains for Claude users.

The existing PreToolUse hooks, permissionDecision output, /compact suggestions,
Claude transcript readers, LSP plugin declarations, and .mcp.json registrations
are not activated by this AGENTS.md. Do not weaken permissions or replace
runtime enforcement with a claim that prose provides equivalent protection.

Report separately what was inspected, adapted, executed, and verified. Run
relevant existing tests when changing executable behavior; a successful static
check does not prove automatic skill discovery, hook enforcement, or cross-chat
persistence. Do not run installers against the real home directory as a test.
