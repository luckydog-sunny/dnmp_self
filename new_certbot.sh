#!/usr/bin/env bash
# 解除 docker-compose.yml 中 certbot 服务块的注释
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DC="$ROOT/docker-compose.yml"

start=$(grep -n '^[[:space:]]*#[[:space:]]*certbot:[[:space:]]*$' "$DC" | head -1 | cut -d: -f1) || true
end=$(grep -n '^[[:space:]]*#[[:space:]]*command:[[:space:]]*renew[[:space:]]*$' "$DC" | head -1 | cut -d: -f1) || true

if [[ -z "${start:-}" || -z "${end:-}" ]]; then
  echo "未找到 certbot 注释块（# certbot: … #   command: renew）" >&2
  exit 1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

lineno=0
while IFS= read -r line || [[ -n "$line" ]]; do
  lineno=$((lineno + 1))
  if (( lineno >= start && lineno <= end )); then
    if [[ "$line" =~ ^([[:space:]]*)#\ ?(.*)$ ]]; then
      line="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
    fi
  fi
  printf '%s\n' "$line"
done < "$DC" > "$tmp"
mv "$tmp" "$DC"
trap - EXIT

echo "已解除 certbot 容器相关行的注释：$DC"
