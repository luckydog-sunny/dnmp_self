#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Docker Compose certbot 容器启用工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}错误：docker-compose.yml 文件不存在！${NC}"
    exit 1
fi

# 检查是否存在 certbot 注释块
if ! grep -q '# certbot:' "$COMPOSE_FILE"; then
    echo -e "${YELLOW}未找到被注释的 certbot 容器配置，可能已经启用。${NC}"
    exit 0
fi

echo -e "${YELLOW}将去除 docker-compose.yml 中 certbot 容器的注释${NC}"
echo ""
read -p "确认执行？(y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${RED}操作已取消${NC}"
    exit 0
fi

echo ""

# 去除 certbot 块的注释（从 "# certbot:" 到 "#   command: renew"）
# 匹配行首可选空白后的 "# "，移除 "# " 保留原有缩进
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' '/# certbot:/,/#   command: renew/s/^\([[:space:]]*\)# /\1/' "$COMPOSE_FILE"
else
    sed -i '/# certbot:/,/#   command: renew/s/^\([[:space:]]*\)# /\1/' "$COMPOSE_FILE"
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ certbot 容器注释已去除${NC}"
else
    echo -e "${RED}✗ 操作失败${NC}"
    exit 1
fi

# 验证 YAML 格式
echo ""
echo -e "${YELLOW}去除注释后的 certbot 配置：${NC}"
echo -e "${YELLOW}----------------------------------------${NC}"
# 提取 certbot 块内容进行展示
awk '/^  certbot:/{found=1} found{print} found && /command: renew/{exit}' "$COMPOSE_FILE"
echo -e "${YELLOW}----------------------------------------${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  处理完成！${NC}"
echo -e "${GREEN}========================================${NC}"
