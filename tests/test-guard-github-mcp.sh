#!/usr/bin/env bash
# اختبار انحدار لحارس GitHub MCP (guard-github-mcp.js) وتركيبه العالمي.
# يختبر الحارس مباشرة بـpayloads صناعية فقط — لا يستدعي أي أداة GitHub MCP حقيقية.
# يغطي: أدوات القراءة (بصمت)، أدوات التغيير (ask + سبب يحمل اسم الأداة بلا تسريب)،
# أداة GitHub غير معروفة (ask افتراضيًا)، أدوات غير GitHub / Bash (بلا قرار)،
# فشل التحليل (fail-closed)، وتركيب المثبّت العالمي (hook + permissions.ask + idempotency).
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$REPO/.claude/scripts/hooks/guard-github-mcp.js"
INSTALLER="$REPO/scripts/install-global-skills.sh"
SRC="$REPO/.claude/skills"
MOCK_NPM_DIR="$REPO/tests/fixtures/mock-npm-pyright"
pass=0; fail=0
ok()  { pass=$((pass+1)); }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }
check(){ if eval "$1"; then ok; else bad "$2"; fi }

payload() {
  # payload <tool_name> [tool_input_json]
  node -e '
    const toolName = process.argv[1];
    const toolInput = process.argv[2] ? JSON.parse(process.argv[2]) : {};
    console.log(JSON.stringify({
      hook_event_name: "PreToolUse",
      tool_name: toolName,
      tool_input: toolInput,
    }));
  ' "$1" "${2:-{\}}"
}

STDOUT_FILE="$(mktemp)"
STDERR_FILE="$(mktemp)"
trap 'rm -f "$STDOUT_FILE" "$STDERR_FILE"' EXIT

run() {
  # run <raw-json-on-stdin> -> يملأ STDOUT_FILE/STDERR_FILE ويعيد exit code
  printf '%s' "$1" > "$STDOUT_FILE.in"
  node "$GUARD" < "$STDOUT_FILE.in" > "$STDOUT_FILE" 2> "$STDERR_FILE"
  echo $?
}

must_silent() {
  # tool_name, tool_input
  local code out
  code="$(run "$(payload "$1" "${2:-}")")"
  out="$(cat "$STDOUT_FILE")"
  if [ "$code" = "0" ] && [ -z "$out" ]; then ok;
  else bad "كان يجب أن يمر بصمت (exit=$code, out=$out): $1"; fi
}

must_ask() {
  local code out
  code="$(run "$(payload "$1" "${2:-}")")"
  out="$(cat "$STDOUT_FILE")"
  if [ "$code" = "0" ] && [[ "$out" == *'"permissionDecision":"ask"'* ]] && [[ "$out" == *'"hookEventName":"PreToolUse"'* ]]; then
    ok;
  else
    bad "كان يجب أن يطلب ask (exit=$code, out=$out): $1"
  fi
}

must_ask_reason_contains() {
  local tool="$1" needle="$2"
  local out
  run "$(payload "$tool")" >/dev/null
  out="$(cat "$STDOUT_FILE")"
  if [[ "$out" == *"$needle"* ]]; then ok; else bad "السبب لا يحتوي '$needle' للأداة $tool: $out"; fi
}

must_deny() {
  local code out
  code="$(run "$1")"
  out="$(cat "$STDOUT_FILE")"
  if [ "$code" = "0" ] && [[ "$out" == *'"permissionDecision":"deny"'* ]]; then ok;
  else bad "كان يجب أن يرفض deny (exit=$code, out=$out)"; fi
}

must_block() {
  local raw="$1"
  local code out err
  code="$(run "$raw")"
  out="$(cat "$STDOUT_FILE")"
  err="$(cat "$STDERR_FILE")"
  if [ "$code" = "2" ] && [ -z "$out" ] && [[ "$err" == *'[GitHub Guard]'* ]]; then ok;
  else bad "كان يجب حظر آمن exit=2 (وجد exit=$code, out=$out, err=$err)"; fi
}

echo "== 1. أدوات القراءة المعروفة: بصمت =="
for t in get_me list_commits list_branches list_tags get_commit get_file_contents \
         pull_request_read issue_read list_issues list_issue_fields list_issue_types \
         list_pull_requests list_repository_collaborators list_releases get_latest_release \
         get_release_by_tag get_tag get_team_members get_teams get_label get_check_run \
         get_job_logs actions_get actions_list search_code search_commits search_issues \
         search_pull_requests search_repositories search_users; do
  must_silent "mcp__github__$t" '{"owner":"x","repo":"y"}'
done

echo "== 2. أدوات التغيير المعروفة: ask + السبب يحمل اسم الأداة =="
for t in create_branch create_or_update_file create_pull_request create_repository delete_file \
         push_files merge_pull_request disable_pr_auto_merge enable_pr_auto_merge \
         update_pull_request update_pull_request_branch add_issue_comment issue_write \
         sub_issue_write add_comment_to_pending_review add_reply_to_pull_request_comment \
         pull_request_review_write resolve_review_thread unresolve_review_thread \
         request_copilot_review run_secret_scanning fork_repository actions_run_trigger \
         subscribe_pr_activity unsubscribe_pr_activity; do
  must_ask "mcp__github__$t" '{"owner":"x","repo":"y"}'
  must_ask_reason_contains "mcp__github__$t" "$t"
done

echo "== 2b. السبب لا يسرّب tokens أو كامل tool_input =="
run "$(payload "mcp__github__merge_pull_request" '{"owner":"x","repo":"y","commit_title":"secret-token-abc123"}')" >/dev/null
out="$(cat "$STDOUT_FILE")"
if [[ "$out" != *"secret-token-abc123"* ]] && [[ "$out" != *'"owner"'* ]]; then ok; else bad "السبب سرّب tool_input: $out"; fi

echo "== 3. أداة GitHub غير معروفة: ask افتراضيًا =="
must_ask "mcp__github__future_dangerous_action" '{}'
must_ask_reason_contains "mcp__github__future_dangerous_action" "future_dangerous_action"

echo "== 4. أداة MCP غير GitHub: بلا قرار =="
code="$(run '{"hook_event_name":"PreToolUse","tool_name":"mcp__context7__query-docs","tool_input":{}}')"
out="$(cat "$STDOUT_FILE")"
if [ "$code" = "0" ] && [ -z "$out" ]; then ok; else bad "أداة غير GitHub تدخلت فيها guard-github-mcp (exit=$code, out=$out)"; fi

echo "== 5. أداة Bash: بلا قرار من حارس GitHub =="
code="$(run '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"rm -rf /"}}')"
out="$(cat "$STDOUT_FILE")"
if [ "$code" = "0" ] && [ -z "$out" ]; then ok; else bad "أداة Bash تدخل فيها حارس GitHub (exit=$code, out=$out)"; fi

echo "== 6. JSON غير صالح: fail-closed (حظر آمن) =="
must_block 'THIS IS NOT JSON AT ALL'
must_block ''

echo "== 7. tool_name مفقود: fail-closed =="
must_block '{"hook_event_name":"PreToolUse","tool_input":{}}'
must_block '{"hook_event_name":"PreToolUse","tool_name":123,"tool_input":{}}'

echo "== 7b. tool_name يبدأ بـ mcp__github__ لكن tool_input غير صالح: deny (نعرف أنها GitHub) =="
must_deny '{"hook_event_name":"PreToolUse","tool_name":"mcp__github__merge_pull_request","tool_input":"not-an-object"}'
must_deny '{"hook_event_name":"PreToolUse","tool_name":"mcp__github__merge_pull_request"}'

echo "== 8-9. تركيب المثبّت في HOME مؤقت + idempotency =="
[ -x "$MOCK_NPM_DIR/npm" ] || { echo "FAIL: npm الوهمي غير قابل للتنفيذ: $MOCK_NPM_DIR/npm"; fail=$((fail+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP" "$STDOUT_FILE" "$STDERR_FILE"' EXIT
export HOME="$TMP"
export PATH="$MOCK_NPM_DIR:$PATH"
export MOCK_NPM_CALLS_FILE="$TMP/mock-npm-calls.log"
export PONYTAIL_CURATED_SKIP_INSTALL=1   # هذا الاختبار لا يغطي Ponytail — انظر test-install-ponytail-curated.sh
: > "$MOCK_NPM_CALLS_FILE"

mkdir -p "$TMP/.claude"
cat > "$TMP/.claude/settings.json" <<'JSON'
{
  "permissions": { "allow": ["Bash(npm test:*)"], "ask": ["Bash(rm -rf /*)"] },
  "env": { "MY_CUSTOM_VAR": "1" },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit", "hooks": [ { "type": "command", "command": "echo user-hook" } ] }
    ]
  }
}
JSON

GUARD_DEST="$TMP/.claude/hooks/guard-github-mcp.js"
SETTINGS_FILE="$TMP/.claude/settings.json"
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
count_ask() {
  node -e '
    const fs=require("fs");
    let s={};
    try { s=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); } catch { s={}; }
    const tool=process.argv[2];
    const ask=(s.permissions&&s.permissions.ask)||[];
    console.log(ask.filter(x=>x===tool).length);
  ' "$1" "$2"
}

"$INSTALLER" >/dev/null 2>&1

check "[ -f \"$GUARD_DEST\" ]" "guard-github-mcp.js لم يُنسخ عالميًا"
check "diff -q \"$GUARD\" \"$GUARD_DEST\" >/dev/null" "guard-github-mcp.js العالمي لا يطابق مصدر المستودع حرفيًا"
check "node -e \"JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8'))\" >/dev/null 2>&1" "settings.json غير صالح بعد التركيب"

n_hook="$(count_hook "$SETTINGS_FILE" 'mcp__github__.*' guard-github-mcp.js)"
check "[ \"$n_hook\" = \"1\" ]" "guard-github-mcp غير مسجل مرة واحدة بالضبط على mcp__github__.* (وجد: $n_hook)"

CHANGE_TOOLS=(create_branch create_or_update_file create_pull_request create_repository delete_file
  push_files merge_pull_request disable_pr_auto_merge enable_pr_auto_merge
  update_pull_request update_pull_request_branch add_issue_comment issue_write
  sub_issue_write add_comment_to_pending_review add_reply_to_pull_request_comment
  pull_request_review_write resolve_review_thread unresolve_review_thread
  request_copilot_review run_secret_scanning fork_repository actions_run_trigger
  subscribe_pr_activity unsubscribe_pr_activity)

for t in "${CHANGE_TOOLS[@]}"; do
  n="$(count_ask "$SETTINGS_FILE" "mcp__github__$t")"
  check "[ \"$n\" = \"1\" ]" "mcp__github__$t غير موجود مرة واحدة بالضبط في permissions.ask (وجد: $n)"
done

READ_TOOLS=(get_me list_commits list_branches list_tags get_commit get_file_contents
  pull_request_read issue_read list_issues list_issue_fields list_issue_types
  list_pull_requests list_repository_collaborators list_releases get_latest_release
  get_release_by_tag get_tag get_team_members get_teams get_label get_check_run
  get_job_logs actions_get actions_list search_code search_commits search_issues
  search_pull_requests search_repositories search_users)
for t in "${READ_TOOLS[@]}"; do
  n="$(count_ask "$SETTINGS_FILE" "mcp__github__$t")"
  check "[ \"$n\" = \"0\" ]" "أداة قراءة mcp__github__$t أُضيفت خطأً إلى permissions.ask"
done

check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.permissions&&s.permissions.allow&&s.permissions.allow[0]==='Bash(npm test:*)')?0:1)\"" "permissions.allow الأصلية اختفت"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.permissions&&s.permissions.ask&&s.permissions.ask.includes('Bash(rm -rf /*)'))?0:1)\"" "قاعدة ask أصلية غير GitHub حُذفت"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); process.exit((s.env&&s.env.MY_CUSTOM_VAR==='1')?0:1)\"" "env الأصلي اختفى"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Edit'&&(m.hooks||[]).some(h=>h.command==='echo user-hook')); process.exit(has?0:1)\"" "hook مستخدم موجود مسبقًا حُذف"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Bash'&&(m.hooks||[]).some(h=>String(h.command||'').includes('guard-dangerous.js'))); process.exit(has?0:1)\"" "guard-dangerous على Bash اختفى"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Write'&&(m.hooks||[]).some(h=>String(h.command||'').includes('suggest-compact.js'))); process.exit(has?0:1)\"" "suggest-compact على Write اختفى"
check "node -e \"const s=JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8')); const has=(s.hooks.PreToolUse||[]).some(m=>m.matcher==='Edit'&&(m.hooks||[]).some(h=>String(h.command||'').includes('suggest-compact.js'))); process.exit(has?0:1)\"" "suggest-compact على Edit اختفى"

TS_PLUGIN_DIR="$TMP/.claude/skills/typescript-lsp-global"
PYRIGHT_PLUGIN_DIR="$TMP/.claude/skills/pyright-lsp-global"
check "[ -d \"$TS_PLUGIN_DIR\" ] && [ -f \"$TS_PLUGIN_DIR/.lsp.json\" ]" "Global TypeScript LSP plugin غير موجود بعد التركيب"
check "[ -d \"$PYRIGHT_PLUGIN_DIR\" ] && [ -f \"$PYRIGHT_PLUGIN_DIR/.lsp.json\" ]" "Global Pyright LSP plugin غير موجود بعد التركيب"

n_src="$(find "$SRC" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
check "[ \"$n_src\" -eq 111 ]" "عدد سكيلات المصدر في المستودع تغيّر (وجد: $n_src)"

# --- التشغيل الثاني: idempotent — لا تكرار للـhook ولا لقواعد ask ---
"$INSTALLER" >/dev/null 2>&1

n_hook2="$(count_hook "$SETTINGS_FILE" 'mcp__github__.*' guard-github-mcp.js)"
check "[ \"$n_hook2\" = \"1\" ]" "التشغيل الثاني كرّر hook guard-github-mcp (وجد: $n_hook2)"

dup_found=0
for t in "${CHANGE_TOOLS[@]}"; do
  n="$(count_ask "$SETTINGS_FILE" "mcp__github__$t")"
  [ "$n" = "1" ] || dup_found=1
done
check "[ \"$dup_found\" = \"0\" ]" "التشغيل الثاني كرّر أو فقد قواعد ask لأدوات التغيير"

check "node -e \"JSON.parse(require('fs').readFileSync('$SETTINGS_FILE','utf8'))\" >/dev/null 2>&1" "settings.json غير صالح بعد التشغيل الثاني"
check "diff -q \"$GUARD\" \"$GUARD_DEST\" >/dev/null" "guard-github-mcp.js العالمي لا يطابق المصدر بعد التشغيل الثاني"

echo ""
echo "النتيجة: نجح=$pass فشل=$fail"
[ "$fail" -eq 0 ]
