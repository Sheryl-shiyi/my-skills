#!/bin/bash
# Sync all skills in this repo to ~/.claude/skills/ via symlinks.
# Run after adding a new skill directory.

SKILLS_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.claude/skills"

mkdir -p "$TARGET_DIR"

for skill in "$SKILLS_DIR"/*/; do
  name=$(basename "$skill")
  [ ! -f "$skill/SKILL.md" ] && continue

  if [ -L "$TARGET_DIR/$name" ]; then
    echo "  skip  $name (symlink exists)"
  elif [ -e "$TARGET_DIR/$name" ]; then
    echo "  WARN  $name exists but is not a symlink — skipping (remove manually to fix)"
  else
    ln -s "$skill" "$TARGET_DIR/$name"
    echo "  link  $name -> $skill"
  fi
done
