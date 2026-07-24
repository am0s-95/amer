#!/usr/bin/env node
// PreToolUse guard على أدوات GitHub MCP (mcp__github__*): يفرض موافقة يدوية
// (permissionDecision: "ask") على كل أداة تكتب أو تغيّر حالة GitHub الخارجية —
// فروع، ملفات، PRs، مراجعات، دمج، تعليقات، إلخ. أدوات القراءة المعروفة تمر
// بصمت عبر نظام الصلاحيات الطبيعي. أي أداة GitHub غير مصنّفة (جديدة أو مستقبلية)
// تُعامل افتراضيًا كأداة تغيير وتطلب موافقة — لا مرور صامت لغير المعروف.
// فشل قراءة/تفسير المدخلات: fail-closed — deny إن أمكن تأكيد أنها GitHub MCP،
// وإلا حظر آمن (exit 2) دون تفاصيل حساسة.
'use strict';

const PREFIX = 'mcp__github__';

const READ_ONLY_TOOLS = new Set([
  'get_me',
  'list_commits',
  'list_branches',
  'list_tags',
  'get_commit',
  'get_file_contents',
  'pull_request_read',
  'issue_read',
  'list_issues',
  'list_issue_fields',
  'list_issue_types',
  'list_pull_requests',
  'list_repository_collaborators',
  'list_releases',
  'get_latest_release',
  'get_release_by_tag',
  'get_tag',
  'get_team_members',
  'get_teams',
  'get_label',
  'get_check_run',
  'get_job_logs',
  'actions_get',
  'actions_list',
  'search_code',
  'search_commits',
  'search_issues',
  'search_pull_requests',
  'search_repositories',
  'search_users',
]);

const MUTATING_TOOLS = new Set([
  'create_branch',
  'create_or_update_file',
  'create_pull_request',
  'create_repository',
  'delete_file',
  'push_files',
  'merge_pull_request',
  'disable_pr_auto_merge',
  'enable_pr_auto_merge',
  'update_pull_request',
  'update_pull_request_branch',
  'add_issue_comment',
  'issue_write',
  'sub_issue_write',
  'add_comment_to_pending_review',
  'add_reply_to_pull_request_comment',
  'pull_request_review_write',
  'resolve_review_thread',
  'unresolve_review_thread',
  'request_copilot_review',
  'run_secret_scanning',
  'fork_repository',
  'actions_run_trigger',
  'subscribe_pr_activity',
  'unsubscribe_pr_activity',
]);

function ask(reason) {
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'ask',
      permissionDecisionReason: reason,
    },
  }));
  process.exit(0);
}

function deny(reason) {
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: reason,
    },
  }));
  process.exit(0);
}

// فشل آمن حين يتعذر تحديد الأداة تمامًا (JSON غير صالح / مدخلات غير كائن):
// حظر صريح للاستدعاء عبر exit code 2 — لا نعرف حتى إن كانت هذه أداة GitHub،
// فلا يمكن استخدام permissionDecision بثقة، والمرور الصامت غير مقبول.
function blockUnknown() {
  process.stderr.write('[GitHub Guard] Unable to validate GitHub MCP request.\n');
  process.exit(2);
}

let raw = '';
process.stdin.on('data', d => { raw += d; });
process.stdin.on('end', () => {
  let input;
  try {
    input = JSON.parse(raw);
  } catch {
    blockUnknown();
    return;
  }

  if (input === null || typeof input !== 'object' || Array.isArray(input)) {
    blockUnknown();
    return;
  }

  // ليس PreToolUse صراحة: ليس معنيًا بهذا الحارس — يمر بصمت.
  if (input.hook_event_name !== undefined && input.hook_event_name !== 'PreToolUse') {
    process.exit(0);
    return;
  }

  const toolName = input.tool_name;
  if (typeof toolName !== 'string' || toolName.length === 0) {
    blockUnknown();
    return;
  }

  if (!toolName.startsWith(PREFIX)) {
    process.exit(0);
    return;
  }

  // من هنا مؤكد أن هذا استدعاء GitHub MCP — أي فشل بنيوي بعد هذه النقطة
  // يُرفض (deny) بدل الحظر العام، لأن هوية الأداة معروفة.
  const toolInput = input.tool_input;
  if (toolInput === undefined || toolInput === null || typeof toolInput !== 'object' || Array.isArray(toolInput)) {
    deny(`[GitHub Guard] Malformed request for "${toolName}" — denied fail-closed.`);
    return;
  }

  const sub = toolName.slice(PREFIX.length);

  if (READ_ONLY_TOOLS.has(sub)) {
    process.exit(0);
    return;
  }

  if (MUTATING_TOOLS.has(sub)) {
    ask(`[GitHub Guard] ${sub} changes remote GitHub state and requires explicit approval.`);
    return;
  }

  ask(`[GitHub Guard] Unclassified GitHub tool "${sub}" requires explicit approval.`);
});
