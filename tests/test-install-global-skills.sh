#!/usr/bin/env bash
# اختبار انحدار لسكربت التركيب العالمي install-global-skills.sh.
# يعمل داخل HOME مؤقت معزول — لا يلمس ~/.claude الحقيقي إطلاقًا.
# يغطي: التركيب، العدّ عبر الروابط، أمان --prune (يتيم مُدار فقط)،
# عدم الحذف بدون --prune، عدم الخلط بين مسار المستودع ومسار شبيه بالبادئة،
# الروابط النسبية، المسارات ذات المسافات، وثبات التشغيل الثاني.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$REPO/scripts/install-global-skills.sh"
SRC="$REPO/.claude/skills"
pass=0; fail=0
ok()   { pass=$((pass+1)); }
bad()  { fail=$((fail+1)); echo "FAIL: $1"; }
check(){ if eval "$1"; then ok; else bad "$2"; fi }
# يعدّ hooks مسجّلة على matcher معيّن تحتوي أمرها على needle، داخل ملف settings معطى.
count_hook() {
  node -e '
    const fs=require("fs");
    let s={};
    try { s=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); } catch { s={}; }
    const matcher=process.argv[2], needle=process.argv[3];
    let n=0;
    for (const m of (s.hooks && s.hooks.PreToolUse) || []) {
      if (m.matcher !== matcher) continue;
      for (const h of (m.hooks||[])) if (String(h.command||"").includes(needle)) n++;
    }
    console.log(n);
  ' "$1" "$2" "$3"
}

TMP="$(mktemp -d '/tmp/skills test.XXXXXX')"   # مسار فيه مسافة عمدًا
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
export TS_LSP_SKIP_INSTALL=1   # هذا الاختبار لا يغطي LSP — انظر test-install-typescript-lsp.sh
DEST="$TMP/.claude/skills"

# --- 1. التركيب الأولي ---
out1="$("$INSTALLER")"
n_src="$(find "$SRC" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
n_dest="$(find -L "$DEST" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
check "[ \"$n_dest\" = \"$n_src\" ]" "العدد بعد التركيب ($n_dest) لا يساوي المصدر ($n_src)"
check "[ \"$n_dest\" -eq 111 ]" "عدد السكيلات المثبتة عالميًا ليس 111 (وجد: $n_dest)"
check "[ -L \"$DEST/token-saver\" ]" "token-saver ليس رابطًا رمزيًا"

# --- 2. التشغيل الثاني لا يغيّر شيئًا ---
out2="$("$INSTALLER")"
check "echo \"$out2\" | grep -q 'جديد=0 محدّث=0'" "التشغيل الثاني غيّر روابط: $out2"

# --- 3. زرع الحالات ---
ln -s /opt "$DEST/foreign-link"                                   # أجنبي: يبقى دائمًا
mkdir -p "$DEST/real-user-skill"; echo x > "$DEST/real-user-skill/SKILL.md"  # مجلد حقيقي: يبقى
ln -s "$SRC/nonexistent-removed-skill" "$DEST/stale-managed"      # مُدار يتيم: يُحذف مع --prune فقط
mkdir -p "$TMP/decoy${SRC##*/}-old"                                # مسار شبيه بالبادئة
ln -s "${SRC}-old/some-skill" "$DEST/prefix-lookalike"            # بادئة شبيهة بلا '/': ليس مُدارًا → يبقى
ln -s "../relative/target" "$DEST/relative-link"                  # نسبي: ليس مُدارًا → يبقى

# --- 4. بدون --prune: لا حذف إطلاقًا ---
"$INSTALLER" >/dev/null
check "[ -L \"$DEST/stale-managed\" ]" "حذف اليتيم بدون --prune!"
check "[ -L \"$DEST/foreign-link\" ]" "حذف الرابط الأجنبي بدون --prune!"

# --- 5. مع --prune: اليتيم المُدار فقط ---
"$INSTALLER" --prune >/dev/null
check "[ ! -e \"$DEST/stale-managed\" ] && [ ! -L \"$DEST/stale-managed\" ]" "--prune لم يحذف اليتيم المُدار"
check "[ -L \"$DEST/foreign-link\" ]" "--prune حذف رابطًا أجنبيًا!"
check "[ -d \"$DEST/real-user-skill\" ]" "--prune حذف مجلد مستخدم حقيقيًا!"
check "[ -L \"$DEST/prefix-lookalike\" ]" "--prune خلط بين \$SRC و \${SRC}-old (بادئة شبيهة)!"
check "[ -L \"$DEST/relative-link\" ]" "--prune حذف رابطًا نسبيًا غير مُدار!"

# --- 6. الروابط المُدارة السليمة تبقى بعد --prune ---
check "[ -L \"$DEST/token-saver\" ] && [ -f \"$DEST/token-saver/SKILL.md\" ]" "رابط مُدار سليم اختفى بعد --prune"

# --- 7. سكيلات ECC الخمس تُكتشف وتُركّب (SKILL.md مقروء عبر الرابط) ---
for s in documentation-lookup database-migrations deployment-patterns mcp-server-patterns deep-research; do
  check "[ -L \"$DEST/$s\" ] && [ -f \"$DEST/$s/SKILL.md\" ]" "سكيل ECC غير مركّبة أو رابطها مكسور: $s"
done

# --- 8. بلوك التوجيه المُدار في CLAUDE.md: موجود مرة واحدة بالضبط ---
CMD_FILE="$TMP/.claude/CLAUDE.md"
count_begin() { grep -cF '<!-- BEGIN MANAGED: automatic-skill-routing -->' "$CMD_FILE"; }
check "[ -f \"$CMD_FILE\" ] && [ \"$(count_begin)\" = \"1\" ]" "البلوك المُدار غير موجود أو مكرر بعد التركيب"

# --- 9. إعادة التشغيل لا تكرر البلوك ولا تمس نص المستخدم ---
printf '\n## قاعدة مستخدم يدوية\nلا تحذفني.\n' >> "$CMD_FILE"
"$INSTALLER" >/dev/null
check "[ \"$(count_begin)\" = \"1\" ]" "إعادة التشغيل كررت البلوك المُدار"
check "grep -q 'لا تحذفني' \"$CMD_FILE\"" "إعادة التشغيل مسحت نص المستخدم في CLAUDE.md"
check "grep -qF '<!-- END MANAGED: automatic-skill-routing -->' \"$CMD_FILE\"" "علامة END اختفت بعد إعادة التشغيل"

# --- 10. BEGIN بلا END: المثبّت يحذّر ولا يلمس الملف ---
printf '%s\n' '<!-- BEGIN MANAGED: automatic-skill-routing -->' > "$CMD_FILE"
printf 'نص المستخدم بعد علامة ناقصة\n' >> "$CMD_FILE"
before_broken="$(cat "$CMD_FILE")"
"$INSTALLER" >/dev/null
after_broken="$(cat "$CMD_FILE")"
check '[ "$before_broken" = "$after_broken" ]' "المثبّت عدّل ملفًا بعلامات ناقصة بدل التحذير"

# --- 11. الحُرّاس العالميان: النسخ، مطابقة المصدر، وتبعيات suggest-compact.js ---
GUARD_SRC="$REPO/.claude/scripts/hooks/guard-dangerous.js"
COMPACT_SRC="$REPO/.claude/scripts/hooks/suggest-compact.js"
GUARD_DEST="$TMP/.claude/hooks/guard-dangerous.js"
COMPACT_DEST="$TMP/.claude/hooks/suggest-compact.js"
check "[ -f \"$GUARD_DEST\" ]" "guard-dangerous.js لم يُنسخ عالميًا"
check "[ -f \"$COMPACT_DEST\" ]" "suggest-compact.js لم يُنسخ عالميًا"
check "diff -q \"$GUARD_SRC\" \"$GUARD_DEST\" >/dev/null" "guard-dangerous.js العالمي لا يطابق مصدر المستودع"
check "diff -q \"$COMPACT_SRC\" \"$COMPACT_DEST\" >/dev/null" "suggest-compact.js العالمي لا يطابق مصدر المستودع"
check "[ -f \"$TMP/.claude/lib/utils.js\" ] && [ -f \"$TMP/.claude/lib/transcript-context.js\" ] && [ -f \"$TMP/.claude/lib/agent-data-home.js\" ]" "تبعيات suggest-compact.js (../lib) لم تُنسخ عالميًا — سيفشل بـ Cannot find module"

# --- 12. settings.json صالح، والحُرّاس الثلاثة مسجّلون مرة واحدة بالضبط بعد كل التشغيلات أعلاه ---
SETTINGS_FILE="$TMP/.claude/settings.json"
check "node -e \"JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8'))\" >/dev/null 2>&1" "settings.json غير صالح JSON"
n_bash="$(count_hook "$SETTINGS_FILE" Bash guard-dangerous.js)"
n_edit="$(count_hook "$SETTINGS_FILE" Edit suggest-compact.js)"
n_write="$(count_hook "$SETTINGS_FILE" Write suggest-compact.js)"
check "[ \"$n_bash\" = \"1\" ]" "guard-dangerous غير مسجل مرة واحدة بالضبط على Bash (وجد: $n_bash)"
check "[ \"$n_edit\" = \"1\" ]" "suggest-compact غير مسجل مرة واحدة بالضبط على Edit (وجد: $n_edit)"
check "[ \"$n_write\" = \"1\" ]" "suggest-compact غير مسجل مرة واحدة بالضبط على Write (وجد: $n_write)"

# --- 13. HOME معزول جديد ببيانات مسبقة: تشغيل مرتين لا يكرر hook ولا يحذف الموجود ---
TMP2="$(mktemp -d)"
trap 'rm -rf "$TMP" "$TMP2"' EXIT
mkdir -p "$TMP2/.claude"
cat > "$TMP2/.claude/settings.json" <<'JSON'
{
  "permissions": { "allow": ["Bash(npm test:*)"] },
  "env": { "MY_CUSTOM_VAR": "1" },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit", "hooks": [ { "type": "command", "command": "echo user-hook" } ] }
    ]
  }
}
JSON
HOME="$TMP2" "$INSTALLER" >/dev/null
HOME="$TMP2" "$INSTALLER" >/dev/null
S2="$TMP2/.claude/settings.json"
check "node -e \"JSON.parse(require('fs').readFileSync('$S2','utf8'))\" >/dev/null 2>&1" "settings.json (اختبار الحفظ) غير صالح بعد التركيب"
n_bash2="$(count_hook "$S2" Bash guard-dangerous.js)"
n_edit2="$(count_hook "$S2" Edit suggest-compact.js)"
n_write2="$(count_hook "$S2" Write suggest-compact.js)"
check "[ \"$n_bash2\" = \"1\" ]" "guard-dangerous تكرر أو لم يُسجّل بعد تشغيلين على HOME معزول (وجد: $n_bash2)"
check "[ \"$n_edit2\" = \"1\" ]" "suggest-compact/Edit تكرر أو لم يُسجّل بعد تشغيلين على HOME معزول (وجد: $n_edit2)"
check "[ \"$n_write2\" = \"1\" ]" "suggest-compact/Write تكرر أو لم يُسجّل بعد تشغيلين على HOME معزول (وجد: $n_write2)"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$S2','utf8')); process.exit((s.permissions&&s.permissions.allow&&s.permissions.allow[0]==='Bash(npm test:*)')?0:1)\"" "permissions الأصلية اختفت بعد التركيب"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$S2','utf8')); process.exit((s.env&&s.env.MY_CUSTOM_VAR==='1')?0:1)\"" "env الأصلي اختفى بعد التركيب"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$S2','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Edit'&&(m.hooks||[]).some(h=>h.command==='echo user-hook')); process.exit(has?0:1)\"" "hook مستخدم موجود مسبقًا على Edit حُذف"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$S2','utf8')); process.exit((s.hooks&&s.hooks.SessionStart)?1:0)\"" "المثبّت أضاف SessionStart غير متوقع لتشغيل نفسه تلقائيًا"

# --- 14. اختبار وظيفي: تشغيل النسخة العالمية المثبتة فعليًا من suggest-compact.js على مدخل Write آمن ---
REAL_TMPDIR="$(node -e 'console.log(require("os").tmpdir())')"
SC_SESSION="test-install-global-skills-$$"
SC_COUNTER_FILE="$REAL_TMPDIR/claude-tool-count-${SC_SESSION}"
SC_BUCKET_FILE="$REAL_TMPDIR/claude-context-bucket-${SC_SESSION}"
rm -f "$SC_COUNTER_FILE" "$SC_BUCKET_FILE"
sc_payload() { node -e 'console.log(JSON.stringify({tool_name:"Write",tool_input:{file_path:"/tmp/example.txt",content:"hi"},session_id:process.argv[1]}))' "$SC_SESSION"; }
sc_payload | node "$COMPACT_DEST" >/dev/null 2>&1
check "[ -f \"$SC_COUNTER_FILE\" ]" "suggest-compact المثبّت عالميًا لم ينشئ ملف claude-tool-count (تبعيات lib ناقصة؟)"
check "[ \"$(cat "$SC_COUNTER_FILE" 2>/dev/null)\" = \"1\" ]" "عدّاد claude-tool-count لم يبدأ من 1"
sc_payload | node "$COMPACT_DEST" >/dev/null 2>&1
check "[ \"$(cat "$SC_COUNTER_FILE" 2>/dev/null)\" = \"2\" ]" "عدّاد claude-tool-count لم يزد إلى 2 بعد استدعاء ثانٍ"
rm -f "$SC_COUNTER_FILE" "$SC_BUCKET_FILE"

echo ""
echo "النتيجة: نجح=$pass فشل=$fail"
[ "$fail" -eq 0 ]
