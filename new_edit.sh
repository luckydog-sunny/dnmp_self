#!/usr/bin/env bash
# 1. 删除 h5/www 站点配置；2. 按项目名称与域名前缀更新 nginx 与 docker-compose
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CONFD="$ROOT/services/nginx/conf.d"
NGINX_CONF="$ROOT/services/nginx/nginx.conf"
BD_CONF="$CONFD/bd.conf"
DC="$ROOT/docker-compose.yml"

rm -f "$CONFD/h5.bd.conf" "$CONFD/www.bd.conf"

read -r -p "项目名称（将生成 {名称}offcial，主域名为 {名称}.top）: " PROJECT
PROJECT="${PROJECT//[[:space:]]/}"
if [[ -z "$PROJECT" ]]; then
  echo "错误：项目名称不能为空" >&2
  exit 1
fi

read -r -p "域名前缀，逗号分隔（如 aaa,bbb,ccc → aaa.${PROJECT}.top …）: " PREFIX_RAW
PREFIX_RAW="${PREFIX_RAW//，/,}"

SERVER_NAMES=""
CERTBOT_D=""
IFS=',' read -ra PARTS <<< "$PREFIX_RAW"
for p in "${PARTS[@]}"; do
  p="$(printf '%s' "$p" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [[ -z "$p" ]] && continue
  SERVER_NAMES+="${p}.${PROJECT}.top "
  CERTBOT_D+="-d ${p}.${PROJECT}.top "
done
SERVER_NAMES="${SERVER_NAMES%% }"
CERTBOT_D="${CERTBOT_D%% }"

if [[ -z "$SERVER_NAMES" ]]; then
  echo "错误：至少输入一个域名前缀" >&2
  exit 1
fi

OFFCIAL="${PROJECT}offcial"
APEX="${PROJECT}.top"

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

echo "完成："
echo "  nginx map 目录: /www/${OFFCIAL}"
echo "  server_name / 证书目录主域: ${APEX}"
echo "  server_name 列表: ${SERVER_NAMES}"
echo "  certbot: ${CERTBOT_D}"
