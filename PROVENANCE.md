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
