#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_DIR="${SCRIPT_DIR}/services/nginx/conf.d"

# 要处理的配置文件
CONFIG_FILES=("bd.conf" "h5.bd.conf" "www.bd.conf")

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Nginx 配置文件注释清理工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}将对以下文件执行操作：${NC}"
for file in "${CONFIG_FILES[@]}"; do
    echo -e "  - ${CONF_DIR}/${file}"
done
echo ""
echo -e "  1. 去除所有注释 #"
echo -e "  2. 删除 listen 443 ssl; 下一行的 listen 80;"
echo ""
read -p "确认执行？(y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${RED}操作已取消${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}开始处理...${NC}"
echo ""

for file in "${CONFIG_FILES[@]}"; do
    FILE_PATH="${CONF_DIR}/${file}"

    if [ ! -f "$FILE_PATH" ]; then
        echo -e "${RED}✗ 文件不存在: ${file}${NC}"
        continue
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: 第一步 去除注释 #（移除行首可选空白后的 "# "）
        sed -i '' 's/^\([[:space:]]*\)# /\1/' "$FILE_PATH"
        # macOS: 第二步 删除 listen 443 ssl; 下一行的 listen 80;
        sed -i '' '/listen 443 ssl;/{n;/listen 80;/d;}' "$FILE_PATH"
    else
        # Linux: 第一步 去除注释 #
        sed -i 's/^\([[:space:]]*\)# /\1/' "$FILE_PATH"
        # Linux: 第二步 删除 listen 443 ssl; 下一行的 listen 80;
        sed -i '/listen 443 ssl;/{n;/listen 80;/d;}' "$FILE_PATH"
    fi

    echo -e "${GREEN}✓ 处理完成: ${file}${NC}"
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  全部处理完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}提示：请重启 nginx 容器使配置生效${NC}"
echo -e "${YELLOW}命令：docker-compose restart nginx${NC}"
echo ""
