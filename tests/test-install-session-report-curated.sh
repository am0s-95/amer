#!/usr/bin/env bash
# اختبار انحدار معزول لتركيب "Session Report Curated" عبر install-global-skills.sh.
# يعمل داخل HOME مؤقت معزول مع claude CLI وهمي (tests/fixtures/mock-claude-ponytail، عام
# ويصلح لأي Plugin/Marketplace) — لا شبكة، لا claude CLI حقيقي، ولا تعديل على مستودع amer نفسه.
# يغطي: صحة marketplace.json (المصدر محلي، سكيل واحدة فقط، بلا hooks/agents/mcpServers/
# lspServers)، صحة plugin.json الفعلي على القرص، تسجيل Marketplace مرة واحدة، تثبيت الـPlugin
# بـuser scope، idempotency التشغيل الثاني، عدم تثبيت session-report الأصلي غير المنقّح بالتوازي،
# بقاء Ponytail/Obsidian/MCP Server Dev Curated مثبتين، سلامة settings.json، عدد سكيلات المصدر
# (111)، قواعد التوجيه التلقائي الخاصة بـSession Report مرة واحدة، توثيق SHA/المصدر في
# PROVENANCE.md، واحترام SESSION_REPORT_CURATED_SKIP_INSTALL.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$REPO/scripts/install-global-skills.sh"
SRC="$REPO/.claude/skills"
MARKETPLACE_DIR="$REPO/.claude/marketplaces/skill-master-plugins"
MARKETPLACE_JSON="$MARKETPLACE_DIR/.claude-plugin/marketplace.json"
PLUGIN_DIR="$MARKETPLACE_DIR/plugins/session-report-curated"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
ROUTING_TEMPLATE="$REPO/.claude/templates/automatic-skill-routing.md"
PROVENANCE_FILE="$REPO/PROVENANCE.md"
MOCK_CLAUDE_DIR="$REPO/tests/fixtures/mock-claude-ponytail"

pass=0; fail=0
ok()  { pass=$((pass+1)); }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }
check(){ if eval "$1"; then ok; else bad "$2"; fi }
jget() { node -e "const v=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); let x=v; for (const k of process.argv.slice(2)) x=x==null?undefined:x[k]; console.log(x===undefined?'':x);" "$@"; }
plugin_idx() { node -e "
  const mp=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));
  const i=mp.plugins.findIndex(p=>p.name===process.argv[2]);
  console.log(i);
" "$1" "$2"; }

[ -x "$MOCK_CLAUDE_DIR/claude" ] || { echo "FAIL: claude الوهمي غير قابل للتنفيذ: $MOCK_CLAUDE_DIR/claude"; exit 1; }
[ -f "$MARKETPLACE_JSON" ] || { echo "FAIL: marketplace.json غير موجود: $MARKETPLACE_JSON"; exit 1; }

# ============================================================
# 1: marketplace.json صالح JSON، وplugin.json الفعلي على القرص صالح أيضًا
# ============================================================
check "node -e \"JSON.parse(require('fs').readFileSync('$MARKETPLACE_JSON','utf8'))\" >/dev/null 2>&1" "marketplace.json ليس JSON صالحًا"
check "[ -f \"$PLUGIN_JSON\" ]" "plugin.json غير موجود: $PLUGIN_JSON"
check "node -e \"JSON.parse(require('fs').readFileSync('$PLUGIN_JSON','utf8'))\" >/dev/null 2>&1" "plugin.json ليس JSON صالحًا"
if command -v claude >/dev/null 2>&1; then
  check "claude plugin validate \"$PLUGIN_DIR\" --strict >/dev/null 2>&1" "claude plugin validate فشل على plugin.json"
fi

# ============================================================
# 2: Plugin باسم session-report-curated موجود مرة واحدة بالضبط في marketplace.json
# ============================================================
n_sr="$(node -e "const mp=JSON.parse(require('fs').readFileSync('$MARKETPLACE_JSON','utf8')); console.log(mp.plugins.filter(p=>p.name==='session-report-curated').length)")"
check "[ \"$n_sr\" = \"1\" ]" "session-report-curated غير موجود مرة واحدة بالضبط في marketplace.json (العدد: $n_sr)"

PLUGIN_IDX="$(plugin_idx "$MARKETPLACE_JSON" session-report-curated)"
check "[ \"$PLUGIN_IDX\" != \"-1\" ]" "لم يُعثر على عنصر session-report-curated في مصفوفة plugins"

# ============================================================
# 3: المصدر محلي (نص مباشر، ليس git-subdir) ويشير إلى مجلد الـPlugin المُوَلَّد داخل الـMarketplace
# ============================================================
src_val="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source)"
check "[ \"$src_val\" = \"./plugins/session-report-curated\" ]" "source ليس ./plugins/session-report-curated (وجد: $src_val)"
check "[ -d \"$PLUGIN_DIR\" ]" "مجلد الـPlugin غير موجود عند المسار الذي يشير إليه source: $PLUGIN_DIR"

# ============================================================
# 4: سكيل واحدة فقط: session-report
# (ملاحظة: لا حقل "skills" صريح في عنصر marketplace.json هنا عمدًا — plugin.json المحلي +
# اصطلاح مجلد skills/ كافيان للاكتشاف. وجود الحقلين معًا (skills في marketplace + plugin.json
# مع اصطلاح skills/) يُنتج خطأ حقيقي "conflicting manifests: both plugin.json and marketplace
# entry specify components" مُكتشَف عبر اختبار التكامل الحقيقي — راجع PROVENANCE.md)
# ============================================================
has_skills_field="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX skills)"
check "[ -z \"$has_skills_field\" ]" "عنصر marketplace.json يحتوي حقل skills صريحًا — يسبب conflicting manifests مع plugin.json (راجع PROVENANCE.md)"
n_skill_dirs="$(find "$PLUGIN_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
check "[ \"$n_skill_dirs\" = \"1\" ]" "مجلد skills/ يحتوي أكثر من مجلد سكيل واحد (العدد: $n_skill_dirs)"
check "[ -f \"$PLUGIN_DIR/skills/session-report/SKILL.md\" ]" "SKILL.md غير موجود لسكيل session-report"
check "[ -f \"$PLUGIN_DIR/skills/session-report/analyze-sessions.mjs\" ]" "analyze-sessions.mjs غير موجود"
check "[ -f \"$PLUGIN_DIR/skills/session-report/template.html\" ]" "template.html غير موجود"

# ============================================================
# 5: لا hooks، لا agents، لا mcpServers، لا lspServers في تعريف الـPlugin (marketplace.json)
#    ولا في plugin.json نفسه
# ============================================================
for field in hooks agents mcpServers lspServers; do
  v="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX "$field")"
  check "[ -z \"$v\" ]" "تعريف الـPlugin في marketplace.json يحتوي حقل $field غير متوقع"
  v2="$(jget "$PLUGIN_JSON" "$field")"
  check "[ -z \"$v2\" ]" "plugin.json يحتوي حقل $field غير متوقع"
done
check "[ ! -d \"$PLUGIN_DIR/hooks\" ]" "مجلد hooks/ موجود داخل الـPlugin"
check "[ ! -d \"$PLUGIN_DIR/agents\" ]" "مجلد agents/ موجود داخل الـPlugin"

# ============================================================
# 6: النسخة الرسمية غير المنقّحة (session-report@claude-plugins-official) غير مُشار إليها في
#    السكربت كمصدر تثبيت فعلي
# ============================================================
check "! grep -q 'plugin install session-report@claude-plugins-official' \"$INSTALLER\"" "السكربت يستدعي تثبيت session-report@claude-plugins-official غير المنقّح"
check "! grep -q 'claude plugin install .*session-report@' \"$INSTALLER\" || grep -q 'session-report-curated@skill-master-plugins' \"$INSTALLER\"" "السكربت لا يشير إلى session-report-curated@skill-master-plugins"

# ============================================================
# التشغيل الأول: HOME مؤقت + claude وهمي، مع Plugins أخرى مُزروعة مسبقًا في حالة الـmock
# (لمحاكاة أن Ponytail/Obsidian/MCP Server Dev مثبّتة من قبل ويجب ألا تتأثر)
# ============================================================
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
export PATH="$MOCK_CLAUDE_DIR:$PATH"
export MOCK_CLAUDE_CALLS_FILE="$TMP/mock-claude-calls.log"
export TS_LSP_SKIP_INSTALL=1
export PYRIGHT_LSP_SKIP_INSTALL=1
export PONYTAIL_CURATED_SKIP_INSTALL=1
export OBSIDIAN_CURATED_SKIP_INSTALL=1
export MCP_SERVER_DEV_CURATED_SKIP_INSTALL=1
: > "$MOCK_CLAUDE_CALLS_FILE"

mkdir -p "$TMP/.claude"
cat > "$TMP/.claude/settings.json" <<'JSON'
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
SETTINGS_FILE="$TMP/.claude/settings.json"

# نزرع حالة mock-claude كأن Ponytail/Obsidian/MCP Server Dev مثبّتة مسبقًا (Marketplace مسجّل + الثلاثة مثبّتون)
cat > "$TMP/.mock-claude-state.json" <<JSON
{
  "marketplaces": [
    { "name": "skill-master-plugins", "source": "directory", "path": "$MARKETPLACE_DIR", "installLocation": "$MARKETPLACE_DIR", "_marketplaceJsonPath": "$MARKETPLACE_JSON" }
  ],
  "plugins": [
    { "id": "ponytail-curated@skill-master-plugins", "version": "4.8.4-skill-master.1", "scope": "user", "enabled": true, "installPath": "/mock/plugins/ponytail-curated@skill-master-plugins" },
    { "id": "obsidian-curated@skill-master-plugins", "version": "1.0.0-skill-master.1", "scope": "user", "enabled": true, "installPath": "/mock/plugins/obsidian-curated@skill-master-plugins" },
    { "id": "mcp-server-dev-curated@skill-master-plugins", "version": "0.1.0-skill-master.1", "scope": "user", "enabled": true, "installPath": "/mock/plugins/mcp-server-dev-curated@skill-master-plugins" }
  ]
}
JSON

git_status_before="$(git -C "$REPO" status --porcelain)"
out1="$("$INSTALLER" 2>&1)"
git_status_after="$(git -C "$REPO" status --porcelain)"
check "[ \"$git_status_before\" = \"$git_status_after\" ]" "تشغيل المثبّت عدّل حالة git لمستودع amer (قبل: [$git_status_before] بعد: [$git_status_after])"

mock_state="$TMP/.mock-claude-state.json"

# ============================================================
# 7: Marketplace مسجّل مسبقًا بنفس المصدر — لا يُعاد تسجيله (كان مزروعًا مسبقًا)
# ============================================================
n_mp_add="$(grep -c '^plugin marketplace add ' "$MOCK_CLAUDE_CALLS_FILE" || true)"
check "[ \"$n_mp_add\" = \"0\" ]" "أعاد المثبّت تسجيل Marketplace رغم أنه مزروع مسبقًا بنفس المسار (العدد: $n_mp_add)"

# ============================================================
# 8: المثبّت يثبت session-report-curated في user scope
# ============================================================
check "grep -qF 'plugin install session-report-curated@skill-master-plugins --scope user' \"$MOCK_CLAUDE_CALLS_FILE\"" "لم يُستدعَ plugin install session-report-curated@skill-master-plugins --scope user"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$mock_state','utf8')); const p=s.plugins.find(p=>p.id==='session-report-curated@skill-master-plugins'); process.exit(p&&p.scope==='user'?0:1)\"" "session-report-curated@skill-master-plugins ليس بـuser scope في حالة claude الوهمي"

# ============================================================
# 9: التشغيل الثاني idempotent — لا تكرار لـinstall، ولا update (النسخة لم تتغيّر)
# ============================================================
out2="$("$INSTALLER" 2>&1)"
n_install_sr_2="$(grep -c '^plugin install session-report-curated@skill-master-plugins' "$MOCK_CLAUDE_CALLS_FILE" || true)"
n_update_sr_2="$(grep -c '^plugin update session-report-curated@skill-master-plugins' "$MOCK_CLAUDE_CALLS_FILE" || true)"
check "[ \"$n_install_sr_2\" = \"1\" ]" "التشغيل الثاني كرّر plugin install لـsession-report-curated (العدد الكلي بعد تشغيلين: $n_install_sr_2)"
check "[ \"$n_update_sr_2\" = \"0\" ]" "التشغيل الثاني نفّذ plugin update لـsession-report-curated رغم أن النسخة لم تتغيّر (العدد: $n_update_sr_2)"
check "echo \"$out2\" | grep -qF 'مثبّت مسبقًا على النسخة المعتمدة'" "التشغيل الثاني لم يُبلغ أن Plugin مثبّت مسبقًا على النسخة المعتمدة"

# ============================================================
# 10: النسخة الرسمية غير المنقّحة (session-report@claude-plugins-official) غير مثبّتة فعليًا
# ============================================================
check "! grep -q 'session-report@claude-plugins-official' \"$MOCK_CLAUDE_CALLS_FILE\"" "وُجد استدعاء لـsession-report@claude-plugins-official (الإضافة الرسمية غير المنقّحة) في سجل claude الوهمي"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$mock_state','utf8')); process.exit(s.plugins.some(p=>p.id==='session-report@claude-plugins-official')?1:0)\"" "الإضافة الرسمية غير المنقّحة مثبّتة في حالة claude الوهمي"

# ============================================================
# 11: Ponytail/Obsidian/MCP Server Dev Curated (المزروعة مسبقًا) تبقى مثبّتة بلا تغيير
# ============================================================
for id in ponytail-curated@skill-master-plugins obsidian-curated@skill-master-plugins mcp-server-dev-curated@skill-master-plugins; do
  check "node -e \"const s=JSON.parse(require('fs').readFileSync('$mock_state','utf8')); process.exit(s.plugins.some(p=>p.id==='$id')?0:1)\"" "$id لم يعد مثبتًا في حالة claude الوهمي بعد تركيب Session Report Curated"
done

# ============================================================
# 12: settings.json — لا Hooks أو statusLine جديدة، والإعدادات السابقة سليمة
# ============================================================
check "node -e \"JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8'))\" >/dev/null 2>&1" "settings.json غير صالح بعد التركيب"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.hooks&&s.hooks.SessionStart)?1:0)\"" "settings.json يحتوي SessionStart جديد"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.hooks&&s.hooks.Stop)?1:0)\"" "settings.json يحتوي Stop hook جديد"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit(s.statusLine?1:0)\"" "settings.json يحتوي statusLine جديد"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.permissions&&s.permissions.allow&&s.permissions.allow[0]==='Bash(npm test:*)')?0:1)\"" "permissions.allow الأصلية اختفت أو تغيّرت"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.env&&s.env.MY_CUSTOM_VAR==='1')?0:1)\"" "env الأصلي اختفى بعد التركيب"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Edit'&&(m.hooks||[]).some(h=>h.command==='echo user-hook')); process.exit(has?0:1)\"" "hook مستخدم موجود مسبقًا على Edit حُذف"

# ============================================================
# 13: لا تُنشأ أي تقارير ولا تُقرأ transcripts أثناء الـbootstrap (لا مجلد reports/ ولا نشاط قراءة)
# ============================================================
check "[ ! -d \"$TMP/.claude/reports\" ]" "المثبّت أنشأ ~/.claude/reports أثناء الـbootstrap (يجب ألا يولّد تقارير عند التثبيت)"

# ============================================================
# 14: عدد Skills المصدرية في amer يبقى 111 (session-report-curated ليس ضمنها — Plugin منفصل)
# ============================================================
n_src="$(find "$SRC" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
check "[ \"$n_src\" -eq 111 ]" "عدد سكيلات المصدر في المستودع ليس 111 (وجد: $n_src)"

# ============================================================
# 15: قواعد Automatic Routing الخاصة بـSession Report موجودة مرة واحدة بالضبط في القالب
# ============================================================
check "[ -f \"$ROUTING_TEMPLATE\" ]" "قالب automatic-skill-routing.md غير موجود"
n_section="$(grep -cF '### Session report routing' "$ROUTING_TEMPLATE" || true)"
check "[ \"$n_section\" = \"1\" ]" "قسم Session report routing غير موجود مرة واحدة بالضبط (العدد: $n_section)"
for line in \
  "لا تشغّله تلقائيًا في SessionStart أو Stop." \
  "لا تشغّله بعد كل مهمة." \
  "الوضع الافتراضي يخفي نصوص prompts." \
  "لا تستخدم --include-prompts دون موافقة صريحة." \
  "لا تنشر أو ترفع التقرير تلقائيًا."
do
  n="$(grep -cF "$line" "$ROUTING_TEMPLATE" || true)"
  check "[ \"$n\" = \"1\" ]" "السطر غير موجود مرة واحدة بالضبط في قسم Session report routing (العدد: $n): $line"
done

# ============================================================
# 16: المصدر الرسمي (anthropics/claude-plugins-official) وSHA كامل (40 حرفًا) موثّقان في PROVENANCE.md
# ============================================================
check "[ -f \"$PROVENANCE_FILE\" ]" "PROVENANCE.md غير موجود"
check "grep -qF 'anthropics/claude-plugins-official' \"$PROVENANCE_FILE\"" "PROVENANCE.md لا يوثّق مستودع anthropics/claude-plugins-official"
check "grep -qF 'plugins/session-report' \"$PROVENANCE_FILE\"" "PROVENANCE.md لا يوثّق مسار plugins/session-report"
documented_sha="$(grep -oE '[0-9a-f]{40}' "$PROVENANCE_FILE" | head -1)"
check "[ -n \"$documented_sha\" ] && [ \"${#documented_sha}\" -eq 40 ]" "لا يوجد SHA كامل (40 حرفًا) موثّق في PROVENANCE.md"

echo ""
echo "النتيجة: نجح=$pass فشل=$fail"
[ "$fail" -eq 0 ]
