#!/usr/bin/env bash
# 对 bd.conf：按行号取消注释并删除第二段中的 listen 80;
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BD_CONF="$ROOT/services/nginx/conf.d/bd.conf"

mapfile -t lines < "$BD_CONF"

for ((i = 0; i < ${#lines[@]}; i++)); do
  ln=$((i + 1))
  if ((ln >= 1 && ln <= 8)) || ((ln == 11)) || ((ln >= 14 && ln <= 20)); then
    line="${lines[$i]}"
    if [[ "$line" =~ ^([[:space:]]*)#\ ?(.*)$ ]]; then
      lines[i]="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
    fi
  fi
done

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

for ((i = 0; i < ${#lines[@]}; i++)); do
  ln=$((i + 1))
  if ((ln == 12)); then
    line="${lines[$i]}"
    if [[ "$line" =~ listen[[:space:]]+80 ]] && [[ ! "$line" =~ 443 ]]; then
      continue
    fi
  fi
  printf '%s\n' "${lines[$i]}"
done > "$tmp"
mv "$tmp" "$BD_CONF"
trap - EXIT

echo "已更新：$BD_CONF"
