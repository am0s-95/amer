#!/usr/bin/env bash
# اختبار انحدار معزول لتركيب "Ponytail Curated" عبر install-global-skills.sh.
# يعمل داخل HOME مؤقت معزول مع claude CLI وهمي (tests/fixtures/mock-claude-ponytail) ومع npm
# وهمي (tests/fixtures/mock-npm-pyright، يغطي TypeScript وPyright معًا) — لا شبكة، لا لمس
# لـ~/.claude الحقيقي، ولا تعديل على مستودع amer نفسه.
# يغطي: صحة marketplace.json (المصدر git-subdir، path=skills، ref=v4.8.4، sha الكامل،
# strict=false، الست سكيلات فقط، بلا hooks/mcpServers/agents في تعريف الـPlugin)، تسجيل
# Marketplace مرة واحدة، تثبيت الـPlugin بـuser scope، idempotency التشغيل الثاني، عدم تثبيت
# Ponytail الأصلي، سلامة settings.json (بلا Hooks أو statusLine من Ponytail) وHooks الحالية
# وTypeScript/Pyright، عدد سكيلات المصدر (111)، قواعد التوجيه التلقائي الجديدة مرة واحدة،
# وعدم تعديل أي ملف داخل مستودع العمل.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$REPO/scripts/install-global-skills.sh"
SRC="$REPO/.claude/skills"
MARKETPLACE_DIR="$REPO/.claude/marketplaces/skill-master-plugins"
MARKETPLACE_JSON="$MARKETPLACE_DIR/.claude-plugin/marketplace.json"
ROUTING_TEMPLATE="$REPO/.claude/templates/automatic-skill-routing.md"
MOCK_CLAUDE_DIR="$REPO/tests/fixtures/mock-claude-ponytail"
MOCK_NPM_DIR="$REPO/tests/fixtures/mock-npm-pyright"
EXPECTED_SHA="bc9ee949d5f439e8b9f3bb92c6d6d3d1e6ebd324"
EXPECTED_SKILLS='ponytail,ponytail-review,ponytail-audit,ponytail-debt,ponytail-gain,ponytail-help'

pass=0; fail=0
ok()  { pass=$((pass+1)); }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }
check(){ if eval "$1"; then ok; else bad "$2"; fi }
jget() { node -e "const v=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); let x=v; for (const k of process.argv.slice(2)) x=x==null?undefined:x[k]; console.log(x===undefined?'':x);" "$@"; }

[ -x "$MOCK_CLAUDE_DIR/claude" ] || { echo "FAIL: claude الوهمي غير قابل للتنفيذ: $MOCK_CLAUDE_DIR/claude"; exit 1; }
[ -x "$MOCK_NPM_DIR/npm" ] || { echo "FAIL: npm الوهمي غير قابل للتنفيذ: $MOCK_NPM_DIR/npm"; exit 1; }
[ -f "$MARKETPLACE_JSON" ] || { echo "FAIL: marketplace.json غير موجود: $MARKETPLACE_JSON"; exit 1; }

# ============================================================
# 1-10: صحة marketplace.json نفسه (ملف المستودع الحقيقي — بلا HOME مؤقت)
# ============================================================

# 1. marketplace.json صالح JSON
check "node -e \"JSON.parse(require('fs').readFileSync('$MARKETPLACE_JSON','utf8'))\" >/dev/null 2>&1" "marketplace.json ليس JSON صالحًا"

PLUGIN_IDX=0   # عنصر ponytail-curated الوحيد في مصفوفة plugins
plugin_name="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX name)"
check "[ \"$plugin_name\" = \"ponytail-curated\" ]" "اسم الـPlugin ليس ponytail-curated (وجد: $plugin_name)"

# 2. المصدر من نوع git-subdir
src_type="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source source)"
check "[ \"$src_type\" = \"git-subdir\" ]" "نوع المصدر ليس git-subdir (وجد: $src_type)"

src_url="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source url)"
check "[ \"$src_url\" = \"https://github.com/DietrichGebert/ponytail.git\" ]" "رابط المصدر غير صحيح (وجد: $src_url)"

# 3. path يساوي skills
src_path="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source path)"
check "[ \"$src_path\" = \"skills\" ]" "path المصدر ليس skills (وجد: $src_path)"

# 4. ref يساوي v4.8.4
src_ref="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source ref)"
check "[ \"$src_ref\" = \"v4.8.4\" ]" "ref المصدر ليس v4.8.4 (وجد: $src_ref)"

# 5. sha يساوي القيمة الكاملة المطلوبة (40 حرفًا)
src_sha="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX source sha)"
check "[ \"$src_sha\" = \"$EXPECTED_SHA\" ]" "sha المصدر لا يطابق المطلوب (وجد: $src_sha)"
check "[ \"${#src_sha}\" -eq 40 ]" "sha المصدر ليس 40 حرفًا (الطول: ${#src_sha})"

# 6. strict = false
strict_val="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX strict)"
check "[ \"$strict_val\" = \"false\" ]" "strict ليست false (وجد: $strict_val)"

# 7. السكيلات الست فقط موجودة في القائمة (لا أكثر ولا أقل، ولا تكرار)
skills_json_line="$(node -e "
  const mp = JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));
  const list = mp.plugins[0].skills || [];
  console.log(list.map(s=>s.replace(/^\.\//,'')).sort().join(','));
" "$MARKETPLACE_JSON")"
expected_sorted="$(printf '%s\n' "${EXPECTED_SKILLS//,/$'\n'}" | sort | paste -sd, -)"
check "[ \"$skills_json_line\" = \"$expected_sorted\" ]" "قائمة skills في marketplace.json لا تطابق الست سكيلات المتوقعة (وجد: $skills_json_line)"
check "[ $(node -e "console.log((JSON.parse(require('fs').readFileSync('$MARKETPLACE_JSON','utf8')).plugins[0].skills||[]).length)") -eq 6 ]" "عدد عناصر skills في marketplace.json ليس 6 بالضبط"

# 8. لا hooks في تعريف Plugin
has_hooks="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX hooks)"
check "[ -z \"$has_hooks\" ]" "تعريف الـPlugin يحتوي حقل hooks غير متوقع"

# 9. لا mcpServers
has_mcp="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX mcpServers)"
check "[ -z \"$has_mcp\" ]" "تعريف الـPlugin يحتوي حقل mcpServers غير متوقع"

# 10. لا agents
has_agents="$(jget "$MARKETPLACE_JSON" plugins $PLUGIN_IDX agents)"
check "[ -z \"$has_agents\" ]" "تعريف الـPlugin يحتوي حقل agents غير متوقع"

# لا يوجد ponytail الأصلي الكامل (غير المنسّق) مضافًا بجانب ponytail-curated في نفس الـMarketplace
# (المصفوفة قد تحتوي عناصر Curated أخرى مثل obsidian-curated — هذا متوقع ومقصود)
has_original_ponytail="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$MARKETPLACE_JSON','utf8')).plugins.some(p=>p.name==='ponytail')?1:0)")"
check "[ \"$has_original_ponytail\" = \"0\" ]" "وُجد عنصر Plugin باسم ponytail الأصلي (غير المنسّق) في marketplace.json"

# ============================================================
# التشغيل الأول: HOME مؤقت + claude وnpm وهميان (يثبّت TypeScript وPyright وPonytail Curated معًا)
# ============================================================
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
export PATH="$MOCK_CLAUDE_DIR:$MOCK_NPM_DIR:$PATH"
export MOCK_CLAUDE_CALLS_FILE="$TMP/mock-claude-calls.log"
export MOCK_NPM_CALLS_FILE="$TMP/mock-npm-calls.log"
export OBSIDIAN_CURATED_SKIP_INSTALL=1   # هذا الاختبار لا يغطي Obsidian — انظر test-install-obsidian-curated.sh
export MCP_SERVER_DEV_CURATED_SKIP_INSTALL=1   # هذا الاختبار لا يغطي MCP Server Dev — انظر test-install-mcp-server-dev-curated.sh
: > "$MOCK_CLAUDE_CALLS_FILE"
: > "$MOCK_NPM_CALLS_FILE"

# بيانات مسبقة في settings.json لضمان بقاء الإعدادات وHooks السابقة سليمة (فحص 16)
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

# لقطة git status لمستودع amer قبل تشغيل المثبّت (فحص 20)
git_status_before="$(git -C "$REPO" status --porcelain)"

out1="$("$INSTALLER" 2>&1)"

# 20. لا يتم تعديل أي مستودع عمل (git status لمستودع amer نفسه لم يتغيّر بتشغيل المثبّت)
git_status_after="$(git -C "$REPO" status --porcelain)"
check "[ \"$git_status_before\" = \"$git_status_after\" ]" "تشغيل المثبّت عدّل حالة git لمستودع amer (قبل: [$git_status_before] بعد: [$git_status_after])"

calls_claude_1="$(cat "$MOCK_CLAUDE_CALLS_FILE")"

# 11. المثبّت يضيف Marketplace مرة واحدة بالضبط
n_mp_add="$(grep -c '^plugin marketplace add ' "$MOCK_CLAUDE_CALLS_FILE" || true)"
check "[ \"$n_mp_add\" = \"1\" ]" "استدعاء plugin marketplace add لم يحدث مرة واحدة بالضبط في التشغيل الأول (العدد: $n_mp_add)"
check "grep -qF \"plugin marketplace add $MARKETPLACE_DIR\" \"$MOCK_CLAUDE_CALLS_FILE\"" "استدعاء marketplace add لا يشير إلى مسار skill-master-plugins داخل المستودع"

# 12. المثبّت يثبت Plugin في user scope
check "grep -qF 'plugin install ponytail-curated@skill-master-plugins --scope user' \"$MOCK_CLAUDE_CALLS_FILE\"" "لم يُستدعَ plugin install ponytail-curated@skill-master-plugins --scope user"

# ============================================================
# التشغيل الثاني: idempotency — لا تكرار لـadd/install
# ============================================================
out2="$("$INSTALLER" 2>&1)"
n_mp_add_2="$(grep -c '^plugin marketplace add ' "$MOCK_CLAUDE_CALLS_FILE" || true)"
n_install_2="$(grep -c '^plugin install ' "$MOCK_CLAUDE_CALLS_FILE" || true)"
n_update_2="$(grep -c '^plugin update ' "$MOCK_CLAUDE_CALLS_FILE" || true)"
check "[ \"$n_mp_add_2\" = \"1\" ]" "التشغيل الثاني كرّر plugin marketplace add (العدد الكلي بعد تشغيلين: $n_mp_add_2)"
check "[ \"$n_install_2\" = \"1\" ]" "التشغيل الثاني كرّر plugin install (العدد الكلي بعد تشغيلين: $n_install_2)"
check "[ \"$n_update_2\" = \"0\" ]" "التشغيل الثاني نفّذ plugin update رغم أن النسخة لم تتغيّر (العدد: $n_update_2)"
check "echo \"$out2\" | grep -qF 'مسجّل مسبقًا بنفس المصدر'" "التشغيل الثاني لم يُبلغ أن Marketplace مسجّل مسبقًا"
check "echo \"$out2\" | grep -qF 'مثبّت مسبقًا على النسخة المعتمدة'" "التشغيل الثاني لم يُبلغ أن Plugin مثبّت مسبقًا على النسخة المعتمدة"

# 14. Ponytail الأصلي الكامل غير مثبت في أي مكان (لا مصدر يشير لجذر مستودع Ponytail، ولا id باسم ponytail@ponytail)
check "! grep -q 'ponytail@ponytail' \"$MOCK_CLAUDE_CALLS_FILE\"" "وُجد استدعاء لـponytail@ponytail (Ponytail الأصلي) في سجل claude الوهمي"
check "node -e \"const mp=JSON.parse(require('fs').readFileSync('$MARKETPLACE_JSON','utf8')); const s=JSON.stringify(mp); process.exit(/DietrichGebert\\/ponytail\\.git/.test(s) && !s.includes('git-subdir') ? 1 : 0)\"" "مصدر يشير لجذر مستودع Ponytail بدل git-subdir محدد بـpath=skills"
mock_state="$TMP/.mock-claude-state.json"
check "[ -f \"$mock_state\" ]" "ملف حالة claude الوهمي غير موجود"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$mock_state','utf8')); process.exit(s.plugins.some(p=>p.id==='ponytail@ponytail')?1:0)\"" "Ponytail الأصلي الكامل (ponytail@ponytail) مثبّت في حالة claude الوهمي"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$mock_state','utf8')); process.exit(s.plugins.length===1 && s.plugins[0].id==='ponytail-curated@skill-master-plugins'?0:1)\"" "حالة الـPlugins في claude الوهمي لا تحتوي ponytail-curated@skill-master-plugins حصرًا"

# ============================================================
# 15. settings.json لا يحصل فيه أي Hooks أو statusLine من Ponytail
# ============================================================
check "node -e \"JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8'))\" >/dev/null 2>&1" "settings.json غير صالح بعد التركيب"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.hooks&&s.hooks.SessionStart)?1:0)\"" "settings.json يحتوي SessionStart (متوقّع من Ponytail الأصلي فقط)"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.hooks&&s.hooks.SubagentStart)?1:0)\"" "settings.json يحتوي SubagentStart (متوقّع من Ponytail الأصلي فقط)"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.hooks&&s.hooks.UserPromptSubmit)?1:0)\"" "settings.json يحتوي UserPromptSubmit (متوقّع من Ponytail الأصلي فقط)"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit(s.statusLine?1:0)\"" "settings.json يحتوي statusLine (متوقّع من نُدجة Ponytail الأصلي فقط)"

# ============================================================
# 16. hooks الحالية (guard-dangerous، guard-github-mcp، suggest-compact) تبقى سليمة، والإعدادات السابقة محفوظة
# ============================================================
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.permissions&&s.permissions.allow&&s.permissions.allow[0]==='Bash(npm test:*)')?0:1)\"" "permissions.allow الأصلية اختفت أو تغيّرت"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.env&&s.env.MY_CUSTOM_VAR==='1')?0:1)\"" "env الأصلي اختفى بعد التركيب"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Edit'&&(m.hooks||[]).some(h=>h.command==='echo user-hook')); process.exit(has?0:1)\"" "hook مستخدم موجود مسبقًا على Edit حُذف"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Bash'&&(m.hooks||[]).some(h=>String(h.command||'').includes('guard-dangerous.js'))); process.exit(has?0:1)\"" "guard-dangerous لم يُسجّل"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='mcp__github__.*'&&(m.hooks||[]).some(h=>String(h.command||'').includes('guard-github-mcp.js'))); process.exit(has?0:1)\"" "guard-github-mcp لم يُسجّل"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Write'&&(m.hooks||[]).some(h=>String(h.command||'').includes('suggest-compact.js'))); process.exit(has?0:1)\"" "suggest-compact على Write لم يُسجّل"

# ============================================================
# 17. TypeScript وPyright يبقيان سليمين (نفس تشغيل المثبّت، عبر mock-npm-pyright المشترك)
# ============================================================
TS_PLUGIN_DIR="$TMP/.claude/skills/typescript-lsp-global"
PYRIGHT_PLUGIN_DIR="$TMP/.claude/skills/pyright-lsp-global"
check "[ -f \"$TS_PLUGIN_DIR/.claude-plugin/plugin.json\" ]" "plugin.json الخاص بـTypeScript LSP غير موجود"
check "[ -f \"$TS_PLUGIN_DIR/.lsp.json\" ]" ".lsp.json الخاص بـTypeScript LSP غير موجود"
ts_ls_bin="$(jget "$TS_PLUGIN_DIR/.lsp.json" typescript command)"
check "[ -n \"$ts_ls_bin\" ] && [ -x \"$ts_ls_bin\" ]" "typescript-language-server غير قابل للتنفيذ بعد تركيب Ponytail Curated"
check "[ -f \"$PYRIGHT_PLUGIN_DIR/.claude-plugin/plugin.json\" ]" "plugin.json الخاص بـPyright LSP غير موجود"
check "[ -f \"$PYRIGHT_PLUGIN_DIR/.lsp.json\" ]" ".lsp.json الخاص بـPyright LSP غير موجود"
pyright_bin="$(jget "$PYRIGHT_PLUGIN_DIR/.lsp.json" pyright command)"
check "[ -n \"$pyright_bin\" ] && [ -x \"$pyright_bin\" ]" "pyright-langserver غير قابل للتنفيذ بعد تركيب Ponytail Curated"

# ============================================================
# 18. عدد Skills المصدرية في amer يبقى 111 (ponytail-curated ليس ضمنها — Plugin وليس Skill مصدري)
# ============================================================
n_src="$(find "$SRC" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
check "[ \"$n_src\" -eq 111 ]" "عدد سكيلات المصدر في المستودع ليس 111 (وجد: $n_src)"

# ============================================================
# 19. قواعد Automatic Routing الجديدة موجودة مرة واحدة بالضبط في القالب
# ============================================================
check "[ -f \"$ROUTING_TEMPLATE\" ]" "قالب automatic-skill-routing.md غير موجود"
for line in \
  "Use ponytail automatically when implementing a feature, refactor, or bugfix that risks over-engineering." \
  "Apply ponytail in lite mode as a method: understand the flow first, then pick the simplest solution that is actually correct." \
  "Do not use ponytail for research-only work, source gathering, documentation analysis, planning that writes no code, or administrative tasks." \
  "Ponytail never relaxes security, validation, accessibility, error handling, tests, reliability, or explicit user requirements." \
  "Use ponytail-review only after a large diff, not after every small edit." \
  "Use ponytail-audit only on explicit request or for a full repository audit." \
  "Do not run ponytail together with code-simplifier or any other duplicate simplification tool in the same pass."
do
  n="$(grep -cF "$line" "$ROUTING_TEMPLATE" || true)"
  check "[ \"$n\" = \"1\" ]" "السطر غير موجود مرة واحدة بالضبط في قالب التوجيه (العدد: $n): $line"
done

echo ""
echo "النتيجة: نجح=$pass فشل=$fail"
[ "$fail" -eq 0 ]
