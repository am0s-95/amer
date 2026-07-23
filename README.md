# amer

مكتبة سكيلات Claude Code (111 سكيل — انظر `PROFILES.md` للتنظيم و`PROVENANCE.md` لمصادر المستورد منها) مع مثبّت عالمي وحارس للأفعال الخطرة.

## التركيب

```bash
./scripts/install-global-skills.sh            # تركيب/تحديث الروابط + الحارس + بلوك التوجيه
./scripts/install-global-skills.sh --prune    # + حذف الروابط اليتيمة المُدارة فقط
./scripts/install-global-skills.sh --copy     # نسخ بدل الروابط
```

المثبّت idempotent ويقوم بثلاثة أشياء:

1. **السكيلات**: symlinks من `.claude/skills/*` إلى `~/.claude/skills/`.
2. **الحارس**: ينسخ `guard-dangerous.js` إلى `~/.claude/hooks/` ويسجّله في `~/.claude/settings.json` (دمج آمن — لا يستبدل الملف).
3. **التوجيه التلقائي**: يزامن البلوك المُدار `automatic-skill-routing` (من `.claude/templates/`) داخل `~/.claude/CLAUDE.md` — يحدّث ما بين العلامتين فقط ولا يمس نص المستخدم.

## الاختبارات

```bash
bash tests/test-install-global-skills.sh   # المثبّت: التركيب، --prune، الـidempotency، البلوك المُدار
bash tests/test-guard-dangerous.sh         # الحارس: خطرة مباشرة/مغلّفة، آمنة، fail-safe
bash tests/test-project-skill-routing.sh   # توجيه السكيلات على مستوى المشروع + ميزانية القائمة
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
  لتركيب السكيلات والحارس وبلوك التوجيه عالميًا في `~/.claude`. هذا التثبيت العالمي **لا ينتقل تلقائيًا** من بيئة سحابية إلى جهاز آخر أو العكس — كل بيئة تُركَّب فيها بشكل مستقل عند الحاجة.
