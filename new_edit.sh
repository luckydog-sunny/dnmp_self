#!/usr/bin/env bash
# Remove h5/www site configs; update nginx and docker-compose from project name and domain prefixes.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CONFD="$ROOT/services/nginx/conf.d"
NGINX_CONF="$ROOT/services/nginx/nginx.conf"
BD_CONF="$CONFD/bd.conf"
DC="$ROOT/docker-compose.yml"

rm -f "$CONFD/h5.bd.conf" "$CONFD/www.bd.conf"

read -r -p "Project name (yields {name}offcial, apex {name}.top): " PROJECT
PROJECT="${PROJECT//[[:space:]]/}"
if [[ -z "$PROJECT" ]]; then
  echo "Error: project name cannot be empty." >&2
  exit 1
fi

read -r -p "Comma-separated domain prefixes (e.g. aaa,bbb → apex + aaa.${PROJECT}.top …): " PREFIX_RAW
PREFIX_RAW="${PREFIX_RAW//，/,}"

OFFCIAL="${PROJECT}offcial"
APEX="${PROJECT}.top"
SERVER_NAMES=""
# certbot: apex first, then each prefix subdomain, e.g. -d abc.top -d aaa.abc.top
CERTBOT_D="-d ${APEX}"

IFS=',' read -ra PARTS <<< "$PREFIX_RAW"
for p in "${PARTS[@]}"; do
  p="$(printf '%s' "$p" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [[ -z "$p" ]] && continue
  SERVER_NAMES+="${p}.${PROJECT}.top "
  CERTBOT_D+=" -d ${p}.${PROJECT}.top"
done
SERVER_NAMES="${SERVER_NAMES%% }"

if [[ -z "$SERVER_NAMES" ]]; then
  echo "Error: enter at least one domain prefix." >&2
  exit 1
fi

# nginx server_name: apex ${PROJECT}.top plus each prefix subdomain (e.g. aaa.${PROJECT}.top)
SERVER_NAMES="${APEX} ${SERVER_NAMES}"

sed "s/phonefinderoffcial/${OFFCIAL}/g" "$NGINX_CONF" > "${NGINX_CONF}.tmp"
mv "${NGINX_CONF}.tmp" "$NGINX_CONF"

awk -v sn="$SERVER_NAMES" -v apex="$APEX" '
{
  gsub(/server_name gccleaner\.top;/, "server_name " sn ";")
  gsub(/gccleaner\.top/, apex)
  print
}' "$BD_CONF" > "${BD_CONF}.tmp"
mv "${BD_CONF}.tmp" "$BD_CONF"

awk -v off="$OFFCIAL" -v cb="$CERTBOT_D" '
{
  gsub(/calculatorxoffcial/, off)
  gsub(/-d calculatorx\.top -d www\.calculatorx\.top/, cb)
  print
}' "$DC" > "${DC}.tmp"
mv "${DC}.tmp" "$DC"

echo "Done."
echo "  nginx map root: /www/${OFFCIAL}"
echo "  apex (certs / primary): ${APEX}"
echo "  server_name: ${SERVER_NAMES}"
echo "  certbot: ${CERTBOT_D}"
