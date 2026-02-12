#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# sed 替换函数（兼容 macOS 和 Linux）
do_sed() {
    local old_str="$1"
    local new_str="$2"
    local file="$3"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/${old_str}/${new_str}/g" "$file"
    else
        sed -i "s/${old_str}/${new_str}/g" "$file"
    fi
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_DIR="${SCRIPT_DIR}/services/nginx/conf.d"
NGINX_CONF="${SCRIPT_DIR}/services/nginx/nginx.conf"
DOCKER_COMPOSE="${SCRIPT_DIR}/docker-compose.yml"

# 要替换的旧值
OLD_DOMAIN="gccleaner.top"
OLD_NGINX_PROJECT="phonefinderoffcial"
OLD_COMPOSE_PROJECT="calculatorxoffcial"
OLD_COMPOSE_DOMAIN="calculatorx.top"

# 要处理的 conf.d 配置文件
CONFIG_FILES=("bd.conf" "h5.bd.conf" "www.bd.conf")

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Nginx 配置文件批量替换工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# ===== 输入 1：新域名 =====
echo -e "${YELLOW}[1] conf.d 域名替换${NC}"
echo -e "    将 ${OLD_DOMAIN} 替换为新域名"
echo -e "    涉及文件：bd.conf / h5.bd.conf / www.bd.conf"
echo ""
read -p "请输入新的域名（例如：example.com）: " NEW_DOMAIN

if [ -z "$NEW_DOMAIN" ]; then
    echo -e "${RED}错误：域名不能为空！${NC}"
    exit 1
fi

# ===== 输入 2：新项目目录名 =====
echo ""
echo -e "${YELLOW}[2] 项目目录名替换${NC}"
echo -e "    nginx.conf 中：${OLD_NGINX_PROJECT} -> 新值"
echo -e "    docker-compose.yml 中：${OLD_COMPOSE_PROJECT} -> 新值"
echo -e "    docker-compose.yml 中：${OLD_COMPOSE_DOMAIN} -> 新值去掉 offcial 后加 .top"
echo ""
read -p "请输入新的项目目录名（例如：newprojectoffcial）: " NEW_PROJECT

if [ -z "$NEW_PROJECT" ]; then
    echo -e "${RED}错误：项目目录名不能为空！${NC}"
    exit 1
fi

# 从项目目录名裁剪掉末尾的 offcial，再加上 .top，生成新域名
NEW_COMPOSE_DOMAIN="${NEW_PROJECT%offcial}.top"

# ===== 确认操作 =====
echo ""
echo -e "${YELLOW}即将执行以下替换操作：${NC}"
echo -e "  [conf.d 文件]     ${OLD_DOMAIN} -> ${NEW_DOMAIN}"
echo -e "  [nginx.conf]      ${OLD_NGINX_PROJECT} -> ${NEW_PROJECT}"
echo -e "  [docker-compose]  ${OLD_COMPOSE_PROJECT} -> ${NEW_PROJECT}"
echo -e "  [docker-compose]  ${OLD_COMPOSE_DOMAIN} -> ${NEW_COMPOSE_DOMAIN}"
echo ""
read -p "确认执行？(y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${RED}操作已取消${NC}"
    exit 0
fi

# ===== 开始执行替换 =====
echo ""
echo -e "${GREEN}开始替换...${NC}"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

# --- 替换 conf.d 下的配置文件中的域名 ---
for file in "${CONFIG_FILES[@]}"; do
    FILE_PATH="${CONF_DIR}/${file}"

    if [ ! -f "$FILE_PATH" ]; then
        echo -e "${RED}✗ 文件不存在: ${file}${NC}"
        ((FAIL_COUNT++))
        continue
    fi

    do_sed "${OLD_DOMAIN}" "${NEW_DOMAIN}" "$FILE_PATH"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 成功替换: ${file}  (${OLD_DOMAIN} -> ${NEW_DOMAIN})${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✗ 替换失败: ${file}${NC}"
        ((FAIL_COUNT++))
    fi
done

# --- 替换 nginx.conf 中的项目目录名 ---
if [ ! -f "$NGINX_CONF" ]; then
    echo -e "${RED}✗ 文件不存在: nginx.conf${NC}"
    ((FAIL_COUNT++))
else
    do_sed "${OLD_NGINX_PROJECT}" "${NEW_PROJECT}" "$NGINX_CONF"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 成功替换: nginx.conf  (${OLD_NGINX_PROJECT} -> ${NEW_PROJECT})${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✗ 替换失败: nginx.conf${NC}"
        ((FAIL_COUNT++))
    fi
fi

# --- 替换 docker-compose.yml 中的项目目录名和域名 ---
if [ ! -f "$DOCKER_COMPOSE" ]; then
    echo -e "${RED}✗ 文件不存在: docker-compose.yml${NC}"
    ((FAIL_COUNT++))
else
    # 替换 calculatorxoffcial -> 新项目目录名
    do_sed "${OLD_COMPOSE_PROJECT}" "${NEW_PROJECT}" "$DOCKER_COMPOSE"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 成功替换: docker-compose.yml  (${OLD_COMPOSE_PROJECT} -> ${NEW_PROJECT})${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✗ 替换失败: docker-compose.yml (项目目录名)${NC}"
        ((FAIL_COUNT++))
    fi

    # 替换 calculatorx.top -> 新域名
    do_sed "${OLD_COMPOSE_DOMAIN}" "${NEW_COMPOSE_DOMAIN}" "$DOCKER_COMPOSE"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 成功替换: docker-compose.yml  (${OLD_COMPOSE_DOMAIN} -> ${NEW_COMPOSE_DOMAIN})${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✗ 替换失败: docker-compose.yml (域名)${NC}"
        ((FAIL_COUNT++))
    fi
fi

# ===== 显示结果统计 =====
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  替换完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "成功: ${GREEN}${SUCCESS_COUNT}${NC} 项操作"
if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "失败: ${RED}${FAIL_COUNT}${NC} 项操作"
fi
echo ""
echo -e "${YELLOW}提示：修改完成后，请重启容器使配置生效${NC}"
echo -e "${YELLOW}命令：docker-compose restart nginx${NC}"
echo ""

