# تنظيم مكتبة السكيلات — Profiles

المرجع التاريخي المجمّد: 106 سكيل عند `aebeee7dd6dec7dbc85d9fd0be2a8580982b3264` (طريقة العد موثقة في `bench/PROTOCOL.md`).
الإجمالي الحالي: **111** بعد استيراد 5 سكيلات من ECC (القسم 12 أدناه؛ المصدر والـSHA في `PROVENANCE.md`).

**طبيعة هذا الملف:** توثيق وتنظيم فقط. كل السكيلات تبقى مثبتة كما هي — لا حذف ولا إضافة. عند بدء مشروع حقيقي، يُنسخ إلى مشروعك ما يلزم من الطبقات (Core + طبقات الـstack المستخدمة)، وتبقى البقية هنا كمكتبة مرجعية تُجلب عند الحاجة.

## طريقة الاستخدام عند بدء مشروع ضخم

1. انسخ طبقة **core** كاملة إلى `.claude/skills/` في مشروعك.
2. أضف طبقات الـstack التي يستخدمها المشروع فعلًا (مثلًا: web-frontend + backend-data + testing-qa + seo).
3. طبقة **devops-deploy** تُستدعى يدويًا فقط — لا تعتمد على تفعيلها التلقائي في تغييرات خطرة.
4. أي سكيل نادرة خارج المكتبة: استخدم `find-skills` وقت الحاجة بدل التثبيت المسبق.

---

## 1. core — الأساس الدائم (9)

تصلح لكل مشروع، دائمة التفعيل:

`token-saver` · `strategic-compact` · `context-budget` · `verification-before-completion` · `systematic-debugging` · `code-reviewer` · `error-handling` · `git-workflow` · `find-skills`

## 2. planning-workflow — سير عمل المهام الكبيرة (16)

للمشاريع متعددة المراحل (تخطيط ← تنفيذ ← مراجعة):

`brainstorming` · `intent-driven-development` · `product-lens` · `writing-plans` · `executing-plans` · `plan-canvas` · `subagent-driven-development` · `dispatching-parallel-agents` · `using-git-worktrees` · `finishing-a-development-branch` · `requesting-code-review` · `receiving-code-review` · `council` · `iterative-retrieval` · `loop-design-check` · `test-driven-development`

## 3. web-frontend — الواجهة (13)

`frontend-design` · `react-best-practices` · `composition-patterns` · `react-view-transitions` · `react-expert` · `nextjs-developer` · `vue-expert` · `typescript-pro` · `javascript-pro` · `ui-styling` · `ui-ux-pro-max` · `web-artifacts-builder` · `web-design-guidelines`

## 4. backend-data — الخلفية والبيانات (10)

`api-designer` · `graphql-architect` · `nestjs-expert` · `fastapi-expert` · `websocket-engineer` · `database-optimizer` · `postgres-pro` · `secure-code-guardian` · `fullstack-guardian` · `microservices-architect`

## 5. testing-qa — الاختبار والجودة (13)

`webapp-testing` · `playwright-expert` · `test-master` · `browser-qa` · `ai-regression-testing` · `click-path-audit` · `eval-harness` · `verification-loop` · `debugging-wizard` · `production-audit` · `repo-scan` · `santa-method` · `delivery-gate`

## 6أ. devops-knowledge — هندسة وتحليل التشغيل (4) — تلقائية

المعرفة والتحليل والمراجعة تُستدعى تلقائيًا كأي سكيل معرفية:

`devops-engineer` · `cloud-architect` · `monitoring-expert` · `vercel-optimize`

## 6ب. devops-execution — أوامر التنفيذ الخطرة (1) ⚠️ يدوية فقط

مقفلة بـ`disable-model-invocation: true` — لا يستدعيها النموذج تلقائيًا أبدًا، فقط أنت عبر الأمر الصريح:

`deploy-to-vercel` (تُستدعى بـ `/deploy-to-vercel`)

**قاعدة عامة للأفعال الخطرة** (مثبتة أيضًا في CLAUDE.md): النشر الفعلي، push للإنتاج، migrations، الحذف، تعديل موارد Cloud، ولمس secrets — كلها تتطلب أمرًا صريحًا منك مهما كانت السكيل المستدعاة. المعرفة تلقائية؛ التنفيذ الخطر بيدك.

## 7. seo-content — السيو والمحتوى (10)

`seo` (الموجّه) · `seo-audit` · `seo-technical` · `seo-schema` · `seo-content` · `seo-geo` · `seo-sitemap` · `seo-page` · `writing-guidelines` · `defuddle`

## 8. design-brand — التصميم والهوية (5)

`design` · `design-system` · `brand` · `banner-design` · `slides`

## 9. cms-commerce — منصات جاهزة (2)

`wordpress-pro` · `shopify-expert`

## 10. media-video — الفيديو (2)

`watch` (الأول دائمًا — الأوفر) · `video-perception` (احتياطي عند فشل watch أو للتحليل البنيوي؛ التوجيه في CLAUDE.md)

## 11. meta-maintenance — صيانة العدّة نفسها (21)

إدارة السكيلات والتعلم والتوثيق — نادرًا ما تلزم داخل مشروع منتج:

`writing-skills` · `skill-scout` · `skill-stocktake` · `rules-distill` · `hookify-rules` · `configure-ecc` · `ecc-guide` · `ecc-recipes` · `config-gc` · `continuous-learning-v2` · `growth-log` · `agent-self-evaluation` · `agent-introspection-debugging` · `agent-sort` · `ck` · `claude-code-tools-guide` · `using-superpowers` · `code-tour` · `codebase-onboarding` · `architecture-decision-records` · `inherit-legacy-style`

## 12. ecc-imported — مستوردة من ECC (5)

مستوردة من `affaan-m/ECC` (التفاصيل والفحص الأمني في `PROVENANCE.md`)، وتُوجَّه تلقائيًا عبر البلوك المُدار `automatic-skill-routing` الذي يزامنه المثبّت في `~/.claude/CLAUDE.md`:

`documentation-lookup` (توثيق حي عبر Context7 — مكمّلة لأي طبقة stack) · `database-migrations` (تكمّل backend-data: migrations وrollbacks وzero-downtime) · `deployment-patterns` (تكمّل devops-knowledge — معرفة فقط، التنفيذ الخطر يبقى يدويًا) · `mcp-server-patterns` (بناء خوادم MCP) · `deep-research` (بحث متعدد المصادر — تتطلب Exa/Firecrawl MCP للتشغيل الفعلي)

---

## حدود مرسومة بين السكيلات المتشابهة

| عند الحاجة إلى | استخدم | لا تستخدم |
|---|---|---|
| مراجعة كود مكتمل | `code-reviewer` (صريح) | `fullstack-guardian` (هذه للبناء لا للمراجعة) |
| بناء ميزة full-stack آمنة | `fullstack-guardian` | `secure-code-guardian` (هذه لنقاط الأمان المحددة) |
| كتابة اختبارات جديدة | `test-master` | `playwright-expert` (هذه لـE2E بالمتصفح فقط) |
| تصحيح خطأ قائم | `systematic-debugging` أولًا | `debugging-wizard` (تكملها عند تتبع stack traces) |
| فحص UI بصريًا | `webapp-testing` (أداتي) | `browser-qa` (تكامل بعد النشر) |

## ملاحظات

- **البروتوكول في `bench/PROTOCOL.md` خطة اختيارية غير معتمدة** — لا تنفيذ إلا بأمر صريح من المالك.
- المرجع المجمّد للمكتبة: الفرع `skills-full-106` والـSHA أعلاه.
- خادم MCP الوحيد المسجّل: `claude-video-vision` (في `.mcp.json`).
- الخطاف الوحيد: `suggest-compact.js` (PreToolUse على Edit/Write).
