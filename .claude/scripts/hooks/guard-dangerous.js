#!/usr/bin/env node
// PreToolUse guard على Bash: يفرض موافقة يدوية (permissionDecision: "ask")
// على أوامر التنفيذ الخطرة — النشر الفعلي، push القسري، migrations،
// الحذف المدمر، تعديل موارد Cloud، والتعامل مع secrets.
// المعرفة والتحليل لا تمر من هنا أصلًا (هذا يفحص أوامر Bash فقط).
'use strict';

const PATTERNS = [
  // النشر الفعلي للإنتاج
  [/\bvercel\b[^\n]*--prod\b/, 'نشر إنتاج عبر Vercel'],
  [/\bnetlify\s+deploy\b[^\n]*--prod\b/, 'نشر إنتاج عبر Netlify'],
  [/\bfirebase\s+deploy\b/, 'نشر عبر Firebase'],
  [/\b(flyctl|fly)\s+deploy\b/, 'نشر عبر Fly.io'],
  [/\brailway\s+up\b/, 'نشر عبر Railway'],
  [/\bwrangler\s+(deploy|publish)\b/, 'نشر عبر Cloudflare'],
  // push خطر
  [/\bgit\s+push\b[^\n]*(--force\b|--force-with-lease|-f\b)/, 'git push قسري'],
  [/\bgit\s+push\b[^\n]*\b(prod|production|release)\b/, 'push إلى فرع/remote إنتاجي'],
  // migrations
  [/\bprisma\s+(migrate\s+(deploy|reset)|db\s+push)\b/, 'Prisma migration'],
  [/\bdrizzle-kit\s+(push|migrate)\b/, 'Drizzle migration'],
  [/\b(rails\s+db:migrate|alembic\s+(upgrade|downgrade)|artisan\s+migrate|flask\s+db\s+upgrade)\b/, 'Database migration'],
  [/\b(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+TABLE)\b/i, 'أمر SQL مدمر'],
  // حذف مدمر
  [/\brm\s+(-[a-z]*r[a-z]*f|-[a-z]*f[a-z]*r)[a-z]*\s+(\/(?!tmp\b)|~\/|\$HOME)/, 'حذف تكراري قسري لمسار جذري/منزلي'],
  [/\bgit\s+(branch\s+-D|push\b[^\n]*--delete)\b/, 'حذف فرع'],
  // تعديل موارد Cloud
  [/\b(aws|gcloud|az)\s+\S+[^\n]*\b(delete|terminate|destroy|remove|rm)\b/, 'حذف/إنهاء مورد Cloud'],
  [/\bterraform\s+(apply|destroy)\b/, 'Terraform apply/destroy'],
  [/\bkubectl\s+(delete|drain|scale)\b/, 'تعديل موارد Kubernetes'],
  // secrets
  [/\b(vercel|netlify|gh|flyctl|railway|wrangler)\s+(env|secret)s?\s+(set|add|rm|remove|delete|push)\b/, 'تعديل secrets'],
  [/\b(cat|less|head|tail|more|bat)\s+[^\n|;&]*\.env(\.[a-z]+)?\b/, 'قراءة ملف secrets (.env)'],
];

let raw = '';
process.stdin.on('data', d => raw += d);
process.stdin.on('end', () => {
  let input = {};
  try { input = JSON.parse(raw); } catch { process.exit(0); }
  if (input.tool_name !== 'Bash') process.exit(0);
  const cmd = String((input.tool_input && input.tool_input.command) || '');
  for (const [re, label] of PATTERNS) {
    if (re.test(cmd)) {
      const reason = `[Guard] فعل خطر (${label}) — يتطلب موافقة يدوية صريحة حسب سياسة المشروع`;
      process.stdout.write(JSON.stringify({
        hookSpecificOutput: {
          hookEventName: 'PreToolUse',
          permissionDecision: 'ask',
          permissionDecisionReason: reason,
        },
      }));
      process.exit(0);
    }
  }
  process.exit(0);
});
