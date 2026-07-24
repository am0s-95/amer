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

## MCP Server Dev Curated (2026-07-24)

- **المصدر:** https://github.com/anthropics/claude-plugins-official
- **المسار:** `plugins/mcp-server-dev`
- **Branch:** `main` (لا يوفّر المصدر tag مخصصًا لهذا الـPlugin بمفرده — المستودع monorepo يضم عشرات الـPlugins بدون إصدارات Git منفصلة لكل واحد)
- **Commit SHA:** `66799ffb4611b7e0c3af391c7569823a4d6b4246` (قمة `main` وقت التحقق — تم التحقق منه مباشرة عبر `github.com/anthropics/claude-plugins-official/commits/main.atom`، SHA كامل من 40 حرفًا، غير مختصر).
- **تاريخ الاستيراد:** 2026-07-24.
- **الترخيص:** Apache License 2.0 (نص الترخيص الكامل في `LICENSE` بمستودع المصدر).
- **طريقة الاستيراد:** نفس Marketplace المحلي المخصص (`.claude/marketplaces/skill-master-plugins`) يضيف عنصر Plugin ثالثًا (`mcp-server-dev-curated`) يشير بمصدر `git-subdir` إلى مجلد `plugins/mcp-server-dev` كاملًا (على الـcommit أعلاه)، مع حقل `skills` صريح يسرد ثلاث سكيلات بأسمائها بالضبط. لا استنساخ محلي، لا نسخ يدوي لملفات — الجلب عبر آلية Claude Code Plugin القياسية (git-subdir sparse clone) عند وقت التثبيت.
- **السكيلات المستوردة (3):** `build-mcp-server`، `build-mcp-app`، `build-mcpb` — كل واحدة كملف `SKILL.md` واحد (`name`, `description`, `version: 0.1.0` في الـfrontmatter) + ملفات `references/` المرافقة لها، بدون تعديل على محتواها.

### فحص بنية المصدر قبل الاستيراد

تم التحقق (قراءة فقط، عبر `raw.githubusercontent.com` و`github.com` على الـSHA أعلاه) أن مجلد `plugins/mcp-server-dev` بالكامل يحتوي فقط: `.claude-plugin/plugin.json`، `skills/`، `LICENSE`، `README.md` — بلا `hooks.json`، بلا `agents/`، بلا `.mcp.json`/`mcpServers`، بلا `lspServers`، وبلا أي سكربت تنفيذي. ملف `plugin.json` نفسه يحتوي فقط `name`/`description`/`author`، وعنصر `mcp-server-dev` داخل `marketplace.json` الرسمي للمستودع يحتوي فقط `name`/`description`/`author`/`source`/`category`/`homepage` — بلا أي حقل تنفيذي إضافي.

ملفات `references/` لكل سكيل (موثّقة هنا لضمان عدم فقدانها عند التثبيت الفعلي):

| السكيل | ملفات references/ |
|---|---|
| `build-mcp-server` (8) | `auth.md`, `deploy-cloudflare-workers.md`, `elicitation.md`, `remote-http-scaffold.md`, `resources-and-prompts.md`, `server-capabilities.md`, `tool-design.md`, `versions.md` |
| `build-mcp-app` (6) | `abuse-protection.md`, `apps-sdk-messages.md`, `directory-checklist.md`, `iframe-sandbox.md`, `payload-budgeting.md`, `widget-templates.md` |
| `build-mcpb` (2) | `local-security.md`, `manifest-schema.md` |

### سبب اعتماد نسخة Curated مثبّتة بدل متابعة Marketplace الحي

الإضافة الرسمية غير المنقّحة (`mcp-server-dev@claude-plugins-official`) تتطلب تسجيل marketplace رسمي حيّ يتابع `main` مباشرة — أي تحديثات مستقبلية غير مُراجَعة تصل تلقائيًا. كما أن سابقة معروفة من إصدارات أقدم لـClaude Code تُظهر خللًا في اكتشاف السكيلات (Skill discovery) لبعض الإضافات المُثبَّتة من marketplaces حيّة. لتفادي الأمرين معًا: (1) تثبيت المصدر على SHA كامل ثابت (`66799ffb4611b7e0c3af391c7569823a4d6b4246`) بدل متابعة `main` حيًا، و(2) إثبات اكتشاف فعلي للسكيلات الثلاث على نسخة Claude Code الحالية (2.1.218) قبل الدمج، بدل الافتراض أن وجود الملفات على القرص يعني اكتشافها. النتيجة مؤكَّدة عمليًا عبر اختبار تكامل حقيقي (HOME مؤقت، شبكة فعلية، Claude CLI حقيقي — راجع نتائج `claude plugin details mcp-server-dev-curated@skill-master-plugins` أدناه).

### مشكلة Skill discovery حقيقية مُكتشَفة ومُصحَّحة أثناء الاختبار التكاملي

المحاولة الأولى استخدمت `path: "plugins/mcp-server-dev"` (المجلد الكامل، بما فيه `.claude-plugin/plugin.json` الأصلي) مع حقل `skills` صريح في `marketplace.json`. النتيجة الفعلية عبر `claude plugin list --json` (HOME مؤقت، Claude Code 2.1.218، شبكة فعلية):

```json
"errors": ["Plugin mcp-server-dev-curated has conflicting manifests: both plugin.json and marketplace entry specify components. Set strict: true in marketplace entry or remove component specs from one location."]
```

ونتيجة `claude plugin details mcp-server-dev-curated@skill-master-plugins`: **`Plugin ... not found`** — رغم أن الملفات الثلاث كاملة موجودة فعليًا على القرص في cache الـPlugin (`skills/build-mcp-server`، `build-mcp-app`، `build-mcpb` كلها موجودة بمحتواها الكامل). هذه بالضبط حالة "الملفات موجودة لكن الاكتشاف فشل" التي حذّر منها هذا التكليف.

**السبب:** تضمين `.claude-plugin/plugin.json` الأصلي (من المصدر) في نطاق الـgit-subdir، مع تكرار تعريف السكيلات مرة أخرى صراحة في `marketplace.json` — تعارض بين مصدرين للحقيقة. `ponytail-curated` و`obsidian-curated` لا يعانيان من هذه المشكلة لأن `path` فيهما يشير مباشرة إلى مجلد `skills/` نفسه (متجاوزًا أي `.claude-plugin/plugin.json` متداخل).

**الإصلاح المعتمد:** تغيير `path` إلى `plugins/mcp-server-dev/skills` (مطابقًا لنفس نمط Ponytail/Obsidian المُثبَت)، وتحديث حقل `skills` إلى `./build-mcp-server`، `./build-mcp-app`، `./build-mcpb` (بدون بادئة `skills/`، لأن جذر المصدر أصبح مجلد `skills/` نفسه). أُعيد الاختبار كاملًا من الصفر (HOME مؤقت جديد) بعد هذا التصحيح.

**نتائج اختبار Skill discovery الحقيقي (بعد الإصلاح، HOME مؤقت جديد، شبكة فعلية، Claude Code 2.1.218):**

- `claude plugin list --json`: الثلاثة (`ponytail-curated`, `obsidian-curated`, `mcp-server-dev-curated`) مثبّتة بحقل `user` scope، **بلا** حقل `errors`.
- `claude plugin details mcp-server-dev-curated@skill-master-plugins`:
  ```
  Component inventory
    Skills (3)  build-mcp-app, build-mcp-server, build-mcpb
    Agents (0)
    Hooks (0)
    MCP servers (0)
    LSP servers (0)
  ```
- `installed_plugins.json` يسجّل `"gitCommitSha": "66799ffb4611b7e0c3af391c7569823a4d6b4246"` مطابقًا تمامًا للـSHA المُتحقَّق منه.
- Skill discovery فعلي عبر `claude -p` (لا cache فقط): طلب "اذكر أسماء كل Skill متاحة متعلقة ببناء MCP" أعاد فعليًا `mcp-server-dev-curated:build-mcp-server`، `mcp-server-dev-curated:build-mcp-app`، `mcp-server-dev-curated:build-mcpb` (مع بادئة المصدر الصحيحة)، بالإضافة إلى `mcp-server-patterns` و`mcp-builder` الموجودين مسبقًا.
- استدعاء آمن لـ`build-mcp-server` عبر `claude -p` بطلب: *"I want to wrap a cloud REST API as an MCP server. Identify the recommended deployment model and the discovery questions, but do not scaffold code."* — الرد طبّق منهجية السكيل الفعلية حرفيًا (أوصى بـremote streamable-HTTP كنموذج افتراضي، سرد نفس أسئلة الاكتشاف الخمس/الست الموثّقة في `SKILL.md`: نوع الاتصال، المستخدمون، عدد الإجراءات، الحاجة لواجهة/elicitation، نوع المصادقة، تفضيل الإطار)، **بلا أي كتابة أو إنشاء ملفات**.
- ملفات `references/` قُرئت فعليًا من مجلد الـcache بعد التثبيت الحقيقي (مثال: `references/auth.md` لـ`build-mcp-server` قابل للقراءة ومحتواه سليم) — لا فقدان لأي ملف من الـ16 المذكورة أعلاه.
- Idempotency: تشغيل ثانٍ للمثبّت الكامل على نفس HOME المؤقت أنتج "تخطي" لكل من marketplace add والثلاثة plugin installs (بلا أي `update` أو تكرار `add`).
- `settings.json` بعد التثبيتين: بلا `statusLine`، وحقل `hooks` يحتوي `PreToolUse` فقط (بمطابقات `Bash`, `mcp__github__.*`, `Edit`, `Write` — حراسنا الأربعة فقط)، بلا `SessionStart`/`SubagentStart`/`UserPromptSubmit`.
- تم حذف كلا الـHOME المؤقتين المستخدمين في الاختبار بعد انتهائه؛ لم يُشغَّل المثبّت على HOME الحقيقي في أي لحظة.

## Session Report Curated (2026-07-24)

- **المصدر:** https://github.com/anthropics/claude-plugins-official
- **المسار:** `plugins/session-report`
- **Branch:** `main` (لا يوفّر المصدر tag مخصصًا لهذا الـPlugin بمفرده — نفس نمط `mcp-server-dev-curated`)
- **Commit SHA:** `b4810bd800e10c8595d79835e61e5945c1cd81ba` (قمة `main` وقت التحقق — تم التحقق منه مباشرة عبر `git clone` كامل للمستودع الرسمي وقراءة `git rev-parse HEAD`، SHA كامل من 40 حرفًا، غير مختصر، ولا اعتماد على `main` حيًا في النسخة النهائية).
- **تاريخ الاستيراد:** 2026-07-24.
- **الترخيص:** Apache License 2.0 (نص الترخيص الكامل في `LICENSE` بمستودع المصدر ومنسوخ حرفيًا في `LICENSE` داخل الـPlugin المنقّح).
- **طريقة الاستيراد:** نسخ محلي (لا `git-subdir` حي) داخل هذا المستودع نفسه، على عكس الثلاثة السابقين. السبب: المصدر الرسمي يحتاج تعديلات حقيقية في المحتوى (إصلاح مسار transcripts، إخفاء البرومبتات افتراضيًا) لا يمكن تحقيقها بمجرد جلب الملفات كما هي من `main` حيّ — `git-subdir` يجلب الملفات الأصلية غير المعدَّلة دائمًا. النسخة المنقَّحة موجودة في `.claude/marketplaces/skill-master-plugins/plugins/session-report-curated/` (داخل جذر الـMarketplace نفسه، لأن مدقّق `claude plugin validate` يرفض أي `source` محلي يحتوي `..` — المسارات المحلية يجب أن تُحل نسبةً لجذر الـMarketplace، لا لمسار `marketplace.json`)، ويشير إليها عنصر `session-report-curated` في `marketplace.json` بحقل `source` نصي مباشر (`./plugins/session-report-curated`) بدل كائن `git-subdir`.
- **الملفات المستوردة:** `skills/session-report/SKILL.md`، `skills/session-report/analyze-sessions.mjs`، `skills/session-report/template.html`، `LICENSE` — منسوخة من المصدر الرسمي على الـSHA أعلاه ثم عُدِّلت محليًا (التفاصيل أدناه). لا ملفات `references/` مرافقة في هذا الـPlugin (المصدر الرسمي لا يتضمن أي).

### المشكلتان المعروفتان في المصدر الرسمي (وسبب رفض `session-report@claude-plugins-official` غير المنقّح)

تم التحقق من كليهما مباشرة على السطر `b4810bd800e10c8595d79835e61e5945c1cd81ba`:

1. **غياب `.claude-plugin/plugin.json` داخل `plugins/session-report`:** المصدر يعرّف الـPlugin فقط عبر عنصر في `marketplace.json` الرسمي للمستودع (`"source": "./plugins/session-report"`, بلا `version` أصلًا) — لا يوجد ملف manifest مستقل للـPlugin نفسه. هذا يطابق ما وصفه التكليف: تثبيت الإضافة الرسمية دون `plugin.json` صريح يُعرّض لاحتمال أن يُشتق اسم/نطاق (namespace) الـPlugin من Git SHA بدل اسم ثابت مقروء، بحسب كيفية تعامل marketplace الحي مع مجلد بلا manifest مستقل.
2. **`analyze-sessions.mjs` يثبّت المسار على `~/.claude/projects`:** السطر الأصلي `const ROOT = flag('--dir', path.join(os.homedir(), '.claude', 'projects'))` — لا يقرأ `process.env.CLAUDE_CONFIG_DIR` إطلاقًا. أي مستخدم يشغّل Claude Code بـ`CLAUDE_CONFIG_DIR` مخصص (شائع في بيئات معزولة/CI) يحصل على تقرير فارغ أو خاطئ بصمت، دون أي إشارة للسبب.

كلا المشكلتين مُصلَحتان في النسخة المنقّحة (راجع التعديلات المحلية أدناه)، وتم التحقق من الإصلاح عبر اختبار وحدة (`tests/test-session-report-analyzer.sh`) واختبار تكامل حقيقي (`tests/test-install-session-report-curated.sh` + اختبار HOME مؤقت حقيقي، النتائج أدناه).

### التعديلات المحلية على `analyze-sessions.mjs`

- **دعم `CLAUDE_CONFIG_DIR`:** `ROOT` الافتراضي أصبح `path.join(process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude'), 'projects')`، مع بقاء `--dir` بأولوية كاملة فوق الاثنين (لم يتغيّر منطق `flag()` نفسه).
- **حقول metadata إضافية في JSON output:** `config_dir`، `root` (كان موجودًا أصلًا)، `generated_at` (كان موجودًا أصلًا)، `requested_since` (القيمة الخام لـ`--since` كما مُرِّرت، أو `null`)، و`privacy: {prompts_included, local_only: true}`.
- **إخفاء البرومبتات افتراضيًا (خصوصية):** `top_prompts[].text` يصبح `"[redacted]"` و`context` يصبح `null` ما لم يُمرَّر `--include-prompts` صراحة. نفس القاعدة على `cache_breaks[].context`. عند تمرير `--include-prompts` تُطبع رسالة تحذير واضحة على `stderr` توضّح أن التقرير سيحتوي نصًا حرفيًا من محادثات المستخدم.
- **معالجة آمنة لمجلد transcripts المفقود:** فحص `fs.existsSync(ROOT)` صريح مع رسالة واضحة على `stderr` عند غيابه (السلوك الأصلي كان يتجاهل الخطأ بصمت عبر `try/catch` في `walk()` بدون أي رسالة) — بلا `stack trace`، `exit code 0`، وتقرير JSON فارغ صالح (`sessions: 0`).
- **الوضع النصي (`printText`) يطابق نفس قواعد الإخفاء** عبر إعادة استخدام `topPrompts()` نفسها، ويطبع سطرًا إضافيًا في الرأس يوضّح `config dir` وحالة الخصوصية.

### التعديل المحلي على `template.html`

- حُذفت ثلاثة أسطر `<link>` كانت تجلب خط JetBrains Mono من Google Fonts (`fonts.googleapis.com`/`fonts.gstatic.com`) — طلب شبكة خارجي يخالف متطلب "self-contained HTML بلا CDN بلا network requests". حُذفت `'JetBrains Mono'` من متغيّر CSS `--mono` (يبقى fallback إلى `SF Mono`/`ui-monospace`/`Menlo`/`Monaco`/`monospace` — كلها خطوط نظام، بلا أي طلب شبكة). لا تعديل آخر على القالب — بقيت كل الجداول، الفرز، الطي، والرسوم بالحروف كما هي.
- أُضيف سطر واحد في `foot-stats` يعرض حالة الخصوصية (`prompts redacted` أو `prompts included (--include-prompts)`) بالاعتماد على حقل `DATA.privacy` الجديد — لا يكسر شيئًا إن كان الحقل غائبًا (تحقّق شرطي).

### `plugin.json` الجديد (يُصلح المشكلة #1)

```json
{
  "name": "session-report-curated",
  "displayName": "Session Report Curated",
  "version": "1.0.0-skill-master.1",
  "description": "Generate privacy-conscious HTML reports of local Claude Code session usage",
  "author": { "name": "Anthropic / Skill Master curated" },
  "license": "Apache-2.0"
}
```

سكيل واحدة فقط (`session-report`)، بلا `hooks`/`agents`/`mcpServers`/`lspServers` في `plugin.json` ولا في تعريف الـPlugin داخل `marketplace.json`.

### مكان إخراج التقرير (SKILL.md)

خلافًا للنسخة الرسمية (تكتب `session-report-*.html` داخل الدليل الحالي — قد يكون مستودع عمل Git)، تُلزم النسخة المنقّحة بالكتابة إلى `~/.claude/reports/` حصرًا (`mkdir -m 700` للمجلد، `chmod 600` للملف)، ولا تكتب أبدًا داخل مستودع مشروع. هذا تعديل على تعليمات `SKILL.md` فقط (توجيه للوكيل الذي ينفّذ الخطوات)، وليس على `analyze-sessions.mjs` نفسه (الذي لا يكتب أي ملف — يطبع JSON على `stdout` فقط).

### نتائج الاختبارات

- **اختبار وحدة المحلل** (`tests/test-session-report-analyzer.sh`, fixtures صناعية فقط): 41/41 نجاح — يغطي احترام `CLAUDE_CONFIG_DIR`، أولوية `--dir`، معالجة المجلد المفقود، الفترات الزمنية الأربع، إخفاء prompts افتراضيًا، `--include-prompts`، dedup الطلبات المكرَّرة (نفس `requestId` بقطعتين، يُحتسب مرة واحدة بأعلى `output_tokens`)، عدم تسرّب نص سرّي اختباري في `stdout`/`stderr` بالوضع الافتراضي، وHTML بلا روابط CDN.
- **اختبار تركيب معزول** (`tests/test-install-session-report-curated.sh`, claude CLI وهمي عام `tests/fixtures/mock-claude-ponytail`): يغطي صحة `marketplace.json`/`plugin.json`، سكيل واحدة فقط، صفر hooks/agents/mcpServers/lspServers، التثبيت بـ`user scope`، idempotency التشغيل الثاني (لا تكرار `add`/`install`، لا `update` عند تطابق النسخة)، عدم تثبيت `session-report@claude-plugins-official` الأصلي بالتوازي، بقاء `ponytail-curated`/`obsidian-curated`/`mcp-server-dev-curated` (مزروعة مسبقًا في حالة الـmock) مثبَّتة بلا تغيير، سلامة `settings.json` (بلا Hooks/statusLine جديدة)، عدم إنشاء `~/.claude/reports` أثناء الـbootstrap، عدد سكيلات المصدر يبقى 111، وقواعد التوجيه التلقائي الخاصة بـSession Report موجودة مرة واحدة بالضبط.
- **اختبار تكامل حقيقي** (HOME مؤقت جديد بالكامل، Claude Code 2.1.219 الحقيقي، شبكة فعلية، fixtures صناعية فقط — لا transcripts حقيقية):
  - التثبيت الكامل (`install-global-skills.sh` بلا أي `SKIP_INSTALL` عدا LSP) ثبّت الأربعة معًا: `ponytail-curated`، `obsidian-curated`، `mcp-server-dev-curated`، `session-report-curated`، كلها بـ`user scope`.
  - **مشكلة حقيقية اكتُشفت وصُحِّحت أثناء الاختبار:** المحاولة الأولى تضمّنت حقل `"skills": ["./skills/session-report"]` صريحًا في عنصر `marketplace.json` **مع** وجود `.claude-plugin/plugin.json` في نفس مجلد الـPlugin — نفس تعارض "conflicting manifests" الموثَّق سابقًا لـ`mcp-server-dev-curated` (راجع القسم أعلاه). `claude plugin list --json` أعاد فعليًا: `"errors": ["Plugin session-report-curated has conflicting manifests: both plugin.json and marketplace entry specify components. Set strict: true in marketplace entry or remove component specs from one location."]`. **الإصلاح:** حذف حقل `skills` من عنصر `marketplace.json` نهائيًا — `plugin.json` المحلي + اصطلاح مجلد `skills/session-report/SKILL.md` كافيان وحدهما للاكتشاف، بلا أي تكرار لمصدر الحقيقة. بعد `claude plugin marketplace update skill-master-plugins` و`claude plugin update session-report-curated@skill-master-plugins`: صفر أخطاء.
  - `claude plugin details session-report-curated@skill-master-plugins` (بعد الإصلاح): `Skills (1)  session-report`، `Agents (0)`، `Hooks (0)`، `MCP servers (0)`، `LSP servers (0)`.
  - Skill discovery فعلي عبر `claude -p` (لا cache فقط): طلب "اذكر أسماء أي Skills متعلقة بتقارير الاستخدام/tokens/cache" أعاد فعليًا `session-report-curated:session-report` فقط (مع بادئة المصدر الصحيحة).
  - تشغيل المحلل الفعلي من نسخة الـcache المثبَّتة فعليًا (لا من نسخة المستودع) على fixture صناعية تحتوي نص سرّي اختباري فريد: الوضع الافتراضي أعاد `top_prompts[0].text: "[redacted]"`, `context: null`, `privacy: {"prompts_included":false,"local_only":true}` — والسر لم يظهر في stdout/JSON. تجربة منفصلة بـ`--include-prompts` أعادت النص الحقيقي فعليًا + تحذيرًا واضحًا على `stderr`.
  - HTML مجمَّع فعليًا (قالب الـcache المثبَّت + JSON الافتراضي المُخفى) في `~/.claude/reports/` بصلاحيات `700`/`600`: بنية `<!doctype html>`...`</html>` سليمة، `#report-data` يحمل الـJSON، بلا أي `http://`/`https://`، والسر لم يتسرّب إلى ملف HTML.
  - لم يُكتب أي شيء داخل مستودع `amer` نفسه في أي خطوة من هذا الاختبار (تحقّق `git status --porcelain` قبل/بعد يطابق التغييرات المقصودة لهذه المهمة فقط).
  - لا طلبات شبكة أثناء تشغيل `analyze-sessions.mjs` نفسه (يستورد `fs`/`os`/`path`/`readline` فقط — الشبكة استُخدمت فقط لتثبيت الـPlugins عبر `claude plugin install`، وهي خطوة تثبيت لا تحليل).
  - **Idempotency:** تشغيل ثانٍ كامل للمثبّت على نفس HOME المؤقت أنتج "تخطي" لكل من marketplace add والأربعة plugin installs (بلا أي `update` أو تكرار `add`)، و`claude plugin list --json` أظهر الأربعة بلا أي حقل `errors`.
  - تم حذف الـHOME المؤقت والـfixtures الصناعية والمستودع المستنسخ للمرجع بعد انتهاء الاختبار بالكامل؛ لم يُشغَّل المحلل على transcripts حقيقية في أي لحظة.
