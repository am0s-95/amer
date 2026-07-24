# amer

مكتبة سكيلات Claude Code (111 سكيل — انظر `PROFILES.md` للتنظيم و`PROVENANCE.md` لمصادر المستورد منها) مع مثبّت عالمي وحارس للأفعال الخطرة.

## التركيب

```bash
./scripts/install-global-skills.sh            # تركيب/تحديث الروابط + الحارس + بلوك التوجيه
./scripts/install-global-skills.sh --prune    # + حذف الروابط اليتيمة المُدارة فقط
./scripts/install-global-skills.sh --copy     # نسخ بدل الروابط
```

المثبّت idempotent ويقوم بتسعة أشياء:

1. **السكيلات**: symlinks من `.claude/skills/*` إلى `~/.claude/skills/` (111 سكيل).
2. **الحُرّاس**: ينسخ `guard-dangerous.js` و`guard-github-mcp.js` و`suggest-compact.js` (وتبعياته) إلى `~/.claude/hooks/`، ويسجّلها في `~/.claude/settings.json` — `guard-dangerous` خاص بأدوات `Bash` (النشر، push القسري، migrations، الحذف المدمر، موارد Cloud، secrets)، و`guard-github-mcp` خاص بأدوات GitHub MCP (`mcp__github__.*`)، و`suggest-compact` على `Edit` و`Write` (دمج آمن — لا يستبدل الملف).
3. **التوجيه التلقائي**: يزامن البلوك المُدار `automatic-skill-routing` (من `.claude/templates/`) داخل `~/.claude/CLAUDE.md` — يحدّث ما بين العلامتين فقط ولا يمس نص المستخدم.
4. **Global TypeScript LSP plugin**: يثبّت plugin شخصي عالمي (skills-directory plugin بلا `SKILL.md` — لا يُحتسب ضمن الـ111 سكيل) في `~/.claude/skills/typescript-lsp-global`، مع runtime ثابت في `~/.local/share/typescript-lsp` يحتوي نسخًا مثبّتة بدقة: `typescript-language-server@5.3.0` و`typescript@5.7.2`. يعمل عالميًا في كل المشاريع تلقائيًا؛ إن كان للمشروع نسخة TypeScript محلية داخل `node_modules` فهي تُستخدم أولًا، والنسخة العالمية (5.7.2) تعمل كـ fallback فقط. تثبيت dependencies الخاصة بكل مشروع يبقى مسؤولية المشروع نفسه — هذا الـplugin لا يثبّت أو يستبدل شيئًا داخل مشاريعك. `npm install` يُشغَّل فقط عند أول تركيب أو عند تغيّر النسخ المطلوبة، ويمكن تخطيه بمتغيّر البيئة `TS_LSP_SKIP_INSTALL=1`.
5. **Global Pyright LSP plugin**: يثبّت plugin شخصي عالمي (skills-directory plugin بلا `SKILL.md` — لا يُحتسب ضمن الـ111 سكيل) في `~/.claude/skills/pyright-lsp-global`، مع runtime ثابت في `~/.local/share/pyright-lsp` يحتوي نسخة مثبّتة بدقة: `pyright@1.1.411` من npm الرسمي. يعمل عالميًا في كل مشاريع Python تلقائيًا عبر Skill Master، ويحترم إعداد كل مشروع الخاص — `pyrightconfig.json` أو `pyproject.toml` أو بيئته الافتراضية — فلا يوجد `typeCheckingMode` أو `pythonVersion` أو `venvPath` عالمي مفروض. تثبيت dependencies وبيئة `venv` الخاصة بكل مشروع تبقى مسؤولية المشروع نفسه؛ عدم تثبيت مكتبات المشروع قد يُنتج تشخيصات `missing-import`، وهذا لا يعني أن الـLSP معطّل. لا يجوز تثبيت الـPlugin الرسمي `pyright-lsp` (أو أي Marketplace Plugin مكافئ) بالتوازي مع `pyright-lsp-global` تفاديًا للتعارض. `npm install` يُشغَّل فقط عند أول تركيب أو عند تغيّر النسخة المطلوبة، ويمكن تخطيه بمتغيّر البيئة `PYRIGHT_LSP_SKIP_INSTALL=1`. `.lsp.json` يربط `workspaceFolder` بـ`` `${CLAUDE_PROJECT_DIR}` `` حرفيًا في كل جلسة، فيبدأ Pyright دائمًا من جذر المشروع الحالي بدل جذر غير مضمون، مما يمنع خلط المستودعات أو الـworktrees في جلسات Claude Cloud متعددة المشاريع.
6. **Ponytail Curated plugin**: يثبّت عالميًا Marketplace محلي مخصص (`.claude/marketplaces/skill-master-plugins`، اسمه `skill-master-plugins`) يعرض حصرًا الست سكيلات من مشروع [Ponytail](https://github.com/DietrichGebert/ponytail) — `ponytail`، `ponytail-review`، `ponytail-audit`، `ponytail-debt`، `ponytail-gain`، `ponytail-help` — عبر `claude plugin marketplace add` ثم `claude plugin install ponytail-curated@skill-master-plugins --scope user`. مثبَّت على الإصدار `v4.8.4` مثبّتًا على commit SHA ثابت (`bc9ee949d5f439e8b9f3bb92c6d6d3d1e6ebd324`) عبر مصدر `git-subdir` (مجلد `skills/` فقط من مستودع Ponytail). **لا يشمل** أي Hooks (`SessionStart`/`SubagentStart`/`UserPromptSubmit`) ولا `statusLine` ولا agents ولا MCP servers من مشروع Ponytail الأصلي — فقط السكيلات الست كملفات `SKILL.md`. الإصدار الكامل الرسمي لـPonytail (`ponytail@ponytail`) **لا يُثبَّت هنا إطلاقًا**. تُستدعى هذه السكيلات تلقائيًا في مهام البرمجة المناسبة (Feature/Refactor/إصلاح فيه خطر over-engineering) عبر بلوك `automatic-skill-routing` — راجع `PROVENANCE.md` لتفاصيل الاستبعاد وسبب اختيار `git-subdir` بدل التثبيت الرسمي الكامل. يمكن تخطي هذا الجزء بمتغيّر البيئة `PONYTAIL_CURATED_SKIP_INSTALL=1`.
7. **Obsidian Curated plugin**: يثبّت عالميًا في نفس Marketplace المحلي (`skill-master-plugins`) عنصر Plugin ثانٍ يعرض حصرًا ثلاث سكيلات "Open Format" فقط من مشروع [Obsidian Skills](https://github.com/kepano/obsidian-skills) — `obsidian-markdown`، `obsidian-bases`، `json-canvas` — عبر `claude plugin install obsidian-curated@skill-master-plugins --scope user`. مثبَّت على commit SHA ثابت (`a1dc48e68138490d522c04cbf5822214c6eb1202` من فرع `main`) عبر مصدر `git-subdir` (مجلد `skills/` فقط من مستودع Obsidian Skills). **لا يشمل** `obsidian-cli` (يحتاج تطبيق Obsidian فعليًا مفتوحًا، غير متاح افتراضيًا في Claude Cloud) ولا `defuddle` (مكرر وظيفيًا مع Exa وFirecrawl العالميين المثبَّتين مسبقًا) ولا أي Hooks أو agents أو MCP servers من المشروع الأصلي. الإصدار الكامل الرسمي (`obsidian@obsidian-skills`) **لا يُثبَّت هنا إطلاقًا**. هذه السكيلات لا تُستخدم تلقائيًا في Markdown العادي لمشاريع البرمجة — تُفعَّل فقط داخل Obsidian Vault حقيقي (وجود مجلد `.obsidian`) أو عند طلب Obsidian/Vault/Wikilink/Callout/Bases/Canvas صراحة، عبر قواعد `automatic-skill-routing` (قسم "Obsidian routing") — راجع `PROVENANCE.md` لتفاصيل الاستبعاد. يمكن تخطي هذا الجزء بمتغيّر البيئة `OBSIDIAN_CURATED_SKIP_INSTALL=1`.
8. **MCP Server Dev Curated plugin**: يثبّت عالميًا في نفس Marketplace المحلي (`skill-master-plugins`) عنصر Plugin ثالث يعرض حصرًا ثلاث سكيلات رسمية من Anthropic ([anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)، مجلد `plugins/mcp-server-dev`) — `build-mcp-server` (نقطة الدخول لبناء أي MCP server)، `build-mcp-app` (واجهات/widgets تفاعلية داخل MCP)، و`build-mcpb` (تغليف MCP محلي كـ`.mcpb`) — عبر `claude plugin install mcp-server-dev-curated@skill-master-plugins --scope user`. مثبَّت على commit SHA ثابت (`66799ffb4611b7e0c3af391c7569823a4d6b4246` من فرع `main` — لا tag مخصص متاح) عبر مصدر `git-subdir`. **لا يشمل** أي Hooks أو agents أو MCP servers أو LSP servers — فقط السكيلات الثلاث وملفات `references/` المرافقة لها. الإصدار الرسمي غير المنقّح (`mcp-server-dev@claude-plugins-official`) **لا يُثبَّت هنا إطلاقًا**. تُستدعى هذه السكيلات تلقائيًا فقط عند طلب بناء MCP server/app/MCPB جديد، عبر قواعد `automatic-skill-routing` (قسم "MCP development routing") — و`mcp-server-patterns` (السكيل المحلي الموجود مسبقًا) يبقى مرجعًا معماريًا داعمًا فقط، لا Workflow مكررًا. راجع `PROVENANCE.md` لتفاصيل التحقق من المصدر ونتائج اختبار Skill discovery الحقيقي. يمكن تخطي هذا الجزء بمتغيّر البيئة `MCP_SERVER_DEV_CURATED_SKIP_INSTALL=1`.

## GitHub MCP Guard

خادم GitHub MCP (`mcp__github__*`) متصل عالميًا بصورة مستقلة عن هذا المستودع — لا يثبّته هذا المثبّت ولا يضيف أي Plugin أو Connector جديدًا. المثبّت يضيف فقط **حارسًا** فوقه، عالميًا في جميع مشاريع Skill Master، عبر `guard-github-mcp.js` (مسجّل على matcher `mcp__github__.*` في `~/.claude/settings.json`) بالإضافة إلى قواعد `permissions.ask` كدفاع إضافي:

- **عمليات القراءة** (`get_me`، `list_pull_requests`، `search_code`، إلخ): تمر وفق نظام الصلاحيات الطبيعي دون أي prompt إضافي من الحارس.
- **عمليات الكتابة والتغيير** (`merge_pull_request`، `push_files`، `create_pull_request`، `delete_file`، `issue_write`، إلخ): تُعيد `permissionDecision: "ask"` وتتطلب موافقة صريحة من المستخدم قبل التنفيذ.
- **أدوات GitHub غير معروفة** (جديدة أو مستقبلية لا تندرج تحت قائمتي القراءة/التغيير): تُعامل افتراضيًا كأداة تغيير وتطلب `ask` — لا مرور صامت لأي أداة غير مصنّفة.
- **فشل قراءة/تفسير المدخلات**: fail-closed — `deny` إن أمكن التأكد أن الاستدعاء GitHub MCP، وإلا حظر آمن للاستدعاء بالكامل.

`guard-dangerous.js` يبقى خاصًا بأوامر `Bash` الخطرة (نشر، push قسري، migrations، حذف مدمر، موارد Cloud، secrets)، و`guard-github-mcp.js` خاص حصرًا بأدوات GitHub MCP — كل حارس مستقل عن الآخر ولا يتداخلان.

## الاختبارات

```bash
bash tests/test-install-global-skills.sh    # المثبّت: التركيب، --prune، الـidempotency، البلوك المُدار
bash tests/test-guard-dangerous.sh          # الحارس: خطرة مباشرة/مغلّفة، آمنة، fail-safe
bash tests/test-guard-github-mcp.sh         # حارس GitHub MCP: قراءة/تغيير/غير معروف/fail-closed + تركيبه العالمي (payloads صناعية فقط)
bash tests/test-project-skill-routing.sh    # توجيه السكيلات على مستوى المشروع + ميزانية القائمة
bash tests/test-install-typescript-lsp.sh   # Global TypeScript LSP: التركيب، المسارات المطلقة، الـidempotency (npm وهمي — بلا شبكة)
bash tests/test-install-pyright-lsp.sh      # Global Pyright LSP: التركيب، المسارات المطلقة، الـidempotency، نسخة 1.1.411 (npm وهمي — بلا شبكة)
bash tests/test-install-ponytail-curated.sh # Ponytail Curated: صحة marketplace.json (git-subdir/ref/sha/strict/6 سكيلات فقط)، الـidempotency، بلا Hooks/statusLine (claude CLI وهمي — بلا شبكة)
bash tests/test-install-obsidian-curated.sh  # Obsidian Curated: صحة marketplace.json (git-subdir/sha/3 سكيلات فقط، بلا obsidian-cli/defuddle)، الـidempotency، بلا Hooks/statusLine، قواعد Obsidian routing (claude CLI وهمي — بلا شبكة)
bash tests/test-install-mcp-server-dev-curated.sh  # MCP Server Dev Curated: صحة marketplace.json (git-subdir/sha/3 سكيلات فقط: build-mcp-server/build-mcp-app/build-mcpb، بلا hooks/agents/mcpServers/lspServers)، الـidempotency، بقاء Ponytail/Obsidian Curated، قواعد MCP development routing (claude CLI وهمي — بلا شبكة)
```

## السحابة مقابل التثبيت العالمي

- **داخل Claude-hosted cloud environment (هذا المستودع، `amer`)**: السكيلات وإعدادات المشروع تعمل تلقائيًا من المستودع نفسه دون أي تدخل:
  - `.claude/skills` تُكتشف تلقائيًا على مستوى المشروع (111 سكيل).
  - `CLAUDE.md` وقالب التوجيه المستورد (`@.claude/templates/automatic-skill-routing.md`) يُحمّلان تلقائيًا في كل جلسة جديدة.
  - `.claude/settings.json` يشغّل حارس الأفعال الخطرة (`guard-dangerous`) واقتراح `/compact` (`suggest-compact`) تلقائيًا.
  - لا يلزم تشغيل `install-global-skills.sh` داخل الـVM السحابية إطلاقًا.
  - إعدادات `~/.claude` داخل هذه الـVM **ليست مصدر ديمومة** — الحاوية مؤقتة ومصدر الحقيقة الوحيد هو مستودع GitHub (`master`)، لا `HOME` المحلي للجلسة.

- **على جهاز دائم أو بيئة محلية**: `~/.claude` يبقى بين الجلسات، لذا يمكن تشغيل:
  ```bash
  ./scripts/install-global-skills.sh
  ```
  لتركيب السكيلات والحارس وبلوك التوجيه وGlobal TypeScript LSP plugin وGlobal Pyright LSP plugin عالميًا في `~/.claude`. هذا التثبيت العالمي **لا ينتقل تلقائيًا** من بيئة سحابية إلى جهاز آخر أو العكس — كل بيئة تُركَّب فيها بشكل مستقل عند الحاجة.
