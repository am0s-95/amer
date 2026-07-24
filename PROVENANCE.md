# مصادر السكيلات المستوردة — Provenance

## دفعة ECC (2026-07-23)

- **المصدر:** https://github.com/affaan-m/ECC
- **upstream commit:** `a3130f9ebfaeed075df5d5b52538acb0ee4bcdf8` (فرع `main`)
- **الترخيص:** MIT — Copyright (c) 2026 Affaan Mustafa (نص الترخيص في مستودع المصدر)
- **طريقة الاستيراد:** نسخ مجلد كل سكيل كما هو (`skills/<name>/SKILL.md`) بدون تعديل على المحتوى أو الـmetadata الأصلية (`origin: ECC` باقية في الـfrontmatter). لا symlinks خارجية، لا مستودع متداخل.

| السكيل | الملفات | اعتماد خارجي |
|---|---|---|
| `documentation-lookup` | SKILL.md | يعمل بكامل فائدته مع Context7 MCP (غير مركّب هنا) |
| `database-migrations` | SKILL.md | لا شيء |
| `deployment-patterns` | SKILL.md | لا شيء |
| `mcp-server-patterns` | SKILL.md | لا شيء |
| `deep-research` | SKILL.md | يتطلب Exa/Firecrawl MCP للتشغيل الفعلي (غير مركّبة هنا) |

**نتيجة الفحص الأمني قبل الدمج:** لا hooks تنفيذية، لا scripts، لا `allowed-tools`، لا `disable-model-invocation`، لا أوامر نشر/حذف/secrets — كل ما ظهر في grep أمثلة توثيقية داخل الشروحات (Dockerfile healthcheck، صيغ GitHub Actions).

## Ponytail Curated (2026-07-24)

- **المصدر:** https://github.com/DietrichGebert/ponytail
- **Tag:** `v4.8.4`
- **Commit SHA:** `bc9ee949d5f439e8b9f3bb92c6d6d3d1e6ebd324` (مطابق لـ`gitHead` في نسخة npm المنشورة `@dietrichgebert/ponytail@4.8.4`، وتم التحقق منه مباشرة عبر `raw.githubusercontent.com` على هذا الـref).
- **الترخيص:** MIT — Copyright (c) 2026 DietrichGebert (نص الترخيص الكامل في `LICENSE` بمستودع المصدر).
- **طريقة الاستيراد:** Marketplace محلي مخصص (`.claude/marketplaces/skill-master-plugins`) يشير بمصدر `git-subdir` إلى مجلد `skills/` فقط من مستودع Ponytail (على الـcommit أعلاه)، مع حقل `skills` صريح في تعريف الـPlugin يسرد الست سكيلات بأسمائها الست بالضبط. لا استنساخ محلي، لا نسخ يدوي لملفات — الجلب يتم عبر آلية Claude Code Plugin القياسية (git-subdir sparse clone) عند وقت التثبيت.
- **السكيلات المستوردة (6):** `ponytail`، `ponytail-review`، `ponytail-audit`، `ponytail-debt`، `ponytail-gain`، `ponytail-help` — كل واحدة كملف `SKILL.md` واحد بدون تعديل على محتواها.

### أسباب استبعاد Hooks وbقية مكوّنات Ponytail الأصلي

مشروع Ponytail الرسمي (`ponytail@ponytail` عبر التثبيت الكامل الموثّق في README الأصلي) يضيف عند تثبيته الكامل:

- Hooks على `SessionStart`, `SubagentStart`, `UserPromptSubmit` (تفعيل تلقائي للوضع + حقن القواعد في كل جلسة **وفي كل Subagent فرعي بلا استثناء**، بما فيها وكلاء بحث/تخطيط قرائية بحتة).
- نُدجة (nudge) تلقائية عند أول جلسة تقترح على الوكيل إضافة مفتاح `statusLine` مباشرة إلى `~/.claude/settings.json`.
- ملف حالة خاص خارج مجلد الـPlugin (`~/.claude/.ponytail-active`, `~/.config/ponytail/config.json`).

الإصدار الثابت `v4.8.4` **لا يطبّق** متغيّر البيئة `PONYTAIL_SUBAGENT_MATCHER` داخل `hooks/ponytail-subagent.js` بصورة مضمونة الأثر في هذا السياق (سلوك حقن غير قابل للتحييد بثقة كافية لكل أنواع الـSubagents هنا)، ولذلك تقرر استبعاد Hooks بالكامل بدل محاولة تحييدها بمتغيّر بيئة. هذا القرار مبني على تشخيص سابق (راجع سجل المحادثة/تقرير التشخيص) خلص إلى أن تثبيت الـPlugin الكامل سيحقن قواعد Ponytail في كل Subagent — بما فيها وكلاء القراءة/البحث/التخطيط — وهو أثر جانبي غير مرغوب في Skill Master.

الحل المعتمد: استيراد الست سكيلات فقط (لا قيمة تنفيذية تلقائية لها بذاتها — تُستدعى فقط عند مطابقة الوصف/التوجيه)، عبر `strict: false` في تعريف الـPlugin بحيث تكون قائمة `skills` الصريحة هي التعريف الكامل والوحيد لمكوّنات الـPlugin، دون أي حقل `hooks`/`agents`/`mcpServers` في نفس التعريف. النتيجة مؤكَّدة عمليًا: `claude plugin details ponytail-curated@skill-master-plugins` يُظهر `Hooks (0)`, `Agents (0)`, `MCP servers (0)`, و`Skills (6)` بالأسماء الست بالضبط — ولا تُضاف أي إشارة إلى `SessionStart`/`SubagentStart`/`UserPromptSubmit` أو `statusLine` في `~/.claude/settings.json` نتيجة هذا التثبيت.

## Obsidian Curated (2026-07-24)

- **المصدر:** https://github.com/kepano/obsidian-skills
- **Branch:** `main`
- **Commit SHA:** `a1dc48e68138490d522c04cbf5822214c6eb1202` (تم التحقق منه مباشرة بعملية `git clone` للمستودع الرسمي وقراءة `git rev-parse HEAD` — SHA كامل من 40 حرفًا، غير مختصر).
- **تاريخ الاستيراد:** 2026-07-24.
- **الترخيص:** MIT — Copyright (c) 2026 Steph Ango (@kepano) (نص الترخيص الكامل في `LICENSE` بمستودع المصدر).
- **طريقة الاستيراد:** نفس Marketplace المحلي المخصص (`.claude/marketplaces/skill-master-plugins`) يضيف عنصر Plugin ثانيًا (`obsidian-curated`) يشير بمصدر `git-subdir` إلى مجلد `skills/` فقط من مستودع Obsidian Skills (على الـcommit أعلاه)، مع حقل `skills` صريح يسرد ثلاث سكيلات بأسمائها بالضبط. لا استنساخ محلي، لا نسخ يدوي لملفات — الجلب عبر آلية Claude Code Plugin القياسية (git-subdir sparse clone) عند وقت التثبيت.
- **السكيلات المستوردة (3):** `obsidian-markdown`، `obsidian-bases`، `json-canvas` — كل واحدة كملف `SKILL.md` واحد (+ ملفات `references/` المرافقة لها) بدون تعديل على محتواها.

### أسباب استبعاد obsidian-cli وdefuddle

مستودع kepano/obsidian-skills الرسمي يضم خمس سكيلات: `obsidian-markdown`، `obsidian-bases`، `json-canvas`، `obsidian-cli`، و`defuddle`. استُبعدت اثنتان عمدًا من `obsidian-curated`:

- **`obsidian-cli`**: يتطلب تطبيق Obsidian فعليًا مفتوحًا وقيد التشغيل (يتواصل مع نسخة حيّة عبر أوامر مثل `obsidian create`/`obsidian search`) — بيئة غير متاحة افتراضيًا داخل Claude Cloud (لا واجهة رسومية، لا تطبيق Obsidian مثبّت). تثبيته هنا سينتج سكيلًا لا يعمل بنيويًا في أغلب الجلسات.
- **`defuddle`**: يكرر وظيفيًا أدوات استخراج محتوى الويب المتاحة عالميًا فعلًا في Skill Master عبر Exa وFirecrawl (MCP servers مثبّتة ومفعّلة). إضافته تُنتج ازدواجية بلا قيمة إضافية.

الثلاث سكيلات المستوردة (`obsidian-markdown`، `obsidian-bases`، `json-canvas`) هي "Open Format Skills" فقط — تصف صيغ ملفات مفتوحة (Markdown الخاص بأوبسيديان، Bases، JSON Canvas) ولا تعتمد على تطبيق أو أداة خارجية للعمل، بخلاف الاثنتين المستبعدتين. تم التحقق أيضًا من خلو المستودع بالكامل (وليس فقط السكيلات الثلاث) من أي Hooks أو Agents أو اعتماديات MCP لازمة — النتيجة مؤكَّدة عمليًا: `claude plugin details obsidian-curated@skill-master-plugins` يُظهر `Skills (3)`, `Hooks (0)`, `Agents (0)`, `MCP servers (0)`, `LSP servers (0)` — ولا تُضاف أي إشارة إلى `SessionStart`/`SubagentStart`/`UserPromptSubmit` أو `statusLine` في `~/.claude/settings.json` نتيجة هذا التثبيت. تفعيل هذه السكيلات مقيَّد بقواعد Automatic Skill Routing (راجع `.claude/templates/automatic-skill-routing.md`، قسم "Obsidian routing") بحيث لا تُستخدم صيغة أوبسيديان (Wikilinks، Callouts، Properties) تلقائيًا في Markdown العادي لمشاريع البرمجة.
