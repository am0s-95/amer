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

TMP="$(mktemp -d '/tmp/skills test.XXXXXX')"   # مسار فيه مسافة عمدًا
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
DEST="$TMP/.claude/skills"

# --- 1. التركيب الأولي ---
out1="$("$INSTALLER")"
n_src="$(find "$SRC" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
n_dest="$(find -L "$DEST" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
check "[ \"$n_dest\" = \"$n_src\" ]" "العدد بعد التركيب ($n_dest) لا يساوي المصدر ($n_src)"
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

echo ""
echo "النتيجة: نجح=$pass فشل=$fail"
[ "$fail" -eq 0 ]
