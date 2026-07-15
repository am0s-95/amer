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
  for link in "$DEST"/*/; do
    l="${link%/}"
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
