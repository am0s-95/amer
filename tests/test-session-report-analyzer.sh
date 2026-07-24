#!/usr/bin/env bash
# اختبار وحدة معزول لـanalyze-sessions.mjs (النسخة المنقّحة داخل session-report-curated).
# يستخدم fixtures صناعية صغيرة فقط (لا transcripts حقيقية إطلاقًا) داخل HOME/CLAUDE_CONFIG_DIR
# مؤقتين. يغطي: احترام CLAUDE_CONFIG_DIR، أولوية --dir، معالجة المجلد المفقود بأمان، الفترات
# الزمنية (24h/7d/30d/all)، إخفاء prompts افتراضيًا (context=null، text=[redacted])،
# --include-prompts، صحة JSON، الخصوصية metadata، dedup الطلبات المكررة، عدم تسرّب نص
# البرومبتات في السجلات (stderr/stdout) بالوضع الافتراضي، وHTML قالب self-contained بلا CDN.
#
# ملاحظة تصميم: كل ناتج JSON يُكتب إلى ملف مؤقت ثم يُقرأ عبر fs.readFileSync — تمرير JSON خامًا
# كوسيطة shell (عبر eval) يكسر بسبب علامات التنصيص الداخلية.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$REPO/.claude/marketplaces/skill-master-plugins/plugins/session-report-curated/skills/session-report"
SCRIPT="$SKILL_DIR/analyze-sessions.mjs"
TEMPLATE="$SKILL_DIR/template.html"

pass=0; fail=0
ok()  { pass=$((pass+1)); }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }
check(){ if eval "$1"; then ok; else bad "$2"; fi }
jfield() { node -e "const j=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); let x=j; for (const k of process.argv.slice(2)) x=x==null?undefined:x[k]; console.log(x===undefined?'<<undefined>>':(typeof x==='object'?JSON.stringify(x):x));" "$@"; }
valid_json() { node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$1" >/dev/null 2>&1; }

[ -f "$SCRIPT" ] || { echo "FAIL: analyze-sessions.mjs غير موجود: $SCRIPT"; exit 1; }
[ -f "$TEMPLATE" ] || { echo "FAIL: template.html غير موجود: $TEMPLATE"; exit 1; }

check "node --check \"$SCRIPT\" >/dev/null 2>&1" "analyze-sessions.mjs لا يمر syntax check"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FIXTURE_HOME="$TMP/home"
ALT_DIR="$TMP/alt-projects"
SECRET="سر-اختباري-فريد-لا-يجب-أن-يظهر-9f3ac2"

mkdir -p "$FIXTURE_HOME/.claude/projects/proj-a"
NOW="$(node -e 'console.log(new Date().toISOString())')"
# جلسة أولى: برومبت بشري واحد يحتوي السر، ثم استدعاء API واحد (طلب مقسّم على قطعتين
# بنفس requestId — لاختبار dedup: يجب أن يُحتسب مرة واحدة بأعلى output_tokens)
cat > "$FIXTURE_HOME/.claude/projects/proj-a/session1.jsonl" <<EOF
{"uuid":"u1","type":"user","timestamp":"$NOW","isSidechain":false,"message":{"content":"$SECRET"}}
{"uuid":"u2","type":"assistant","timestamp":"$NOW","requestId":"req1","message":{"id":"msg_01aaa","usage":{"input_tokens":100,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":10}}}
{"uuid":"u3","type":"assistant","timestamp":"$NOW","requestId":"req1","message":{"id":"msg_01aaa","usage":{"input_tokens":100,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":50}}}
EOF
# سطر jsonl تالف عمدًا — يجب أن يُتخطّى بصمت بلا انهيار
printf 'this is not valid json\n' >> "$FIXTURE_HOME/.claude/projects/proj-a/session1.jsonl"

# ============================================================
# 1: المجلد المفقود يُعالج بأمان (لا انهيار، لا stack trace، JSON صالح، exit 0)
# ============================================================
CLAUDE_CONFIG_DIR="$TMP/does-not-exist" HOME="/nonexistent-home-$$" node "$SCRIPT" --json --since 7d \
  >"$TMP/missing-out.json" 2>"$TMP/missing-stderr.log"
missing_rc=$?
check "[ \"$missing_rc\" -eq 0 ]" "exit code ليس 0 عند مجلد transcripts مفقود (وجد: $missing_rc)"
check "! grep -qi 'Error:' \"$TMP/missing-stderr.log\"" "stack trace/خطأ غير متوقع في stderr عند مجلد مفقود"
check "valid_json \"$TMP/missing-out.json\"" "الناتج ليس JSON صالحًا عند مجلد transcripts مفقود"
check "[ \"$(jfield "$TMP/missing-out.json" overall sessions)\" = \"0\" ]" "sessions ليست 0 عند مجلد مفقود"
check "grep -qi 'transcripts' \"$TMP/missing-stderr.log\"" "لا توجد رسالة واضحة على stderr عند مجلد transcripts مفقود"

# ============================================================
# 2: CLAUDE_CONFIG_DIR محترم (config_dir/root يشيران إلى fixture)
# ============================================================
CLAUDE_CONFIG_DIR="$FIXTURE_HOME/.claude" HOME="/nonexistent-home-$$" node "$SCRIPT" --json --since all \
  >"$TMP/default-out.json" 2>"$TMP/default-stderr.log"
check "valid_json \"$TMP/default-out.json\"" "الناتج الافتراضي ليس JSON صالحًا"
config_dir_val="$(jfield "$TMP/default-out.json" config_dir)"
root_val="$(jfield "$TMP/default-out.json" root)"
check "[ \"$config_dir_val\" = \"$FIXTURE_HOME/.claude\" ]" "config_dir لا يطابق CLAUDE_CONFIG_DIR (وجد: $config_dir_val)"
check "[ \"$root_val\" = \"$FIXTURE_HOME/.claude/projects\" ]" "root لا يطابق CLAUDE_CONFIG_DIR/projects (وجد: $root_val)"
check "[ \"$(jfield "$TMP/default-out.json" overall sessions)\" = \"1\" ]" "لم يُكتشف session واحد من fixture (root)"

# ============================================================
# 3: --dir له أولوية على CLAUDE_CONFIG_DIR
# ============================================================
mkdir -p "$ALT_DIR/proj-b"
cp "$FIXTURE_HOME/.claude/projects/proj-a/session1.jsonl" "$ALT_DIR/proj-b/session1.jsonl"
CLAUDE_CONFIG_DIR="$TMP/should-be-ignored" HOME="/nonexistent-home-$$" node "$SCRIPT" --json --since all --dir "$ALT_DIR" \
  >"$TMP/dirflag-out.json" 2>/dev/null
root_dirflag="$(jfield "$TMP/dirflag-out.json" root)"
check "[ \"$root_dirflag\" = \"$ALT_DIR\" ]" "--dir لم يتغلّب على CLAUDE_CONFIG_DIR (وجد root: $root_dirflag)"

# ============================================================
# 4-6: الوضع الافتراضي يخفي prompts (text=[redacted]، context=null)، وmetadata الخصوصية صحيحة
# ============================================================
text_val="$(jfield "$TMP/default-out.json" top_prompts 0 text)"
ctx_val="$(jfield "$TMP/default-out.json" top_prompts 0 context)"
check "[ \"$text_val\" = \"[redacted]\" ]" "top_prompts[0].text ليس [redacted] بالوضع الافتراضي (وجد: $text_val)"
check "[ \"$ctx_val\" = \"null\" ]" "top_prompts[0].context ليس null بالوضع الافتراضي (وجد: $ctx_val)"
prompts_included="$(jfield "$TMP/default-out.json" privacy prompts_included)"
local_only="$(jfield "$TMP/default-out.json" privacy local_only)"
check "[ \"$prompts_included\" = \"false\" ]" "privacy.prompts_included ليست false افتراضيًا (وجد: $prompts_included)"
check "[ \"$local_only\" = \"true\" ]" "privacy.local_only ليست true (وجد: $local_only)"
check "! grep -qF \"$SECRET\" \"$TMP/default-stderr.log\"" "نص السر تسرّب إلى stderr بالوضع الافتراضي"
check "! grep -qF \"$SECRET\" \"$TMP/default-out.json\"" "نص السر تسرّب إلى stdout/JSON بالوضع الافتراضي"

# ============================================================
# 7: --include-prompts يعيد النص الحقيقي (فقط عند الطلب الصريح) + تحذير على stderr
# ============================================================
CLAUDE_CONFIG_DIR="$FIXTURE_HOME/.claude" HOME="/nonexistent-home-$$" node "$SCRIPT" --json --since all --include-prompts \
  >"$TMP/included-out.json" 2>"$TMP/included-stderr.log"
text_included="$(jfield "$TMP/included-out.json" top_prompts 0 text)"
check "grep -qF \"$SECRET\" \"$TMP/included-out.json\"" "--include-prompts لم يُظهر النص الحقيقي (وجد: $text_included)"
check "grep -qi 'include-prompts' \"$TMP/included-stderr.log\"" "لا يوجد تحذير واضح على stderr عند --include-prompts"
prompts_included2="$(jfield "$TMP/included-out.json" privacy prompts_included)"
check "[ \"$prompts_included2\" = \"true\" ]" "privacy.prompts_included ليست true مع --include-prompts (وجد: $prompts_included2)"

# ============================================================
# 8: config_dir/root/generated_at/requested_since موجودة في الناتج
# ============================================================
for field in config_dir root generated_at requested_since privacy; do
  v="$(jfield "$TMP/default-out.json" "$field")"
  check "[ \"$v\" != \"<<undefined>>\" ]" "الحقل $field غير موجود في ناتج JSON"
done
gen_at="$(jfield "$TMP/default-out.json" generated_at)"
check "node -e \"process.exit(isNaN(Date.parse(process.argv[1]))?1:0)\" \"$gen_at\"" "generated_at ليس تاريخ ISO صالحًا (وجد: $gen_at)"

# ============================================================
# 9: الفترات الزمنية 24h و7d و30d وall تعمل بلا انهيار وتُنتج JSON صالح
# ============================================================
for since in 24h 7d 30d all; do
  CLAUDE_CONFIG_DIR="$FIXTURE_HOME/.claude" HOME="/nonexistent-home-$$" node "$SCRIPT" --json --since "$since" \
    >"$TMP/since-$since.json" 2>/dev/null
  rc=$?
  check "[ \"$rc\" -eq 0 ]" "--since $since أنهى بخطأ (exit: $rc)"
  check "valid_json \"$TMP/since-$since.json\"" "--since $since لم ينتج JSON صالحًا"
done
req_since_val="$(jfield "$TMP/since-24h.json" requested_since)"
check "[ \"$req_since_val\" = \"24h\" ]" "requested_since لا يطابق قيمة --since الممرَّرة (وجد: $req_since_val)"

# ============================================================
# 10: dedup — الطلب المقسّم على قطعتين بنفس requestId يُحتسب مرة واحدة بأعلى output_tokens
# ============================================================
api_calls="$(jfield "$TMP/default-out.json" overall api_calls)"
output_tokens="$(jfield "$TMP/default-out.json" overall output_tokens)"
check "[ \"$api_calls\" = \"1\" ]" "dedup فشل: api_calls ليست 1 لطلب واحد مقسّم على قطعتين (وجد: $api_calls)"
check "[ \"$output_tokens\" = \"50\" ]" "dedup فشل: output_tokens ليست 50 (الأعلى بين القطعتين) (وجد: $output_tokens)"

# ============================================================
# 11: السطر التالف (jsonl غير صالح) لم يُسقط العملية — تحقّقنا أعلاه أن الناتج JSON صالح رغم وجوده
# ============================================================
check "true" "(مُتحقَّق ضمنيًا: الفحوصات أعلاه نجحت رغم سطر jsonl تالف في fixture)"

# ============================================================
# 12: template.html — self-contained: بلا روابط CDN أو network خارجية
# ============================================================
check "! grep -qiE 'https?://|<script src=' \"$TEMPLATE\"" "template.html يحتوي رابط شبكة خارجي (CDN أو <script src>)"
check "grep -qF '<script id=\"report-data\"' \"$TEMPLATE\"" "template.html لا يحتوي عنصر #report-data لتضمين JSON"

# ============================================================
# 13: لا استيرادات شبكة في المحلل (فحص ساكن — fs/os/path/readline فقط)
# ============================================================
check "! grep -qE \"require\\('(https?|net|dgram)'\\)|from '(https?|net|dgram)'\" \"$SCRIPT\"" "analyze-sessions.mjs يستورد وحدة شبكة (http/https/net/dgram)"

echo ""
echo "النتيجة: نجح=$pass فشل=$fail"
[ "$fail" -eq 0 ]
