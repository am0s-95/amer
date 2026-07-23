#!/usr/bin/env bash
# اختبار انحدار لتوجيه السكيلات التلقائي على مستوى المشروع (بدون لمس HOME الحقيقي).
# يتحقق من: استيراد القالب في CLAUDE.md، وجود القالب، صلاحية settings.json،
# قيمة skillListingBudgetFraction، بقاء hooks الحالية، وعدد السكيلات.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_MD="$REPO/CLAUDE.md"
SETTINGS="$REPO/.claude/settings.json"
TEMPLATE="$REPO/.claude/templates/automatic-skill-routing.md"
IMPORT_LINE='@.claude/templates/automatic-skill-routing.md'
pass=0; fail=0
ok()  { pass=$((pass+1)); }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }

# --- 1. سطر الاستيراد موجود في CLAUDE.md مرة واحدة بالضبط ---
count_import="$(grep -cF "$IMPORT_LINE" "$CLAUDE_MD" 2>/dev/null || echo 0)"
if [ "$count_import" = "1" ]; then ok; else bad "سطر استيراد قالب التوجيه غير موجود مرة واحدة بالضبط في CLAUDE.md (العدد: $count_import)"; fi

# --- 2. ملف القالب المستورد موجود ---
if [ -f "$TEMPLATE" ]; then ok; else bad "ملف القالب $TEMPLATE غير موجود"; fi

# --- 3. settings.json صالح JSON ---
if node -e "JSON.parse(require('fs').readFileSync('$SETTINGS','utf8'))" 2>/dev/null; then ok; else bad "settings.json ليس JSON صالحًا"; fi

# --- 4. skillListingBudgetFraction تساوي 0.03 بالضبط ---
budget="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$SETTINGS','utf8')).skillListingBudgetFraction)" 2>/dev/null)"
if [ "$budget" = "0.03" ]; then ok; else bad "skillListingBudgetFraction ليست 0.03 (القيمة الفعلية: $budget)"; fi

# --- 5. guard-dangerous مسجّل مرة واحدة بالضبط ---
count_guard="$(grep -c 'guard-dangerous' "$SETTINGS")"
if [ "$count_guard" = "1" ]; then ok; else bad "guard-dangerous غير مسجّل مرة واحدة بالضبط (العدد: $count_guard)"; fi

# --- 6. suggest-compact مسجّل على Edit وWrite (مرتين) ---
count_compact="$(grep -c 'suggest-compact' "$SETTINGS")"
if [ "$count_compact" = "2" ]; then ok; else bad "suggest-compact غير مسجّل على Edit وWrite (العدد: $count_compact)"; fi

# --- 7. لا يوجد SessionStart hook يشغّل install-global-skills.sh ---
if node -e "
const s = JSON.parse(require('fs').readFileSync('$SETTINGS','utf8'));
const hooks = s.hooks || {};
if (hooks.SessionStart) process.exit(1);
const text = JSON.stringify(s);
if (text.includes('install-global-skills.sh')) process.exit(1);
process.exit(0);
" 2>/dev/null; then ok; else bad "يوجد SessionStart hook أو إشارة لتشغيل install-global-skills.sh داخل settings.json"; fi

# --- 8. عدد سكيلات المشروع ما زال 111 ---
n_skills="$(find "$REPO/.claude/skills" -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
if [ "$n_skills" = "111" ]; then ok; else bad "عدد ملفات .claude/skills/*/SKILL.md ليس 111 (العدد: $n_skills)"; fi

# --- 9. env.SLASH_COMMAND_TOOL_CHAR_BUDGET تساوي النص "90000" ---
char_budget="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$SETTINGS','utf8')).env && JSON.parse(require('fs').readFileSync('$SETTINGS','utf8')).env.SLASH_COMMAND_TOOL_CHAR_BUDGET)" 2>/dev/null)"
if [ "$char_budget" = "90000" ]; then ok; else bad "env.SLASH_COMMAND_TOOL_CHAR_BUDGET ليست \"90000\" (القيمة الفعلية: $char_budget)"; fi

echo ""
echo "النتيجة: نجح=$pass فشل=$fail"
[ "$fail" -eq 0 ]
