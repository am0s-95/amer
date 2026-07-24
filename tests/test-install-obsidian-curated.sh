#!/usr/bin/env bash
# اختبار انحدار معزول لتركيب "Obsidian Curated" عبر install-global-skills.sh.
# يعمل داخل HOME مؤقت معزول مع claude CLI وهمي (tests/fixtures/mock-claude-ponytail، عام
# ويصلح لأي Plugin/Marketplace) — لا شبكة، لا npm (obsidian-curated لا يحتاج تشغيل زمني)،
# لا لمس لـ~/.claude الحقيقي، ولا تعديل على مستودع amer نفسه.
# يغطي: صحة marketplace.json (المصدر git-subdir، path=skills، ref=main، sha الكامل، السكيلات
# الثلاث فقط، بلا hooks/mcpServers/agents/lspServers)، تسجيل Marketplace مرة واحدة، تثبيت
# الـPlugin بـuser scope، idempotency التشغيل الثاني، عدم تثبيت obsidian الأصلي الكامل أو
# obsidian-cli أو defuddle، بقاء Ponytail Curated مثبتًا، سلامة settings.json (بلا Hooks أو
# statusLine جديدة) وTypeScript/Pyright، عدد سكيلات المصدر (111)، قواعد التوجيه التلقائي
# الخاصة بـObsidian مرة واحدة، وفحوصات fixture لحالتي Vault وغير-Vault.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$REPO/scripts/install-global-skills.sh"
SRC="$REPO/.claude/skills"
MARKETPLACE_DIR="$REPO/.claude/marketplaces/skill-master-plugins"
MARKETPLACE_JSON="$MARKETPLACE_DIR/.claude-plugin/marketplace.json"
ROUTING_TEMPLATE="$REPO/.claude/templates/automatic-skill-routing.md"
MOCK_CLAUDE_DIR="$REPO/tests/fixtures/mock-claude-ponytail"
FIXTURES_DIR="$REPO/tests/fixtures/obsidian-routing"
EXPECTED_SHA="a1dc48e68138490d522c04cbf5822214c6eb1202"
EXPECTED_SKILLS='obsidian-markdown,obsidian-bases,json-canvas'

pass=0; fail=0
ok()  { pass=$((pass+1)); }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }
check(){ if eval "$1"; then ok; else bad "$2"; fi }
jget() { node -e "const v=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); let x=v; for (const k of process.argv.slice(2)) x=x==null?undefined:x[k]; console.log(x===undefined?'':x);" "$@"; }
# يجد فهرس عنصر بالاسم داخل مصفوفة plugins في marketplace.json
plugin_idx() { node -e "
  const mp=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));
  const i=mp.plugins.findIndex(p=>p.name===process.argv[2]);
  console.log(i);
" "$1" "$2"; }

[ -x "$MOCK_CLAUDE_DIR/claude" ] || { echo "FAIL: claude الوهمي غير قابل للتنفيذ: $MOCK_CLAUDE_DIR/claude"; exit 1; }
[ -f "$MARKETPLACE_JSON" ] || { echo "FAIL: marketplace.json غير موجود: $MARKETPLACE_JSON"; exit 1; }

# ============================================================
# 1-12: صحة marketplace.json نفسه (ملف المستودع الحقيقي — بلا HOME مؤقت)
# ============================================================

# 1. marketplace.json صالح JSON
check "node -e \"JSON.parse(require('fs').readFileSync('$MARKETPLACE_JSON','utf8'))\" >/dev/null 2>&1" "marketplace.json ليس JSON صالحًا"

# 2. Plugin باسم obsidian-curated موجود مرة واحدة بالضبط
n_obsidian="$(node -e "const mp=JSON.parse(require('fs').readFileSync('$MARKETPLACE_JSON','utf8')); console.log(mp.plugins.filter(p=>p.name==='obsidian-curated').length)")"
check "[ \"$n_obsidian\" = \"1\" ]" "obsidian-curated غير موجود مرة واحدة بالضبط في marketplace.json (العدد: $n_obsidian)"

PLUGIN_IDX="$(plugin_idx "$MARKETPLACE_JSON" obsidian-curated)"
check "[ \"$PLUGIN_IDX\" != \"-1\" ]" "لم يُعثر على عنصر obsidian-curated في مصفوفة plugins"

# 3. المصدر من نوع git-subdir
src_type="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source source)"
check "[ \"$src_type\" = \"git-subdir\" ]" "نوع المصدر ليس git-subdir (وجد: $src_type)"

# 4. url يطابق المستودع الرسمي
src_url="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source url)"
check "[ \"$src_url\" = \"https://github.com/kepano/obsidian-skills.git\" ]" "رابط المصدر غير صحيح (وجد: $src_url)"

# 5. path يساوي skills
src_path="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source path)"
check "[ \"$src_path\" = \"skills\" ]" "path المصدر ليس skills (وجد: $src_path)"

# 6. sha كامل من 40 حرفًا ويطابق القيمة المتحقَّق منها
src_sha="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source sha)"
check "[ \"$src_sha\" = \"$EXPECTED_SHA\" ]" "sha المصدر لا يطابق المطلوب (وجد: $src_sha)"
check "[ \"${#src_sha}\" -eq 40 ]" "sha المصدر ليس 40 حرفًا (الطول: ${#src_sha})"

# 7. السكيلات الثلاث فقط موجودة (لا أكثر ولا أقل، ولا تكرار)
skills_json_line="$(node -e "
  const mp = JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));
  const list = mp.plugins[Number(process.argv[2])].skills || [];
  console.log(list.map(s=>s.replace(/^\.\//,'')).sort().join(','));
" "$MARKETPLACE_JSON" "$PLUGIN_IDX")"
expected_sorted="$(printf '%s\n' "${EXPECTED_SKILLS//,/$'\n'}" | sort | paste -sd, -)"
check "[ \"$skills_json_line\" = \"$expected_sorted\" ]" "قائمة skills في marketplace.json لا تطابق السكيلات الثلاث المتوقعة (وجد: $skills_json_line)"
check "[ $(node -e "console.log((JSON.parse(require('fs').readFileSync('$MARKETPLACE_JSON','utf8')).plugins[Number(process.argv[1])].skills||[]).length)" "$PLUGIN_IDX") -eq 3 ]" "عدد عناصر skills في marketplace.json ليس 3 بالضبط"

# 8. obsidian-cli غير موجود ضمن قائمة skills
check "! echo \"$skills_json_line\" | grep -q 'obsidian-cli'" "obsidian-cli موجود ضمن قائمة skills رغم استبعاده عمدًا"

# 9. defuddle غير موجود ضمن قائمة skills
check "! echo \"$skills_json_line\" | grep -q 'defuddle'" "defuddle موجود ضمن قائمة skills رغم استبعاده عمدًا"

# 10. لا hooks في تعريف Plugin
has_hooks="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX hooks)"
check "[ -z \"$has_hooks\" ]" "تعريف الـPlugin يحتوي حقل hooks غير متوقع"

# 11. لا agents
has_agents="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX agents)"
check "[ -z \"$has_agents\" ]" "تعريف الـPlugin يحتوي حقل agents غير متوقع"

# 12. لا mcpServers ولا lspServers
has_mcp="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX mcpServers)"
has_lsp="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX lspServers)"
check "[ -z \"$has_mcp\" ]" "تعريف الـPlugin يحتوي حقل mcpServers غير متوقع"
check "[ -z \"$has_lsp\" ]" "تعريف الـPlugin يحتوي حقل lspServers غير متوقع"

# ============================================================
# التشغيل الأول: HOME مؤقت + claude وهمي (يثبّت TypeScript/Pyright/Ponytail/Obsidian معًا)
# ============================================================
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
export PATH="$MOCK_CLAUDE_DIR:$PATH"
export MOCK_CLAUDE_CALLS_FILE="$TMP/mock-claude-calls.log"
export TS_LSP_SKIP_INSTALL=1
export PYRIGHT_LSP_SKIP_INSTALL=1
export MCP_SERVER_DEV_CURATED_SKIP_INSTALL=1   # هذا الاختبار لا يغطي MCP Server Dev — انظر test-install-mcp-server-dev-curated.sh
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

# 13. المثبّت يضيف Marketplace مرة واحدة بالضبط
n_mp_add="$(grep -c '^plugin marketplace add ' "$MOCK_CLAUDE_CALLS_FILE" || true)"
check "[ \"$n_mp_add\" = \"1\" ]" "استدعاء plugin marketplace add لم يحدث مرة واحدة بالضبط في التشغيل الأول (العدد: $n_mp_add)"
check "grep -qF \"plugin marketplace add $MARKETPLACE_DIR\" \"$MOCK_CLAUDE_CALLS_FILE\"" "استدعاء marketplace add لا يشير إلى مسار skill-master-plugins داخل المستودع"

# 14. المثبّت يثبت الـPlugin في user scope
check "grep -qF 'plugin install obsidian-curated@skill-master-plugins --scope user' \"$MOCK_CLAUDE_CALLS_FILE\"" "لم يُستدعَ plugin install obsidian-curated@skill-master-plugins --scope user"

# ============================================================
# التشغيل الثاني: idempotency — لا تكرار لـadd/install لـobsidian-curated
# ============================================================
out2="$("$INSTALLER" 2>&1)"
n_mp_add_2="$(grep -c '^plugin marketplace add ' "$MOCK_CLAUDE_CALLS_FILE" || true)"
n_install_obsidian_2="$(grep -c '^plugin install obsidian-curated@skill-master-plugins' "$MOCK_CLAUDE_CALLS_FILE" || true)"
n_update_obsidian_2="$(grep -c '^plugin update obsidian-curated@skill-master-plugins' "$MOCK_CLAUDE_CALLS_FILE" || true)"
check "[ \"$n_mp_add_2\" = \"1\" ]" "التشغيل الثاني كرّر plugin marketplace add (العدد الكلي بعد تشغيلين: $n_mp_add_2)"
check "[ \"$n_install_obsidian_2\" = \"1\" ]" "التشغيل الثاني كرّر plugin install لـobsidian-curated (العدد الكلي بعد تشغيلين: $n_install_obsidian_2)"
check "[ \"$n_update_obsidian_2\" = \"0\" ]" "التشغيل الثاني نفّذ plugin update لـobsidian-curated رغم أن النسخة لم تتغيّر (العدد: $n_update_obsidian_2)"
check "echo \"$out2\" | grep -qF 'Obsidian Curated: Marketplace (skill-master-plugins) مسجّل مسبقًا بنفس المصدر'" "التشغيل الثاني لم يُبلغ أن Marketplace مسجّل مسبقًا (Obsidian Curated)"
check "echo \"$out2\" | grep -qF 'مثبّت مسبقًا على النسخة المعتمدة'" "التشغيل الثاني لم يُبلغ أن Plugin مثبّت مسبقًا على النسخة المعتمدة"

# obsidian الأصلي الكامل (بكل الخمس سكيلات) غير مثبت في أي مكان
check "! grep -q 'obsidian@obsidian-skills' \"$MOCK_CLAUDE_CALLS_FILE\"" "وُجد استدعاء لـobsidian@obsidian-skills (Plugin الأصلي الكامل) في سجل claude الوهمي"
mock_state="$TMP/.mock-claude-state.json"
check "[ -f \"$mock_state\" ]" "ملف حالة claude الوهمي غير موجود"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$mock_state','utf8')); process.exit(s.plugins.some(p=>p.id==='obsidian@obsidian-skills')?1:0)\"" "obsidian الأصلي الكامل مثبّت في حالة claude الوهمي"

# 15. Ponytail Curated ما زال مثبتًا (نفس المصدر/التشغيل الآن يثبت الاثنين معًا)
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$mock_state','utf8')); process.exit(s.plugins.some(p=>p.id==='ponytail-curated@skill-master-plugins')?0:1)\"" "ponytail-curated@skill-master-plugins لم يعد مثبتًا في حالة claude الوهمي"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$mock_state','utf8')); process.exit(s.plugins.some(p=>p.id==='obsidian-curated@skill-master-plugins')?0:1)\"" "obsidian-curated@skill-master-plugins ليس ضمن الـPlugins المثبتة"

# ============================================================
# 16-17. settings.json: لا Hooks أو statusLine جديدة، والحُرّاس والإعدادات السابقة سليمة
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
# 18. TypeScript وPyright يبقيان سليمين (تخطّيناهما هنا بـSKIP_INSTALL لعزل الاختبار عن npm/الشبكة —
#     يُغطّيان فعليًا في test-install-typescript-lsp.sh وtest-install-pyright-lsp.sh)
# ============================================================
check "[ ! -e \"$TMP/.claude/skills/typescript-lsp-global\" ]" "TS_LSP_SKIP_INSTALL لم يُحترم (typescript-lsp-global أُنشئ رغم التخطي)"
check "[ ! -e \"$TMP/.claude/skills/pyright-lsp-global\" ]" "PYRIGHT_LSP_SKIP_INSTALL لم يُحترم (pyright-lsp-global أُنشئ رغم التخطي)"

# ============================================================
# 19. عدد Skills المصدرية في amer يبقى 111 (obsidian-curated ليس ضمنها — Plugin وليس Skill مصدري)
# ============================================================
n_src="$(find "$SRC" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
check "[ \"$n_src\" -eq 111 ]" "عدد سكيلات المصدر في المستودع ليس 111 (وجد: $n_src)"

# ============================================================
# 20. قواعد Automatic Routing الخاصة بـObsidian موجودة مرة واحدة بالضبط في القالب
# ============================================================
check "[ -f \"$ROUTING_TEMPLATE\" ]" "قالب automatic-skill-routing.md غير موجود"
n_section="$(grep -cF '### Obsidian routing' "$ROUTING_TEMPLATE" || true)"
check "[ \"$n_section\" = \"1\" ]" "قسم Obsidian routing غير موجود مرة واحدة بالضبط (العدد: $n_section)"
for line in \
  "Use obsidian-markdown only when at least one of the following holds:" \
  "An .obsidian folder exists at the project root or a parent folder." \
  "Use obsidian-bases only when:" \
  "Creating or editing a .base file." \
  "Use json-canvas only when:" \
  "Creating or editing a .canvas file." \
  "Do not use obsidian-cli in Claude Cloud." \
  "Do not use defuddle; use Exa or Firecrawl for web extraction."
do
  n="$(grep -cF "$line" "$ROUTING_TEMPLATE" || true)"
  check "[ \"$n\" = \"1\" ]" "السطر غير موجود مرة واحدة بالضبط في قسم Obsidian routing (العدد: $n): $line"
done

# 21. التوجيه يمنع Obsidian في README العادي (تصريح نصي واضح لهذه الحالة)
check "grep -qF 'README.md' \"$ROUTING_TEMPLATE\"" "قسم Obsidian routing لا يذكر استبعاد README.md صراحة"

# ============================================================
# 22-24: فحوصات fixture لحالتي Vault وغير-Vault (بلا لمس أي مشروع حقيقي)
# ============================================================
NON_VAULT="$FIXTURES_DIR/non-vault"
VAULT="$FIXTURES_DIR/vault"

# 22. حالة غير-Vault: لا .obsidian، ولا Wikilinks/Callouts مضافة
check "[ ! -d \"$NON_VAULT/.obsidian\" ]" "fixture غير-Vault يحتوي .obsidian خطأً"
check "[ -f \"$NON_VAULT/README.md\" ]" "fixture غير-Vault لا يحتوي README.md"
check "! grep -q '\\[\\[' \"$NON_VAULT/README.md\"" "fixture غير-Vault يحتوي wikilinks رغم أنه ليس Vault"

# 23. حالة Vault: .obsidian موجود، وNotes/Test.md → obsidian-markdown (يحتوي syntax أوبسيديان)
check "[ -d \"$VAULT/.obsidian\" ]" "fixture Vault لا يحتوي .obsidian"
check "[ -f \"$VAULT/Notes/Test.md\" ]" "fixture Vault لا يحتوي Notes/Test.md"
check "grep -q '\\[\\[' \"$VAULT/Notes/Test.md\"" "Notes/Test.md في fixture Vault لا يحتوي wikilink (لإثبات ارتباطه بـobsidian-markdown)"

# 24. Database.base → obsidian-bases، Board.canvas → json-canvas (بالامتداد)
check "[ -f \"$VAULT/Database.base\" ]" "fixture Vault لا يحتوي Database.base"
check "[ -f \"$VAULT/Board.canvas\" ]" "fixture Vault لا يحتوي Board.canvas"
check "node -e \"JSON.parse(require('fs').readFileSync('$VAULT/Board.canvas','utf8'))\" >/dev/null 2>&1" "Board.canvas ليس JSON صالحًا (JSON Canvas صيغة JSON)"

echo ""
echo "النتيجة: نجح=$pass فشل=$fail"
[ "$fail" -eq 0 ]
