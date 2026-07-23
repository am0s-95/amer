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
