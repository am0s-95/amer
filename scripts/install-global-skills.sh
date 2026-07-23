#!/usr/bin/env bash
# تركيب مكتبة السكيلات عالميًا: symlinks من ~/.claude/skills إلى هذا المستودع.
# المستودع يبقى مصدر الحقيقة — git pull ثم إعادة تشغيل السكربت تحدّث كل شيء.
#
# الاستخدام:
#   ./scripts/install-global-skills.sh            # تركيب/تحديث الروابط
#   ./scripts/install-global-skills.sh --prune    # + حذف الروابط اليتيمة (لسكيلات أزيلت من المستودع)
#   ./scripts/install-global-skills.sh --copy     # نسخ بدل الروابط (لأنظمة بلا symlinks مثل بعض بيئات Windows)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_DIR/.claude/skills"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
MODE="link"
PRUNE=0
for arg in "$@"; do
  case "$arg" in
    --copy)  MODE="copy" ;;
    --prune) PRUNE=1 ;;
  esac
done

[ -d "$SRC" ] || { echo "خطأ: لا يوجد $SRC"; exit 1; }
mkdir -p "$DEST"

installed=0; updated=0; skipped=0
for skill_dir in "$SRC"/*/; do
  name="$(basename "$skill_dir")"
  [ -f "$skill_dir/SKILL.md" ] || continue
  target="$DEST/$name"
  if [ "$MODE" = "copy" ]; then
    rm -rf "$target"
    cp -r "$skill_dir" "$target"
    installed=$((installed+1))
  else
    if [ -L "$target" ]; then
      [ "$(readlink "$target")" = "${skill_dir%/}" ] && { skipped=$((skipped+1)); continue; }
      ln -sfn "${skill_dir%/}" "$target"; updated=$((updated+1))
    elif [ -e "$target" ]; then
      echo "تخطي (موجود وليس رابطًا — لن أستبدله): $name"
      skipped=$((skipped+1))
    else
      ln -s "${skill_dir%/}" "$target"; installed=$((installed+1))
    fi
  fi
done

pruned=0
if [ "$PRUNE" = "1" ]; then
  for l in "$DEST"/*; do
    if [ -L "$l" ]; then
      tgt="$(readlink "$l")"
      case "$tgt" in
        "$SRC"/*) [ -d "$tgt" ] || { rm "$l"; pruned=$((pruned+1)); } ;;
      esac
    fi
  done
fi

total="$(find -L "$DEST" -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
echo "تم: جديد=$installed محدّث=$updated متخطى=$skipped محذوف=$pruned"
echo "إجمالي السكيلات المتاحة عالميًا في $DEST: $total"

# مزامنة بلوك التوجيه التلقائي المُدار في CLAUDE.md العالمي (idempotent):
# يُستبدل محتوى ما بين علامتي BEGIN/END فقط؛ أي نص للمستخدم خارجهما لا يُمس.
TPL="$REPO_DIR/.claude/templates/automatic-skill-routing.md"
CMD_BEGIN='<!-- BEGIN MANAGED: automatic-skill-routing -->'
CMD_END='<!-- END MANAGED: automatic-skill-routing -->'
CMD_FILE="${CLAUDE_MD_DEST:-$HOME/.claude/CLAUDE.md}"
if [ -f "$TPL" ]; then
  mkdir -p "$(dirname "$CMD_FILE")"
  touch "$CMD_FILE"
  if grep -qF "$CMD_BEGIN" "$CMD_FILE"; then
    if grep -qF "$CMD_END" "$CMD_FILE"; then
      awk -v tpl="$TPL" -v b="$CMD_BEGIN" -v e="$CMD_END" '
        $0 == b { inblk=1; while ((getline line < tpl) > 0) print line; close(tpl); next }
        $0 == e { inblk=0; next }
        !inblk { print }
      ' "$CMD_FILE" > "$CMD_FILE.tmp" && mv "$CMD_FILE.tmp" "$CMD_FILE"
      echo "بلوك التوجيه التلقائي: حُدّث في $CMD_FILE"
    else
      echo "تحذير: علامة BEGIN موجودة بلا END في $CMD_FILE — لن ألمس الملف. صحّح العلامات يدويًا."
    fi
  else
    { [ -s "$CMD_FILE" ] && printf '\n'; cat "$TPL"; } >> "$CMD_FILE"
    echo "بلوك التوجيه التلقائي: أُضيف إلى $CMD_FILE"
  fi
fi

# تركيب الحُرّاس عالميًا: guard-dangerous على Bash، suggest-compact على Edit وWrite
# (نسخ + دمج آمن في settings.json — لا يستبدل الملف ولا يحذف hooks أخرى)
HOOKS_DIR="$HOME/.claude/hooks"
LIB_DIR="$HOME/.claude/lib"
mkdir -p "$HOOKS_DIR"
cp "$REPO_DIR/.claude/scripts/hooks/guard-dangerous.js" "$HOOKS_DIR/guard-dangerous.js"
cp "$REPO_DIR/.claude/scripts/hooks/suggest-compact.js" "$HOOKS_DIR/suggest-compact.js"
# suggest-compact.js يعتمد على ../lib/utils و../lib/transcript-context —
# لازم تُنسخ معه وإلا فشل بـ "Cannot find module" عند كل استدعاء عالمي.
mkdir -p "$LIB_DIR"
cp "$REPO_DIR/.claude/scripts/lib/utils.js" "$LIB_DIR/utils.js"
cp "$REPO_DIR/.claude/scripts/lib/transcript-context.js" "$LIB_DIR/transcript-context.js"
cp "$REPO_DIR/.claude/scripts/lib/agent-data-home.js" "$LIB_DIR/agent-data-home.js"
node -e '
const fs=require("fs"),p=process.env.HOME+"/.claude/settings.json";
let s={};try{s=JSON.parse(fs.readFileSync(p,"utf8"))}catch{}
s.hooks=s.hooks||{};s.hooks.PreToolUse=s.hooks.PreToolUse||[];

function ensureHook(matcher, scriptName, label){
  const cmd="node \"$HOME/.claude/hooks/"+scriptName+"\"";
  const has=s.hooks.PreToolUse.some(m=>m.matcher===matcher && (m.hooks||[]).some(h=>String(h.command||"").includes(scriptName)));
  if(has){console.log(label+": مسجّل مسبقًا على "+matcher); return false;}
  s.hooks.PreToolUse.push({matcher:matcher,hooks:[{type:"command",command:cmd}]});
  console.log(label+": سُجّل على "+matcher+" في ~/.claude/settings.json");
  return true;
}

let changed=false;
if(ensureHook("Bash","guard-dangerous.js","حارس الأفعال الخطرة")) changed=true;
if(ensureHook("Edit","suggest-compact.js","اقتراح /compact")) changed=true;
if(ensureHook("Write","suggest-compact.js","اقتراح /compact")) changed=true;
if(changed) fs.writeFileSync(p,JSON.stringify(s,null,2)+"\n");
'
