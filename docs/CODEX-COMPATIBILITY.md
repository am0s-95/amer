# فحص توافق amer مع Codex وChatGPT Work

تاريخ الفحص: 2026-09-05. المصدر المثبّت: [eb8f64fd655214971ec5eb6e4d73ea60aa9bd454](https://github.com/am0s-95/amer/tree/eb8f64fd655214971ec5eb6e4d73ea60aa9bd454).

## النتيجة وحدود الفحص

المكتبة قابلة للاستفادة منها كتعليمات وموارد منتقاة. ليست حزمة تشغيل متوافقة بالكامل بمجرد ربط GitHub.
أضيف AGENTS.md كجسر تعليمات داخل المستودع؛ لا يثبّت السكيلات عالميًا، ولا يسجّل Hooks أو MCP أو LSP، ولا يغيّر إعدادات حساب ChatGPT.

حُصرت شجرة المستودع (959 ملفًا)، وجُلبت النصوص الكاملة لكل ملفات SKILL.md المباشرة الـ111 وفُحصت آليًا لمؤشرات الاعتماديات.
قُرئت إعدادات Claude والتوجيه والحارسان وسكربت ضغط السياق وإعداد MCP وتعريف marketplace، وفُحصت مواضع التثبيت في المثبّت.
هذا فحص توافق بنيوي ومراجعة موجهة، وليس مراجعة سطرية لكل الملفات الـ959 أو اختبارًا سلوكيًا للسكيلات الـ111.
لم تُشغّل خدمات خارجية أو المثبّت أو اختبارات المكتبة الأصلية، ولم يُثبت تشغيل تلقائي في محادثة جديدة.

## ما يمكن استخدامه وما يحتاج تكييفًا

| المكوّن | الحالة العملية |
|---|---|
| إرشادات البرمجة والمراجعة والتصحيح | تُقرأ عند الحاجة مع مواردها؛ أمثلة: systematic-debugging وapi-designer وcode-reviewer. أدوات التنفيذ ومتطلبات المشروع تُفحص في المهمة الفعلية. |
| تعليمات المشروع | AGENTS.md يحدد طريقة الاستفادة داخل مستودع مفتوح في Codex. في جلسة تستخدم موصل GitHub فقط، يجب قراءة الملف صراحة؛ الوصول للمستودع ليس تحميلًا تلقائيًا للتعليمات. |
| الحُرّاس | guard-dangerous.js يتحقق من tool_name = Bash؛ guard-github-mcp.js يتحقق من بادئة mcp__github__. أدوات جلسة Work المفحوصة تستخدم أسماء مختلفة. كما أن JSON الناتج مخصص لـPreToolUse في Claude. تغيير الاسم وحده ليس تكامل إنفاذ. |
| ضغط السياق | suggest-compact.js يقرأ transcript_path وسجلات usage الخاصة بالجلسة؛ ليس مقياسًا مثبتًا لسياق ChatGPT. لا نقل آلي لأمر /compact. |
| الذاكرة وتقارير الاستخدام | ck وcontinuous-learning-v2 وsession-report مرتبطة بمسارات/سجلات Claude؛ تحتاج تصميم تخزين وتحقق من مخطط السجلات للبيئة المستهدفة. لا وصول تلقائي لتاريخ حساب المستخدم. |
| البحث والتوثيق | documentation-lookup يحتاج Context7؛ deep-research يتطلب Exa أو Firecrawl. وجود الاسم في ملف لا يثبت اتصال الخادم. يمكن استخدام وسيلة متاحة بديلة للمهمة مع التصريح بذلك. |
| الفيديو | watch يذكر مسارات Codex وطريقة مستقلة لتحديد SKILL_DIR، لكنه يحتاج أدوات مثل ffmpeg وyt-dlp، وقد يحتاج خدمة تفريغ صوتي. video-perception يحتاج خادم claude-video-vision. |
| التصميم | ui-ux-pro-max يستخدم CLAUDE_PLUGIN_ROOT في الأوامر. banner-design يشير إلى ai-artist وai-multimodal وchrome-devtools غير الموجودة كمهارات مباشرة في هذه المكتبة؛ قد توجد في بيئة أخرى، ولم يُتحقق منها هنا. |
| إضافات LSP وmarketplace | تعريفات Claude وأوامر claude plugin تحتاج آلية تكامل مع البيئة المستهدفة. لا يثبت نسخها تفعيل التشخيصات داخل Codex. |
| سياسة الاستدعاء | deploy-to-vercel مقفلة في المصدر بـdisable-model-invocation: true؛ يجب الحفاظ على قصد الاستدعاء الصريح عند أي تغليف، والتحقق من آلية المنصة المستهدفة. |

## ملاحظات اتساق مؤكدة

- نهاية PROFILES.md تقول إن خادم MCP الوحيد هو claude-video-vision؛ لكن .mcp.json يسجّل claude-video-vision وcontext7.
- الملف نفسه يقول إن الخطاف الوحيد suggest-compact.js؛ لكن إعداد المشروع يسجّل guard-dangerous.js أيضًا. المثبّت العالمي يسجّل guard-github-mcp.js كذلك؛ يجب التمييز بين إعداد المشروع والتركيب العالمي.
- عدد 111 صحيح للمجلدات المباشرة تحت .claude/skills. الـmarketplace يعرّف إضافات أخرى: Ponytail (6)، Obsidian (3)، MCP Server Dev (3)، وsession-report محلي. ليست جميعها نصوصًا مضمنة ضمن الـ111، ولا يثبت هذا الفحص تركيبها في جهاز المستخدم.
- بعض أسماء frontmatter تختلف عن المجلد، مثل composition-patterns / vercel-composition-patterns. التكييف يحتاج الحفاظ على الربط الفعلي.
- عدم العثور على مؤشر نصي لا يعني توافق السكيل أو اكتمال اعتمادياتها.

## كيفية الاستفادة الآن

داخل هذا الفرع، اقرأ AGENTS.md ثم اختر السكيل المناسب من PROFILES.md وافتحه وموارده المطلوبة. يمكن تطبيق الإرشادات في جلسة Work التي تصل إلى الملفات، مع أدواتها المتاحة.
في Codex الذي يفتح المستودع، AGENTS.md هو مدخل تعليمات المشروع. لا يلزم تشغيل كمبيوتر المستخدم لفحص الملفات أو إعداد هذا الفرع.

للتثبيت القابل للاكتشاف خارج هذا المستودع، يلزم تغليف/استيراد مدعوم، وفحص الاعتماديات والتعارضات والتراخيص للمهارات المختارة، ثم التحقق في جلسة جديدة.
توثيق OpenAI يوضح [تعليمات AGENTS.md](https://developers.openai.com/codex/agent-configuration/agents-md)، و[بناء السكيلات وتوزيعها كإضافات](https://developers.openai.com/codex/build-skills)، و[استيراد إعدادات وكيل آخر](https://developers.openai.com/codex/import).
مسار الاستيراد الموثق يشمل تطبيق سطح المكتب وCodex CLI؛ لا يُفترض أن ملفات جهاز مطفأ قابلة للوصول من الهاتف.

## جرد ملفات السكيلات الـ111

مؤشرات آلية مستخرجة من نص SKILL.md نفسه، وليست أحكام نجاح/فشل. قد تكون الإشارة ضمن مثال أو وصف؛ يجب مراجعة السياق قبل التكييف.
الموارد التابعة وسكربتاتها لم تُختبر جميعًا. الإضافات الخارجية في marketplace خارج هذا الجدول.

| مجلد السكيل | مؤشرات تستدعي مراجعة عند النقل |
|---|---|
| [agent-introspection-debugging](../.claude/skills/agent-introspection-debugging/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [agent-self-evaluation](../.claude/skills/agent-self-evaluation/SKILL.md) | hook/session references |
| [agent-sort](../.claude/skills/agent-sort/SKILL.md) | Claude paths/runtime; MCP/tool references |
| [ai-regression-testing](../.claude/skills/ai-regression-testing/SKILL.md) | mentions Codex/cross-agent use |
| [api-designer](../.claude/skills/api-designer/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [architecture-decision-records](../.claude/skills/architecture-decision-records/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [banner-design](../.claude/skills/banner-design/SKILL.md) | Claude paths/runtime |
| [brainstorming](../.claude/skills/brainstorming/SKILL.md) | MCP/tool references |
| [brand](../.claude/skills/brand/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [browser-qa](../.claude/skills/browser-qa/SKILL.md) | MCP/tool references |
| [ck](../.claude/skills/ck/SKILL.md) | Claude paths/runtime; hook/session references |
| [claude-code-tools-guide](../.claude/skills/claude-code-tools-guide/SKILL.md) | MCP/tool references |
| [click-path-audit](../.claude/skills/click-path-audit/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [cloud-architect](../.claude/skills/cloud-architect/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [code-reviewer](../.claude/skills/code-reviewer/SKILL.md) | Claude tool metadata |
| [code-tour](../.claude/skills/code-tour/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [codebase-onboarding](../.claude/skills/codebase-onboarding/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [composition-patterns](../.claude/skills/composition-patterns/SKILL.md) | frontmatter name: vercel-composition-patterns |
| [config-gc](../.claude/skills/config-gc/SKILL.md) | Claude paths/runtime; MCP/tool references |
| [configure-ecc](../.claude/skills/configure-ecc/SKILL.md) | Claude paths/runtime; MCP/tool references; mentions Codex/cross-agent use |
| [context-budget](../.claude/skills/context-budget/SKILL.md) | MCP/tool references; mentions Codex/cross-agent use |
| [continuous-learning-v2](../.claude/skills/continuous-learning-v2/SKILL.md) | Claude paths/runtime; hook/session references |
| [council](../.claude/skills/council/SKILL.md) | Claude paths/runtime |
| [database-migrations](../.claude/skills/database-migrations/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [database-optimizer](../.claude/skills/database-optimizer/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [debugging-wizard](../.claude/skills/debugging-wizard/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [deep-research](../.claude/skills/deep-research/SKILL.md) | Claude paths/runtime; MCP/tool references; mentions Codex/cross-agent use |
| [defuddle](../.claude/skills/defuddle/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [delivery-gate](../.claude/skills/delivery-gate/SKILL.md) | Claude paths/runtime; hook/session references |
| [deploy-to-vercel](../.claude/skills/deploy-to-vercel/SKILL.md) | explicit-only policy must be preserved; Claude paths/runtime; mentions Codex/cross-agent use |
| [deployment-patterns](../.claude/skills/deployment-patterns/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [design-system](../.claude/skills/design-system/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [design](../.claude/skills/design/SKILL.md) | Claude paths/runtime; MCP/tool references |
| [devops-engineer](../.claude/skills/devops-engineer/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [dispatching-parallel-agents](../.claude/skills/dispatching-parallel-agents/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [documentation-lookup](../.claude/skills/documentation-lookup/SKILL.md) | MCP/tool references; mentions Codex/cross-agent use |
| [ecc-guide](../.claude/skills/ecc-guide/SKILL.md) | mentions Codex/cross-agent use |
| [ecc-recipes](../.claude/skills/ecc-recipes/SKILL.md) | hook/session references |
| [error-handling](../.claude/skills/error-handling/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [eval-harness](../.claude/skills/eval-harness/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [executing-plans](../.claude/skills/executing-plans/SKILL.md) | mentions Codex/cross-agent use |
| [fastapi-expert](../.claude/skills/fastapi-expert/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [find-skills](../.claude/skills/find-skills/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [finishing-a-development-branch](../.claude/skills/finishing-a-development-branch/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [frontend-design](../.claude/skills/frontend-design/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [fullstack-guardian](../.claude/skills/fullstack-guardian/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [git-workflow](../.claude/skills/git-workflow/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [graphql-architect](../.claude/skills/graphql-architect/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [growth-log](../.claude/skills/growth-log/SKILL.md) | hook/session references |
| [hookify-rules](../.claude/skills/hookify-rules/SKILL.md) | hook/session references |
| [inherit-legacy-style](../.claude/skills/inherit-legacy-style/SKILL.md) | Claude tool metadata; hook/session references |
| [intent-driven-development](../.claude/skills/intent-driven-development/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [iterative-retrieval](../.claude/skills/iterative-retrieval/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [javascript-pro](../.claude/skills/javascript-pro/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [loop-design-check](../.claude/skills/loop-design-check/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [mcp-server-patterns](../.claude/skills/mcp-server-patterns/SKILL.md) | MCP/tool references |
| [microservices-architect](../.claude/skills/microservices-architect/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [monitoring-expert](../.claude/skills/monitoring-expert/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [nestjs-expert](../.claude/skills/nestjs-expert/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [nextjs-developer](../.claude/skills/nextjs-developer/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [plan-canvas](../.claude/skills/plan-canvas/SKILL.md) | Claude paths/runtime; mentions Codex/cross-agent use |
| [playwright-expert](../.claude/skills/playwright-expert/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [postgres-pro](../.claude/skills/postgres-pro/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [product-lens](../.claude/skills/product-lens/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [production-audit](../.claude/skills/production-audit/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [react-best-practices](../.claude/skills/react-best-practices/SKILL.md) | frontmatter name: vercel-react-best-practices |
| [react-expert](../.claude/skills/react-expert/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [react-view-transitions](../.claude/skills/react-view-transitions/SKILL.md) | frontmatter name: vercel-react-view-transitions |
| [receiving-code-review](../.claude/skills/receiving-code-review/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [repo-scan](../.claude/skills/repo-scan/SKILL.md) | Claude paths/runtime |
| [requesting-code-review](../.claude/skills/requesting-code-review/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [rules-distill](../.claude/skills/rules-distill/SKILL.md) | Claude paths/runtime |
| [santa-method](../.claude/skills/santa-method/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [secure-code-guardian](../.claude/skills/secure-code-guardian/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [seo-audit](../.claude/skills/seo-audit/SKILL.md) | MCP/tool references |
| [seo-content](../.claude/skills/seo-content/SKILL.md) | MCP/tool references |
| [seo-geo](../.claude/skills/seo-geo/SKILL.md) | MCP/tool references |
| [seo-page](../.claude/skills/seo-page/SKILL.md) | MCP/tool references |
| [seo-schema](../.claude/skills/seo-schema/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [seo-sitemap](../.claude/skills/seo-sitemap/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [seo-technical](../.claude/skills/seo-technical/SKILL.md) | MCP/tool references |
| [seo](../.claude/skills/seo/SKILL.md) | MCP/tool references |
| [shopify-expert](../.claude/skills/shopify-expert/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [skill-scout](../.claude/skills/skill-scout/SKILL.md) | Claude paths/runtime |
| [skill-stocktake](../.claude/skills/skill-stocktake/SKILL.md) | explicit-only policy must be preserved; Claude paths/runtime |
| [slides](../.claude/skills/slides/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [strategic-compact](../.claude/skills/strategic-compact/SKILL.md) | Claude paths/runtime; MCP/tool references; hook/session references; compaction command |
| [subagent-driven-development](../.claude/skills/subagent-driven-development/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [systematic-debugging](../.claude/skills/systematic-debugging/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [test-driven-development](../.claude/skills/test-driven-development/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [test-master](../.claude/skills/test-master/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [token-saver](../.claude/skills/token-saver/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [typescript-pro](../.claude/skills/typescript-pro/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [ui-styling](../.claude/skills/ui-styling/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [ui-ux-pro-max](../.claude/skills/ui-ux-pro-max/SKILL.md) | Claude paths/runtime |
| [using-git-worktrees](../.claude/skills/using-git-worktrees/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [using-superpowers](../.claude/skills/using-superpowers/SKILL.md) | mentions Codex/cross-agent use |
| [vercel-optimize](../.claude/skills/vercel-optimize/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [verification-before-completion](../.claude/skills/verification-before-completion/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [verification-loop](../.claude/skills/verification-loop/SKILL.md) | hook/session references |
| [video-perception](../.claude/skills/video-perception/SKILL.md) | MCP/tool references |
| [vue-expert](../.claude/skills/vue-expert/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [watch](../.claude/skills/watch/SKILL.md) | Claude tool metadata; Claude paths/runtime; mentions Codex/cross-agent use |
| [web-artifacts-builder](../.claude/skills/web-artifacts-builder/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [web-design-guidelines](../.claude/skills/web-design-guidelines/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [webapp-testing](../.claude/skills/webapp-testing/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [websocket-engineer](../.claude/skills/websocket-engineer/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [wordpress-pro](../.claude/skills/wordpress-pro/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [writing-guidelines](../.claude/skills/writing-guidelines/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [writing-plans](../.claude/skills/writing-plans/SKILL.md) | No selected marker found; dependencies still need task-specific review |
| [writing-skills](../.claude/skills/writing-skills/SKILL.md) | No selected marker found; dependencies still need task-specific review |
