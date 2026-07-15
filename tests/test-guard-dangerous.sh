#!/usr/bin/env bash
# اختبار انحدار لحارس الأفعال الخطرة (guard-dangerous.js).
# يتحقق أن الأوامر الخطرة (المباشرة والمغلّفة) تُحوّل إلى موافقة يدوية،
# وأن أوامر الفحص الآمنة تمر بصمت، وأن فشل التفسير يفشل بأمان (ask).
set -u
GUARD="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.claude/scripts/hooks/guard-dangerous.js"
pass=0; fail=0

run() { printf '%s' "$1" | node "$GUARD" 2>/dev/null; }
payload() { node -e 'console.log(JSON.stringify({tool_name:"Bash",tool_input:{command:process.argv[1]}}))' "$1"; }

must_ask() {
  out="$(run "$(payload "$1")")"
  if [[ "$out" == *'"permissionDecision":"ask"'* ]]; then pass=$((pass+1));
  else fail=$((fail+1)); echo "FAIL (كان يجب أن يسأل): $1"; fi
}
must_allow() {
  out="$(run "$(payload "$1")")"
  if [[ -z "$out" ]]; then pass=$((pass+1));
  else fail=$((fail+1)); echo "FAIL (كان يجب أن يسمح): $1 → $out"; fi
}

echo "== خطرة مباشرة =="
must_ask 'vercel deploy --prod'
must_ask 'git push --force origin master'
must_ask 'git push -f origin main'
must_ask 'prisma migrate deploy'
must_ask 'prisma db push'
must_ask 'rm -rf /var/data'
must_ask 'rm -rf ~/projects'
must_ask 'aws ec2 terminate-instances --instance-ids i-123'
must_ask 'gcloud compute instances delete my-vm'
must_ask 'terraform apply -auto-approve'
must_ask 'terraform destroy'
must_ask 'kubectl delete deployment api'
must_ask 'cat .env.production'
must_ask 'head -5 secrets/.env'
must_ask 'vercel env add DATABASE_URL'
must_ask 'gh secret set TOKEN'
must_ask 'psql -c "DROP TABLE users"'

echo "== خطرة مغلّفة (wrapped) =="
must_ask "bash -c 'git push --force origin main'"
must_ask 'sh -c "vercel --prod"'
must_ask 'git -C /some/path push --force'
must_ask 'npx vercel --prod'
must_ask 'npm run deploy'
must_ask 'cd app && terraform apply'
must_ask 'yarn deploy'

echo "== آمنة (فحص/عمل يومي) =="
must_allow 'git status'
must_allow 'git push origin feature/my-branch'
must_allow 'git push -u origin claude/work-branch'
must_allow 'terraform plan'
must_allow 'kubectl get pods'
must_allow 'aws s3 ls'
must_allow 'npm test'
must_allow 'npm run build'
must_allow 'ls -la && cat README.md'
must_allow 'prisma generate'
must_allow 'grep -r "deploy" src/'

echo "== فشل آمن (fail-safe) =="
out="$(run 'THIS IS NOT JSON AT ALL')"
if [[ "$out" == *'"permissionDecision":"ask"'* ]]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: مدخلات غير مفهومة يجب أن تسأل لا أن تسمح"; fi

echo "== أدوات غير Bash تمر بصمت =="
out="$(run '{"tool_name":"Read","tool_input":{"file_path":"/x/.env"}}')"
if [[ -z "$out" ]]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: أداة Read يجب ألا يعترضها حارس Bash"; fi

echo ""
echo "النتيجة: نجح=$pass فشل=$fail"
[ "$fail" -eq 0 ]
