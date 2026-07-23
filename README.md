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
```
