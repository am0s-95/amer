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

### MCP development routing

- استخدم build-mcp-server تلقائيًا عندما يطلب المستخدم:
  - بناء MCP server
  - تحويل API أو خدمة إلى MCP
  - تصميم أدوات MCP
  - اختيار remote HTTP أو local stdio أو MCPB
  - بناء تكامل جديد عبر Model Context Protocol

- build-mcp-server هو نقطة الدخول الأساسية.

- استخدم build-mcp-app فقط عندما يحتاج MCP:
  - واجهات تفاعلية داخل المحادثة
  - widgets
  - forms
  - pickers
  - visual previews
  - rich interactive UI

- استخدم build-mcpb فقط عندما يجب أن يعمل الخادم على جهاز المستخدم أو يصل
  إلى ملفات محلية أو تطبيق سطح مكتب أو APIs نظام التشغيل.

- استخدم mcp-server-patterns كمرجع معماري داعم، وليس Workflow كاملًا موازيًا.
- لا تشغّل build-mcp-server وmcp-server-patterns كمسارين كاملين مكررين.
- لا تستخدم مهارات البناء لمجرد استخدام MCP موجود أو استدعاء أداة MCP.
- لا تبدأ scaffolding قبل تحديد:
  - ما الذي يتصل به MCP
  - من سيستخدمه
  - عدد الإجراءات
  - نموذج النشر
  - المصادقة
  - الحاجة إلى واجهة تفاعلية

- لا تسمح لهذه المهارات بتنفيذ deploy أو publish أو إنشاء secrets أو تغيير
  خدمة خارجية دون موافقة صريحة.

### Session report routing

- استخدم session-report فقط عندما يطلب المستخدم:
  - تقرير استهلاك Claude Code
  - تحليل tokens أو cache
  - تحليل subagents أو skills
  - أكثر البرومبتات تكلفة
  - مقارنة الاستخدام بين المشاريع
- لا تشغّله تلقائيًا في SessionStart أو Stop.
- لا تشغّله بعد كل مهمة.
- الوضع الافتراضي يخفي نصوص prompts.
- لا تستخدم --include-prompts دون موافقة صريحة.
- اشرح أن التقرير يحلل transcripts المتاحة في HOME الحالي فقط،
  وليس كل تاريخ حساب Claude عبر الأجهزة أو البيئات.
- لا تنشر أو ترفع التقرير تلقائيًا.
<!-- END MANAGED: automatic-skill-routing -->
