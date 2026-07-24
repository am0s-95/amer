#!/usr/bin/env bash
# اختبار انحدار معزول لتركيب "MCP Server Dev Curated" عبر install-global-skills.sh.
# يعمل داخل HOME مؤقت معزول مع claude CLI وهمي (tests/fixtures/mock-claude-ponytail، عام
# ويصلح لأي Plugin/Marketplace) — لا شبكة، لا npm، لا لمس لـ~/.claude الحقيقي، ولا تعديل على
# مستودع amer نفسه.
# يغطي: صحة marketplace.json (المصدر git-subdir، path=plugins/mcp-server-dev، ref=main، sha
# الكامل، السكيلات الثلاث فقط: build-mcp-server/build-mcp-app/build-mcpb، بلا
# hooks/agents/mcpServers/lspServers)، تسجيل Marketplace مرة واحدة، تثبيت الـPlugin بـuser
# scope، idempotency التشغيل الثاني، عدم تثبيت mcp-server-dev الأصلي غير المنقّح بالتوازي،
# بقاء Ponytail Curated وObsidian Curated مثبتين، سلامة settings.json (بلا Hooks أو statusLine
# جديدة)، وTypeScript/Pyright، عدد سكيلات المصدر (111)، قواعد التوجيه التلقائي الخاصة بـMCP
# development مرة واحدة، وتوثيق reference files في PROVENANCE.md.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$REPO/scripts/install-global-skills.sh"
SRC="$REPO/.claude/skills"
MARKETPLACE_DIR="$REPO/.claude/marketplaces/skill-master-plugins"
MARKETPLACE_JSON="$MARKETPLACE_DIR/.claude-plugin/marketplace.json"
ROUTING_TEMPLATE="$REPO/.claude/templates/automatic-skill-routing.md"
PROVENANCE_FILE="$REPO/PROVENANCE.md"
MOCK_CLAUDE_DIR="$REPO/tests/fixtures/mock-claude-ponytail"
EXPECTED_SHA="66799ffb4611b7e0c3af391c7569823a4d6b4246"
EXPECTED_SKILLS='build-mcp-server,build-mcp-app,build-mcpb'

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
# 1: marketplace.json صالح JSON
# ============================================================
check "node -e \"JSON.parse(require('fs').readFileSync('$MARKETPLACE_JSON','utf8'))\" >/dev/null 2>&1" "marketplace.json ليس JSON صالحًا"

# ============================================================
# 2: Plugin باسم mcp-server-dev-curated موجود مرة واحدة بالضبط
# ============================================================
n_mcp="$(node -e "const mp=JSON.parse(require('fs').readFileSync('$MARKETPLACE_JSON','utf8')); console.log(mp.plugins.filter(p=>p.name==='mcp-server-dev-curated').length)")"
check "[ \"$n_mcp\" = \"1\" ]" "mcp-server-dev-curated غير موجود مرة واحدة بالضبط في marketplace.json (العدد: $n_mcp)"

PLUGIN_IDX="$(plugin_idx "$MARKETPLACE_JSON" mcp-server-dev-curated)"
check "[ \"$PLUGIN_IDX\" != \"-1\" ]" "لم يُعثر على عنصر mcp-server-dev-curated في مصفوفة plugins"

# ============================================================
# 3: المصدر من نوع git-subdir
# ============================================================
src_type="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source source)"
check "[ \"$src_type\" = \"git-subdir\" ]" "نوع المصدر ليس git-subdir (وجد: $src_type)"

# ============================================================
# 4: url يطابق المستودع الرسمي
# ============================================================
src_url="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source url)"
check "[ \"$src_url\" = \"https://github.com/anthropics/claude-plugins-official.git\" ]" "رابط المصدر غير صحيح (وجد: $src_url)"

# ============================================================
# 5: path يساوي plugins/mcp-server-dev/skills (لا plugins/mcp-server-dev نفسه — تضمين
#    .claude-plugin/plugin.json الأصلي مع حقل skills صريح في marketplace.json يُنتج تعارضًا
#    حقيقيًا في Skill discovery: "conflicting manifests: both plugin.json and marketplace
#    entry specify components" — مكتشَف عبر اختبار التكامل الحقيقي، راجع PROVENANCE.md)
# ============================================================
src_path="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source path)"
check "[ \"$src_path\" = \"plugins/mcp-server-dev/skills\" ]" "path المصدر ليس plugins/mcp-server-dev/skills (وجد: $src_path)"

# ============================================================
# 6: sha كامل من 40 حرفًا ويطابق القيمة المتحقَّق منها
# ============================================================
src_sha="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source sha)"
check "[ \"$src_sha\" = \"$EXPECTED_SHA\" ]" "sha المصدر لا يطابق المطلوب (وجد: $src_sha)"
check "[ \"${#src_sha}\" -eq 40 ]" "sha المصدر ليس 40 حرفًا (الطول: ${#src_sha})"

# ============================================================
# 7-10: السكيلات الثلاث فقط موجودة (لا أكثر ولا أقل، ولا تكرار)، وكل واحدة منها موجودة بالاسم
# ============================================================
skills_json_line="$(node -e "
  const mp = JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));
  const list = mp.plugins[Number(process.argv[2])].skills || [];
  console.log(list.map(s=>s.replace(/^\.\/(skills\/)?/,'')).sort().join(','));
" "$MARKETPLACE_JSON" "$PLUGIN_IDX")"
expected_sorted="$(printf '%s\n' "${EXPECTED_SKILLS//,/$'\n'}" | sort | paste -sd, -)"
check "[ \"$skills_json_line\" = \"$expected_sorted\" ]" "قائمة skills في marketplace.json لا تطابق السكيلات الثلاث المتوقعة (وجد: $skills_json_line)"
check "[ $(node -e "console.log((JSON.parse(require('fs').readFileSync('$MARKETPLACE_JSON','utf8')).plugins[Number(process.argv[1])].skills||[]).length)" "$PLUGIN_IDX") -eq 3 ]" "عدد عناصر skills في marketplace.json ليس 3 بالضبط"
check "echo \"$skills_json_line\" | tr ',' '\n' | grep -qx 'build-mcp-server'" "build-mcp-server غير موجود ضمن قائمة skills"
check "echo \"$skills_json_line\" | tr ',' '\n' | grep -qx 'build-mcp-app'" "build-mcp-app غير موجود ضمن قائمة skills"
check "echo \"$skills_json_line\" | tr ',' '\n' | grep -qx 'build-mcpb'" "build-mcpb غير موجود ضمن قائمة skills"

# ============================================================
# 11-14: لا hooks، لا agents، لا mcpServers، لا lspServers في تعريف الـPlugin
# ============================================================
has_hooks="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX hooks)"
check "[ -z \"$has_hooks\" ]" "تعريف الـPlugin يحتوي حقل hooks غير متوقع"
has_agents="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX agents)"
check "[ -z \"$has_agents\" ]" "تعريف الـPlugin يحتوي حقل agents غير متوقع"
has_mcp="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX mcpServers)"
check "[ -z \"$has_mcp\" ]" "تعريف الـPlugin يحتوي حقل mcpServers غير متوقع"
has_lsp="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX lspServers)"
check "[ -z \"$has_lsp\" ]" "تعريف الـPlugin يحتوي حقل lspServers غير متوقع"

# ============================================================
# التشغيل الأول: HOME مؤقت + claude وهمي (يثبّت Ponytail وObsidian وmcp-server-dev-curated معًا)
# ============================================================
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
export PATH="$MOCK_CLAUDE_DIR:$PATH"
export MOCK_CLAUDE_CALLS_FILE="$TMP/mock-claude-calls.log"
export TS_LSP_SKIP_INSTALL=1
export PYRIGHT_LSP_SKIP_INSTALL=1
export SESSION_REPORT_CURATED_SKIP_INSTALL=1   # هذا الاختبار لا يغطي Session Report — انظر test-install-session-report-curated.sh
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

git_status_before="$(git -C "$REPO" status --porcelain)"
out1="$("$INSTALLER" 2>&1)"
git_status_after="$(git -C "$REPO" status --porcelain)"
check "[ \"$git_status_before\" = \"$git_status_after\" ]" "تشغيل المثبّت عدّل حالة git لمستودع amer (قبل: [$git_status_before] بعد: [$git_status_after])"

# ============================================================
# 15: المثبّت يضيف Marketplace مرة واحدة بالضبط
# ============================================================
n_mp_add="$(grep -c '^plugin marketplace add ' "$MOCK_CLAUDE_CALLS_FILE" || true)"
check "[ \"$n_mp_add\" = \"1\" ]" "استدعاء plugin marketplace add لم يحدث مرة واحدة بالضبط في التشغيل الأول (العدد: $n_mp_add)"
check "grep -qF \"plugin marketplace add $MARKETPLACE_DIR\" \"$MOCK_CLAUDE_CALLS_FILE\"" "استدعاء marketplace add لا يشير إلى مسار skill-master-plugins داخل المستودع"

# ============================================================
# 16: المثبّت يثبت الـPlugin في user scope
# ============================================================
check "grep -qF 'plugin install mcp-server-dev-curated@skill-master-plugins --scope user' \"$MOCK_CLAUDE_CALLS_FILE\"" "لم يُستدعَ plugin install mcp-server-dev-curated@skill-master-plugins --scope user"

# ============================================================
# التشغيل الثاني: idempotency — لا تكرار لـadd/install لـmcp-server-dev-curated
# ============================================================
out2="$("$INSTALLER" 2>&1)"
n_mp_add_2="$(grep -c '^plugin marketplace add ' "$MOCK_CLAUDE_CALLS_FILE" || true)"
n_install_mcp_2="$(grep -c '^plugin install mcp-server-dev-curated@skill-master-plugins' "$MOCK_CLAUDE_CALLS_FILE" || true)"
n_update_mcp_2="$(grep -c '^plugin update mcp-server-dev-curated@skill-master-plugins' "$MOCK_CLAUDE_CALLS_FILE" || true)"
check "[ \"$n_mp_add_2\" = \"1\" ]" "التشغيل الثاني كرّر plugin marketplace add (العدد الكلي بعد تشغيلين: $n_mp_add_2)"
check "[ \"$n_install_mcp_2\" = \"1\" ]" "التشغيل الثاني كرّر plugin install لـmcp-server-dev-curated (العدد الكلي بعد تشغيلين: $n_install_mcp_2)"
check "[ \"$n_update_mcp_2\" = \"0\" ]" "التشغيل الثاني نفّذ plugin update لـmcp-server-dev-curated رغم أن النسخة لم تتغيّر (العدد: $n_update_mcp_2)"
check "echo \"$out2\" | grep -qF 'MCP Server Dev Curated: Marketplace (skill-master-plugins) مسجّل مسبقًا بنفس المصدر'" "التشغيل الثاني لم يُبلغ أن Marketplace مسجّل مسبقًا (MCP Server Dev Curated)"
check "echo \"$out2\" | grep -qF 'مثبّت مسبقًا على النسخة المعتمدة'" "التشغيل الثاني لم يُبلغ أن Plugin مثبّت مسبقًا على النسخة المعتمدة"

# ============================================================
# 17-18: idempotency + الإضافة الرسمية غير المنقّحة (mcp-server-dev@claude-plugins-official)
#         لا تُثبت بالتوازي في أي مكان
# ============================================================
check "! grep -q 'mcp-server-dev@claude-plugins-official' \"$MOCK_CLAUDE_CALLS_FILE\"" "وُجد استدعاء لـmcp-server-dev@claude-plugins-official (الإضافة الرسمية غير المنقّحة) في سجل claude الوهمي"
mock_state="$TMP/.mock-claude-state.json"
check "[ -f \"$mock_state\" ]" "ملف حالة claude الوهمي غير موجود"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$mock_state','utf8')); process.exit(s.plugins.some(p=>p.id==='mcp-server-dev@claude-plugins-official')?1:0)\"" "الإضافة الرسمية غير المنقّحة مثبّتة في حالة claude الوهمي"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$mock_state','utf8')); process.exit(s.plugins.some(p=>p.id==='mcp-server-dev-curated@skill-master-plugins')?0:1)\"" "mcp-server-dev-curated@skill-master-plugins ليس ضمن الـPlugins المثبتة"

# ============================================================
# 19: Ponytail Curated وObsidian Curated يبقيان مثبتين (نفس التشغيل يثبت الثلاثة معًا)
# ============================================================
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$mock_state','utf8')); process.exit(s.plugins.some(p=>p.id==='ponytail-curated@skill-master-plugins')?0:1)\"" "ponytail-curated@skill-master-plugins لم يعد مثبتًا في حالة claude الوهمي"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$mock_state','utf8')); process.exit(s.plugins.some(p=>p.id==='obsidian-curated@skill-master-plugins')?0:1)\"" "obsidian-curated@skill-master-plugins لم يعد مثبتًا في حالة claude الوهمي"

# ============================================================
# 20-22: settings.json — لا Hooks أو statusLine جديدة، والحُرّاس والإعدادات السابقة سليمة
# ============================================================
check "node -e \"JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8'))\" >/dev/null 2>&1" "settings.json غير صالح بعد التركيب"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.hooks&&s.hooks.SessionStart)?1:0)\"" "settings.json يحتوي SessionStart جديد"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.hooks&&s.hooks.SubagentStart)?1:0)\"" "settings.json يحتوي SubagentStart جديد"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.hooks&&s.hooks.UserPromptSubmit)?1:0)\"" "settings.json يحتوي UserPromptSubmit جديد"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit(s.statusLine?1:0)\"" "settings.json يحتوي statusLine جديد"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.permissions&&s.permissions.allow&&s.permissions.allow[0]==='Bash(npm test:*)')?0:1)\"" "permissions.allow الأصلية اختفت أو تغيّرت"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.env&&s.env.MY_CUSTOM_VAR==='1')?0:1)\"" "env الأصلي اختفى بعد التركيب"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Edit'&&(m.hooks||[]).some(h=>h.command==='echo user-hook')); process.exit(has?0:1)\"" "hook مستخدم موجود مسبقًا على Edit حُذف"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Bash'&&(m.hooks||[]).some(h=>String(h.command||'').includes('guard-dangerous.js'))); process.exit(has?0:1)\"" "guard-dangerous لم يُسجّل"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='mcp__github__.*'&&(m.hooks||[]).some(h=>String(h.command||'').includes('guard-github-mcp.js'))); process.exit(has?0:1)\"" "guard-github-mcp لم يُسجّل"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Write'&&(m.hooks||[]).some(h=>String(h.command||'').includes('suggest-compact.js'))); process.exit(has?0:1)\"" "suggest-compact على Write لم يُسجّل"

# ============================================================
# 23: TypeScript وPyright يبقيان سليمين (تخطّيناهما هنا بـSKIP_INSTALL لعزل الاختبار عن npm/الشبكة —
#     يُغطّيان فعليًا في test-install-typescript-lsp.sh وtest-install-pyright-lsp.sh)
# ============================================================
check "[ ! -e \"$TMP/.claude/skills/typescript-lsp-global\" ]" "TS_LSP_SKIP_INSTALL لم يُحترم (typescript-lsp-global أُنشئ رغم التخطي)"
check "[ ! -e \"$TMP/.claude/skills/pyright-lsp-global\" ]" "PYRIGHT_LSP_SKIP_INSTALL لم يُحترم (pyright-lsp-global أُنشئ رغم التخطي)"

# ============================================================
# 24: عدد Skills المصدرية في amer يبقى 111 (mcp-server-dev-curated ليس ضمنها — Plugin بعيد المصدر)
# ============================================================
n_src="$(find "$SRC" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
check "[ \"$n_src\" -eq 111 ]" "عدد سكيلات المصدر في المستودع ليس 111 (وجد: $n_src)"

# ============================================================
# 25: قواعد Automatic Routing الخاصة بـMCP development موجودة مرة واحدة بالضبط في القالب
# ============================================================
check "[ -f \"$ROUTING_TEMPLATE\" ]" "قالب automatic-skill-routing.md غير موجود"
n_section="$(grep -cF '### MCP development routing' "$ROUTING_TEMPLATE" || true)"
check "[ \"$n_section\" = \"1\" ]" "قسم MCP development routing غير موجود مرة واحدة بالضبط (العدد: $n_section)"
for line in \
  "استخدم build-mcp-server تلقائيًا عندما يطلب المستخدم:" \
  "build-mcp-server هو نقطة الدخول الأساسية." \
  "استخدم build-mcp-app فقط عندما يحتاج MCP:" \
  "استخدم build-mcpb فقط عندما يجب أن يعمل الخادم على جهاز المستخدم أو يصل" \
  "استخدم mcp-server-patterns كمرجع معماري داعم، وليس Workflow كاملًا موازيًا." \
  "لا تشغّل build-mcp-server وmcp-server-patterns كمسارين كاملين مكررين."
do
  n="$(grep -cF "$line" "$ROUTING_TEMPLATE" || true)"
  check "[ \"$n\" = \"1\" ]" "السطر غير موجود مرة واحدة بالضبط في قسم MCP development routing (العدد: $n): $line"
done

# ============================================================
# 26: reference files الخاصة بالمهارات الثلاث موثّقة في PROVENANCE.md ولا تُفقد من التوثيق
#     (القراءة الفعلية من القرص بعد تثبيت حقيقي مغطاة في اختبار التكامل الحقيقي، وليس هنا)
# ============================================================
check "[ -f \"$PROVENANCE_FILE\" ]" "PROVENANCE.md غير موجود"
for ref in \
  "auth.md" "deploy-cloudflare-workers.md" "elicitation.md" "remote-http-scaffold.md" \
  "resources-and-prompts.md" "server-capabilities.md" "tool-design.md" "versions.md" \
  "abuse-protection.md" "apps-sdk-messages.md" "directory-checklist.md" "iframe-sandbox.md" \
  "payload-budgeting.md" "widget-templates.md" \
  "local-security.md" "manifest-schema.md"
do
  check "grep -qF \"$ref\" \"$PROVENANCE_FILE\"" "ملف مرجعي غير موثّق في PROVENANCE.md: $ref"
done

echo ""
echo "النتيجة: نجح=$pass فشل=$fail"
[ "$fail" -eq 0 ]
