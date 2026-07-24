<!-- BEGIN MANAGED: automatic-skill-routing -->
For every non-trivial task, inspect available skills automatically.
The user must not need to name skills manually.
Select the smallest compatible set; start with no more than four.
Prefer process skill, then domain skill, then verification skill.
Do not activate duplicate skills from the same family.
Use documentation-lookup for version-dependent libraries, APIs, and frameworks.
Use database-migrations for schema changes, backfills, indexes, and rollback planning.
Use deployment-patterns for CI/CD, release, Docker, health checks, and deployment design.
Use mcp-server-patterns only for MCP servers, tools, resources, transports, or MCP Apps.
Use deep-research only for current multi-source research when required MCP tools are available.
Invoke routine skills silently.
Use ponytail automatically when implementing a feature, refactor, or bugfix that risks over-engineering.
Apply ponytail in lite mode as a method: understand the flow first, then pick the simplest solution that is actually correct.
Do not use ponytail for research-only work, source gathering, documentation analysis, planning that writes no code, or administrative tasks.
Ponytail never relaxes security, validation, accessibility, error handling, tests, reliability, or explicit user requirements.
Use ponytail-review only after a large diff, not after every small edit.
Use ponytail-audit only on explicit request or for a full repository audit.
Do not run ponytail together with code-simplifier or any other duplicate simplification tool in the same pass.
Never deploy, push, merge, publish, delete data, destroy infrastructure, or run production migrations without explicit user approval.

### Obsidian routing

Obsidian Skills are installed globally, but are not used automatically in plain Markdown.

Use obsidian-markdown only when at least one of the following holds:
- An .obsidian folder exists at the project root or a parent folder.
- The user explicitly mentions Obsidian, Vault, Wikilink, Embed, or Callout.
- The target file is known to be a Note inside an Obsidian Vault.
- The user requests Obsidian properties/frontmatter or Obsidian-specific syntax.

Use obsidian-bases only when:
- Creating or editing a .base file.
- Or Obsidian Bases is explicitly requested.

Use json-canvas only when:
- Creating or editing a .canvas file.
- Or JSON Canvas is explicitly requested.

Do not use Obsidian syntax inside:
- README.md
- CHANGELOG.md
- API docs
- Plain Markdown files for coding projects
- GitHub Issues or Pull Requests
unless the user explicitly asks for it.

Do not convert plain links into [[wikilinks]] outside a Vault.
Do not add Obsidian properties or callouts to regular project files.
Do not use obsidian-cli in Claude Cloud.
Do not use defuddle; use Exa or Firecrawl for web extraction.
<!-- END MANAGED: automatic-skill-routing -->
