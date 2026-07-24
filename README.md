# amer

مكتبة سكيلات Claude Code (111 سكيل — انظر `PROFILES.md` للتنظيم و`PROVENANCE.md` لمصادر المستورد منها) مع مثبّت عالمي وحارس للأفعال الخطرة.

## التركيب

```bash
./scripts/install-global-skills.sh            # تركيب/تحديث الروابط + الحارس + بلوك التوجيه
./scripts/install-global-skills.sh --prune    # + حذف الروابط اليتيمة المُدارة فقط
./scripts/install-global-skills.sh --copy     # نسخ بدل الروابط
```

المثبّت idempotent ويقوم بستة أشياء:

1. **السكيلات**: symlinks من `.claude/skills/*` إلى `~/.claude/skills/` (111 سكيل).
2. **الحُرّاس**: ينسخ `guard-dangerous.js` و`suggest-compact.js` (وتبعياته) إلى `~/.claude/hooks/`، ويسجّلهما في `~/.claude/settings.json` — `guard-dangerous` على `Bash`، و`suggest-compact` على `Edit` و`Write` (دمج آمن — لا يستبدل الملف).
3. **التوجيه التلقائي**: يزامن البلوك المُدار `automatic-skill-routing` (من `.claude/templates/`) داخل `~/.claude/CLAUDE.md` — يحدّث ما بين العلامتين فقط ولا يمس نص المستخدم.
4. **Global TypeScript LSP plugin**: يثبّت plugin شخصي عالمي (skills-directory plugin بلا `SKILL.md` — لا يُحتسب ضمن الـ111 سكيل) في `~/.claude/skills/typescript-lsp-global`، مع runtime ثابت في `~/.local/share/typescript-lsp` يحتوي نسخًا مثبّتة بدقة: `typescript-language-server@5.3.0` و`typescript@5.7.2`. يعمل عالميًا في كل المشاريع تلقائيًا؛ إن كان للمشروع نسخة TypeScript محلية داخل `node_modules` فهي تُستخدم أولًا، والنسخة العالمية (5.7.2) تعمل كـ fallback فقط. تثبيت dependencies الخاصة بكل مشروع يبقى مسؤولية المشروع نفسه — هذا الـplugin لا يثبّت أو يستبدل شيئًا داخل مشاريعك. `npm install` يُشغَّل فقط عند أول تركيب أو عند تغيّر النسخ المطلوبة، ويمكن تخطيه بمتغيّر البيئة `TS_LSP_SKIP_INSTALL=1`.
5. **Global Pyright LSP plugin**: يثبّت plugin شخصي عالمي (skills-directory plugin بلا `SKILL.md` — لا يُحتسب ضمن الـ111 سكيل) في `~/.claude/skills/pyright-lsp-global`، مع runtime ثابت في `~/.local/share/pyright-lsp` يحتوي نسخة مثبّتة بدقة: `pyright@1.1.411` من npm الرسمي. يعمل عالميًا في كل مشاريع Python تلقائيًا عبر Skill Master، ويحترم إعداد كل مشروع الخاص — `pyrightconfig.json` أو `pyproject.toml` أو بيئته الافتراضية — فلا يوجد `typeCheckingMode` أو `pythonVersion` أو `venvPath` عالمي مفروض. تثبيت dependencies وبيئة `venv` الخاصة بكل مشروع تبقى مسؤولية المشروع نفسه؛ عدم تثبيت مكتبات المشروع قد يُنتج تشخيصات `missing-import`، وهذا لا يعني أن الـLSP معطّل. لا يجوز تثبيت الـPlugin الرسمي `pyright-lsp` (أو أي Marketplace Plugin مكافئ) بالتوازي مع `pyright-lsp-global` تفاديًا للتعارض. `npm install` يُشغَّل فقط عند أول تركيب أو عند تغيّر النسخة المطلوبة، ويمكن تخطيه بمتغيّر البيئة `PYRIGHT_LSP_SKIP_INSTALL=1`. `.lsp.json` يربط `workspaceFolder` بـ`` `${CLAUDE_PROJECT_DIR}` `` حرفيًا في كل جلسة، فيبدأ Pyright دائمًا من جذر المشروع الحالي بدل جذر غير مضمون، مما يمنع خلط المستودعات أو الـworktrees في جلسات Claude Cloud متعددة المشاريع.

## الاختبارات

```bash
bash tests/test-install-global-skills.sh    # المثبّت: التركيب، --prune، الـidempotency، البلوك المُدار
bash tests/test-guard-dangerous.sh          # الحارس: خطرة مباشرة/مغلّفة، آمنة، fail-safe
bash tests/test-project-skill-routing.sh    # توجيه السكيلات على مستوى المشروع + ميزانية القائمة
bash tests/test-install-typescript-lsp.sh   # Global TypeScript LSP: التركيب، المسارات المطلقة، الـidempotency (npm وهمي — بلا شبكة)
bash tests/test-install-pyright-lsp.sh      # Global Pyright LSP: التركيب، المسارات المطلقة، الـidempotency، نسخة 1.1.411 (npm وهمي — بلا شبكة)
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
