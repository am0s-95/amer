#!/usr/bin/env bash
# اختبار انحدار معزول لتركيب Global TypeScript LSP plugin عبر install-global-skills.sh.
# يعمل داخل HOME مؤقت معزول مع npm وهمي (tests/fixtures/mock-npm) — لا شبكة، لا لمس لـ~/.claude الحقيقي.
# يغطي: إنشاء Runtime/Plugin dirs، صحة plugin.json/.lsp.json، المسارات المطلقة والـexecutables،
# extension mappings، startupTimeout/restartOnCrash/maxRestarts، الـidempotency، وبقاء
# الإعدادات/الحُرّاس السابقة وعدد سكيلات المصدر عند 111.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$REPO/scripts/install-global-skills.sh"
SRC="$REPO/.claude/skills"
MOCK_NPM_DIR="$REPO/tests/fixtures/mock-npm"
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
export PYRIGHT_LSP_SKIP_INSTALL=1   # هذا الاختبار لا يغطي Pyright — انظر test-install-pyright-lsp.sh
export PONYTAIL_CURATED_SKIP_INSTALL=1   # هذا الاختبار لا يغطي Ponytail — انظر test-install-ponytail-curated.sh
export OBSIDIAN_CURATED_SKIP_INSTALL=1   # هذا الاختبار لا يغطي Obsidian — انظر test-install-obsidian-curated.sh
: > "$MOCK_NPM_CALLS_FILE"

# --- بيانات مسبقة في settings.json لضمان بقاء الإعدادات وHooks السابقة (فحص 15) ---
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

RUNTIME_DIR="$TMP/.local/share/typescript-lsp"
PLUGIN_DIR="$TMP/.claude/skills/typescript-lsp-global"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
LSP_JSON="$PLUGIN_DIR/.lsp.json"
SETTINGS_FILE="$TMP/.claude/settings.json"

# --- التشغيل الأول ---
out1="$("$INSTALLER" 2>&1)"

# 1. إنشاء Runtime directory
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
  cmd="$(jget "$LSP_JSON" typescript command)"
  fallback="$(jget "$LSP_JSON" typescript initializationOptions tsserver fallbackPath)"

  # 6. command مسار مطلق
  check "[ \"${cmd#/}\" != \"$cmd\" ]" "command ليس مسارًا مطلقًا: $cmd"
  # 7. command يشير إلى executable موجود
  check "[ -n \"$cmd\" ] && [ -x \"$cmd\" ]" "command لا يشير إلى executable موجود: $cmd"

  # 8. fallbackPath مسار مطلق
  check "[ \"${fallback#/}\" != \"$fallback\" ]" "fallbackPath ليس مسارًا مطلقًا: $fallback"
  # 9. fallbackPath يشير إلى tsserver.js موجود
  check "[ -n \"$fallback\" ] && [ -f \"$fallback\" ]" "fallbackPath لا يشير إلى tsserver.js موجود: $fallback"
  check "[[ \"$fallback\" == */tsserver.js ]]" "fallbackPath لا ينتهي بـ tsserver.js: $fallback"

  # 10. extension mappings الثمانية صحيحة
  declare -A expected_ext=(
    [.ts]=typescript [.tsx]=typescriptreact [.js]=javascript [.jsx]=javascriptreact
    [.mts]=typescript [.cts]=typescript [.mjs]=javascript [.cjs]=javascript
  )
  for ext in "${!expected_ext[@]}"; do
    got="$(jget "$LSP_JSON" typescript extensionToLanguage "$ext")"
    check "[ \"$got\" = \"${expected_ext[$ext]}\" ]" "extensionToLanguage[$ext] = '$got' وليس '${expected_ext[$ext]}'"
  done

  # 11-13. startupTimeout / restartOnCrash / maxRestarts
  check "[ \"$(jget "$LSP_JSON" typescript startupTimeout)\" = \"120000\" ]" "startupTimeout ليست 120000"
  check "[ \"$(jget "$LSP_JSON" typescript restartOnCrash)\" = \"true\" ]" "restartOnCrash ليست true"
  check "[ \"$(jget "$LSP_JSON" typescript maxRestarts)\" = \"3\" ]" "maxRestarts ليست 3"
fi

# التحقق من محتوى plugin.json الأساسي
check "[ \"$(jget "$PLUGIN_JSON" name)\" = \"typescript-lsp-global\" ]" "اسم Plugin غير صحيح في plugin.json"
check "[ \"$(jget "$PLUGIN_JSON" lspServers)\" = \"./.lsp.json\" ]" "lspServers لا يشير إلى ./.lsp.json"

# لا SKILL.md لهذا الـPlugin — لا يُحتسب كسكيل رقم 112
check "[ ! -f \"$PLUGIN_DIR/SKILL.md\" ]" "لا يجب أن يحتوي typescript-lsp-global على SKILL.md"

calls_after_first="$(wc -l < "$MOCK_NPM_CALLS_FILE" | tr -d ' ')"
check "[ \"$calls_after_first\" -ge 1 ]" "npm الوهمي لم يُستدعَ في التشغيل الأول"

# --- 14. التشغيل الثاني: idempotent — لا يكرر ولا يكسر الـPlugin ---
out2="$("$INSTALLER" 2>&1)"
calls_after_second="$(wc -l < "$MOCK_NPM_CALLS_FILE" | tr -d ' ')"
check "[ \"$calls_after_second\" = \"$calls_after_first\" ]" "التشغيل الثاني نفّذ npm install رغم عدم تغيّر النسخ/package.json (استدعاءات: $calls_after_first -> $calls_after_second)"
check "node -e \"JSON.parse(require('fs').readFileSync('$PLUGIN_JSON','utf8'))\" >/dev/null 2>&1" "plugin.json تكسّر بعد التشغيل الثاني"
check "node -e \"JSON.parse(require('fs').readFileSync('$LSP_JSON','utf8'))\" >/dev/null 2>&1" ".lsp.json تكسّر بعد التشغيل الثاني"
check "[ -d \"$PLUGIN_DIR\" ]" "Plugin directory اختفى بعد التشغيل الثاني"
n_plugin_dirs="$(find "$TMP/.claude/skills" -maxdepth 1 -iname 'typescript-lsp-global*' | wc -l | tr -d ' ')"
check "[ \"$n_plugin_dirs\" = \"1\" ]" "تكرّر Plugin directory بدل التحديث في مكانه (وجد: $n_plugin_dirs)"

# --- 15. الإعدادات والـhooks السابقة تبقى محفوظة ---
check "node -e \"JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8'))\" >/dev/null 2>&1" "settings.json غير صالح بعد التركيب"
check "[ \"$(jget "$SETTINGS_FILE" permissions allow)\" != '' ]" "permissions الأصلية اختفت"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.permissions&&s.permissions.allow&&s.permissions.allow[0]==='Bash(npm test:*)')?0:1)\"" "قيمة permissions.allow الأصلية تغيّرت"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.env&&s.env.MY_CUSTOM_VAR==='1')?0:1)\"" "env الأصلي اختفى بعد التركيب"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Edit'&&(m.hooks||[]).some(h=>h.command==='echo user-hook')); process.exit(has?0:1)\"" "hook مستخدم موجود مسبقًا على Edit حُذف"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Bash'&&(m.hooks||[]).some(h=>String(h.command||'').includes('guard-dangerous.js'))); process.exit(has?0:1)\"" "guard-dangerous لم يُسجّل"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Write'&&(m.hooks||[]).some(h=>String(h.command||'').includes('suggest-compact.js'))); process.exit(has?0:1)\"" "suggest-compact على Write لم يُسجّل"

# --- 16. عدد Skills المصدرية يبقى 111 (لا شيء يمس .claude/skills الحقيقي في المستودع) ---
n_src="$(find "$SRC" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
check "[ \"$n_src\" -eq 111 ]" "عدد سكيلات المصدر في المستودع ليس 111 (وجد: $n_src) — typescript-lsp-global لا يجب أن يُعتبر سكيل"

echo ""
echo "النتيجة: نجح=$pass فشل=$fail"
[ "$fail" -eq 0 ]
