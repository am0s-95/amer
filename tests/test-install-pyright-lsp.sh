#!/usr/bin/env bash
# اختبار انحدار معزول لتركيب Global Pyright LSP plugin عبر install-global-skills.sh.
# يعمل داخل HOME مؤقت معزول مع npm وهمي (tests/fixtures/mock-npm-pyright) — لا شبكة، لا لمس لـ~/.claude الحقيقي.
# يغطي: إنشاء Runtime/Plugin dirs، صحة plugin.json/.lsp.json، المسارات المطلقة والـexecutables،
# extension mappings، PYRIGHT_TMPDIR، startupTimeout/restartOnCrash/maxRestarts، نسخة pyright،
# الـidempotency، وسلامة TypeScript LSP والإعدادات/الحُرّاس السابقة وعدد سكيلات المصدر عند 111،
# وعدم وجود SessionStart يشغّل المثبّت تلقائيًا.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$REPO/scripts/install-global-skills.sh"
SRC="$REPO/.claude/skills"
MOCK_NPM_DIR="$REPO/tests/fixtures/mock-npm-pyright"
pass=0; fail=0
ok()  { pass=$((pass+1)); }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }
check(){ if eval "$1"; then ok; else bad "$2"; fi }
jget() { node -e "const v=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); let x=v; for (const k of process.argv.slice(2)) x=x==null?undefined:x[k]; console.log(x===undefined?'':x);" "$@"; }

[ -x "$MOCK_NPM_DIR/npm" ] || { echo "FAIL: npm الوهمي غير قابل للتنفيذ: $MOCK_NPM_DIR/npm"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
export PATH="$MOCK_NPM_DIR:$PATH"
export MOCK_NPM_CALLS_FILE="$TMP/mock-npm-calls.log"
export PONYTAIL_CURATED_SKIP_INSTALL=1   # هذا الاختبار لا يغطي Ponytail — انظر test-install-ponytail-curated.sh
: > "$MOCK_NPM_CALLS_FILE"

# --- بيانات مسبقة في settings.json لضمان بقاء الإعدادات وHooks السابقة (فحص 19) ---
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

RUNTIME_DIR="$TMP/.local/share/pyright-lsp"
PLUGIN_DIR="$TMP/.claude/skills/pyright-lsp-global"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
LSP_JSON="$PLUGIN_DIR/.lsp.json"
SETTINGS_FILE="$TMP/.claude/settings.json"
TS_RUNTIME_DIR="$TMP/.local/share/typescript-lsp"
TS_PLUGIN_DIR="$TMP/.claude/skills/typescript-lsp-global"

# --- التشغيل الأول (يثبّت TypeScript وPyright معًا عبر نفس npm الوهمي) ---
out1="$("$INSTALLER" 2>&1)"

# 1. إنشاء Runtime
check "[ -d \"$RUNTIME_DIR\" ]" "لم يُنشأ Runtime directory: $RUNTIME_DIR"

# 2. إنشاء Plugin directory
check "[ -d \"$PLUGIN_DIR\" ]" "لم يُنشأ Plugin directory: $PLUGIN_DIR"

# 3. وجود plugin.json
check "[ -f \"$PLUGIN_JSON\" ]" "plugin.json غير موجود"

# 4. وجود .lsp.json
check "[ -f \"$LSP_JSON\" ]" ".lsp.json غير موجود"

# 5. صلاحية الملفين كـJSON
check "node -e \"JSON.parse(require('fs').readFileSync('$PLUGIN_JSON','utf8'))\" >/dev/null 2>&1" "plugin.json ليس JSON صالحًا"
check "node -e \"JSON.parse(require('fs').readFileSync('$LSP_JSON','utf8'))\" >/dev/null 2>&1" ".lsp.json ليس JSON صالحًا"

if [ -f "$LSP_JSON" ]; then
  cmd="$(jget "$LSP_JSON" pyright command)"
  tmpdir_env="$(jget "$LSP_JSON" pyright env PYRIGHT_TMPDIR)"

  # 6. command مسار مطلق
  check "[ \"${cmd#/}\" != \"$cmd\" ]" "command ليس مسارًا مطلقًا: $cmd"
  # 7. command يشير إلى pyright-langserver موجود وقابل للتنفيذ
  check "[ -n \"$cmd\" ] && [ -x \"$cmd\" ]" "command لا يشير إلى pyright-langserver قابل للتنفيذ: $cmd"
  check "[[ \"$cmd\" == *pyright-langserver ]]" "command لا ينتهي بـ pyright-langserver: $cmd"

  # 8. args تساوي ["--stdio"]
  check "node -e \"const a=JSON.parse(require('fs').readFileSync('$LSP_JSON','utf8')).pyright.args; process.exit((Array.isArray(a)&&a.length===1&&a[0]==='--stdio')?0:1)\"" "args ليست [\"--stdio\"]"

  # 8.1-8.4. workspaceFolder — اختبار انحدار: يجب أن يبقى موجودًا وحرفيًا ${CLAUDE_PROJECT_DIR}
  # بلا توسيع من المثبّت (لا HOME، لا PWD، لا مسار مستودع ثابت). Claude Code هو من يوسّعها لاحقًا.
  workspace_folder="$(jget "$LSP_JSON" pyright workspaceFolder)"
  # ملاحظة: قيمة workspace_folder نفسها هي النص الحرفي "${CLAUDE_PROJECT_DIR}" — لذا يجب لفّها
  # بعلامات اقتباس مفردة (') عند بناء عبارة eval كي لا يُعاد توسيعها كمتغيّر بيئة فعلي تحت set -u.
  # 8.1. الحقل موجود (يفشل هذا الفحص إذا حُذف workspaceFolder مستقبلًا)
  check "[ -n '$workspace_folder' ]" "workspaceFolder غير موجود في تعريف pyright — لا بد أن يبقى \${CLAUDE_PROJECT_DIR} حرفيًا"
  # 8.2. القيمة تساوي حرفيًا \${CLAUDE_PROJECT_DIR} بدون أي توسيع
  check "[ '$workspace_folder' = '\${CLAUDE_PROJECT_DIR}' ]" "workspaceFolder ليست \${CLAUDE_PROJECT_DIR} حرفيًا (وجد: $workspace_folder)"
  # 8.3. المثبّت لم يحوّلها إلى HOME المؤقت
  check "[ '$workspace_folder' != '$TMP' ]" "workspaceFolder تحوّلت إلى HOME بدل البقاء \${CLAUDE_PROJECT_DIR} حرفيًا"
  # 8.4. المثبّت لم يحوّلها إلى مسار مستودع أو PWD ثابت
  check "[ '$workspace_folder' != '$REPO' ] && [ '$workspace_folder' != '$(pwd)' ]" "workspaceFolder تحوّلت إلى مسار مستودع/PWD ثابت بدل البقاء \${CLAUDE_PROJECT_DIR} حرفيًا"

  # 9. امتدادا .py و.pyi مربوطان بـpython
  check "[ \"$(jget "$LSP_JSON" pyright extensionToLanguage .py)\" = \"python\" ]" "extensionToLanguage[.py] ليست python"
  check "[ \"$(jget "$LSP_JSON" pyright extensionToLanguage .pyi)\" = \"python\" ]" "extensionToLanguage[.pyi] ليست python"

  # 10. PYRIGHT_TMPDIR مسار مطلق
  check "[ \"${tmpdir_env#/}\" != \"$tmpdir_env\" ]" "PYRIGHT_TMPDIR ليس مسارًا مطلقًا: $tmpdir_env"
  # 11. مجلد PYRIGHT_TMPDIR موجود
  check "[ -n \"$tmpdir_env\" ] && [ -d \"$tmpdir_env\" ]" "مجلد PYRIGHT_TMPDIR غير موجود: $tmpdir_env"
  check "[ \"$tmpdir_env\" = \"$TMP/.cache/pyright-tmp\" ]" "PYRIGHT_TMPDIR ليس \$HOME/.cache/pyright-tmp: $tmpdir_env"

  # 12-14. startupTimeout / restartOnCrash / maxRestarts
  check "[ \"$(jget "$LSP_JSON" pyright startupTimeout)\" = \"120000\" ]" "startupTimeout ليست 120000"
  check "[ \"$(jget "$LSP_JSON" pyright restartOnCrash)\" = \"true\" ]" "restartOnCrash ليست true"
  check "[ \"$(jget "$LSP_JSON" pyright maxRestarts)\" = \"3\" ]" "maxRestarts ليست 3"

  # لا إعدادات فحص عالمية مفروضة
  check "[ \"$(jget "$LSP_JSON" pyright typeCheckingMode)\" = \"\" ]" "يجب ألا يحتوي .lsp.json على typeCheckingMode عالمي"
  check "[ \"$(jget "$LSP_JSON" pyright pythonVersion)\" = \"\" ]" "يجب ألا يحتوي .lsp.json على pythonVersion عالمي"
  check "[ \"$(jget "$LSP_JSON" pyright venvPath)\" = \"\" ]" "يجب ألا يحتوي .lsp.json على venvPath عالمي"
fi

# 15. نسخة pyright المثبتة = 1.1.411
PYRIGHT_PKG_JSON="$RUNTIME_DIR/node_modules/pyright/package.json"
check "[ -f \"$PYRIGHT_PKG_JSON\" ] && [ \"$(jget "$PYRIGHT_PKG_JSON" version)\" = \"1.1.411\" ]" "نسخة pyright المثبتة ليست 1.1.411"

# التحقق من محتوى plugin.json الأساسي
check "[ \"$(jget "$PLUGIN_JSON" name)\" = \"pyright-lsp-global\" ]" "اسم Plugin غير صحيح في plugin.json"
check "[ \"$(jget "$PLUGIN_JSON" lspServers)\" = \"./.lsp.json\" ]" "lspServers لا يشير إلى ./.lsp.json"

# لا SKILL.md لهذا الـPlugin — لا يُحتسب كسكيل رقم 112
check "[ ! -f \"$PLUGIN_DIR/SKILL.md\" ]" "لا يجب أن يحتوي pyright-lsp-global على SKILL.md"

calls_after_first="$(wc -l < "$MOCK_NPM_CALLS_FILE" | tr -d ' ')"
check "[ \"$calls_after_first\" -ge 1 ]" "npm الوهمي لم يُستدعَ في التشغيل الأول"

# --- 16-17. التشغيل الثاني: idempotent — لا يعيد npm install ولا يكرر Plugin ---
out2="$("$INSTALLER" 2>&1)"
calls_after_second="$(wc -l < "$MOCK_NPM_CALLS_FILE" | tr -d ' ')"
check "[ \"$calls_after_second\" = \"$calls_after_first\" ]" "التشغيل الثاني نفّذ npm install رغم عدم تغيّر النسخة/package.json (استدعاءات: $calls_after_first -> $calls_after_second)"
check "node -e \"JSON.parse(require('fs').readFileSync('$PLUGIN_JSON','utf8'))\" >/dev/null 2>&1" "plugin.json تكسّر بعد التشغيل الثاني"
check "node -e \"JSON.parse(require('fs').readFileSync('$LSP_JSON','utf8'))\" >/dev/null 2>&1" ".lsp.json تكسّر بعد التشغيل الثاني"
check "[ -d \"$PLUGIN_DIR\" ]" "Plugin directory اختفى بعد التشغيل الثاني"
n_plugin_dirs="$(find "$TMP/.claude/skills" -maxdepth 1 -iname 'pyright-lsp-global*' | wc -l | tr -d ' ')"
check "[ \"$n_plugin_dirs\" = \"1\" ]" "تكرّر Plugin directory بدل التحديث في مكانه (وجد: $n_plugin_dirs)"

# workspaceFolder يبقى حرفيًا \${CLAUDE_PROJECT_DIR} بعد التشغيل الثاني أيضًا (idempotency)
workspace_folder_2="$(jget "$LSP_JSON" pyright workspaceFolder)"
check "[ '$workspace_folder_2' = '\${CLAUDE_PROJECT_DIR}' ]" "workspaceFolder تغيّرت بعد التشغيل الثاني (وجد: $workspace_folder_2)"

# --- 18. TypeScript LSP يبقى موجودًا وسليمًا بعد إضافة Pyright ---
check "[ -d \"$TS_RUNTIME_DIR\" ]" "Runtime الخاص بـ TypeScript LSP اختفى: $TS_RUNTIME_DIR"
check "[ -d \"$TS_PLUGIN_DIR\" ]" "Plugin directory الخاص بـ TypeScript LSP اختفى: $TS_PLUGIN_DIR"
check "[ -f \"$TS_PLUGIN_DIR/.claude-plugin/plugin.json\" ]" "plugin.json الخاص بـ TypeScript LSP غير موجود"
check "[ -f \"$TS_PLUGIN_DIR/.lsp.json\" ]" ".lsp.json الخاص بـ TypeScript LSP غير موجود"
check "node -e \"JSON.parse(require('fs').readFileSync('$TS_PLUGIN_DIR/.lsp.json','utf8'))\" >/dev/null 2>&1" ".lsp.json الخاص بـ TypeScript LSP ليس JSON صالحًا"
ts_ls_bin="$(jget "$TS_PLUGIN_DIR/.lsp.json" typescript command)"
check "[ -n \"$ts_ls_bin\" ] && [ -x \"$ts_ls_bin\" ]" "typescript-language-server لم يعد قابلاً للتنفيذ بعد تركيب Pyright"

# --- 19. الإعدادات والـhooks السابقة تبقى محفوظة ---
check "node -e \"JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8'))\" >/dev/null 2>&1" "settings.json غير صالح بعد التركيب"
check "[ \"$(jget "$SETTINGS_FILE" permissions allow)\" != '' ]" "permissions الأصلية اختفت"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.permissions&&s.permissions.allow&&s.permissions.allow[0]==='Bash(npm test:*)')?0:1)\"" "قيمة permissions.allow الأصلية تغيّرت"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.env&&s.env.MY_CUSTOM_VAR==='1')?0:1)\"" "env الأصلي اختفى بعد التركيب"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Edit'&&(m.hooks||[]).some(h=>h.command==='echo user-hook')); process.exit(has?0:1)\"" "hook مستخدم موجود مسبقًا على Edit حُذف"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Bash'&&(m.hooks||[]).some(h=>String(h.command||'').includes('guard-dangerous.js'))); process.exit(has?0:1)\"" "guard-dangerous لم يُسجّل"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Write'&&(m.hooks||[]).some(h=>String(h.command||'').includes('suggest-compact.js'))); process.exit(has?0:1)\"" "suggest-compact على Write لم يُسجّل"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.hooks&&s.hooks.SessionStart)?1:0)\"" "المثبّت أضاف SessionStart غير متوقع لتشغيل نفسه تلقائيًا"

# --- 20. عدد Skills المصدرية يبقى 111 ---
n_src="$(find "$SRC" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
check "[ \"$n_src\" -eq 111 ]" "عدد سكيلات المصدر في المستودع ليس 111 (وجد: $n_src) — pyright-lsp-global لا يجب أن يُعتبر سكيل"

# --- 21. لا يوجد SessionStart يشغّل المثبّت تلقائيًا (تأكيد إضافي عبر بحث نصي) ---
check "! grep -q 'install-global-skills.sh' \"$SETTINGS_FILE\"" "settings.json يشير إلى تشغيل install-global-skills.sh تلقائيًا"

echo ""
echo "النتيجة: نجح=$pass فشل=$fail"
[ "$fail" -eq 0 ]
