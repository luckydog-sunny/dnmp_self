#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_DIR="${SCRIPT_DIR}/services/nginx/conf.d"

# 要替换的旧域名
OLD_DOMAIN="gccleaner.top"

# 要处理的配置文件
CONFIG_FILES=("bd.conf" "h5.bd.conf" "www.bd.conf")

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Nginx 配置文件域名替换工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}当前旧域名：${OLD_DOMAIN}${NC}"
echo -e "${YELLOW}将会修改以下文件：${NC}"
for file in "${CONFIG_FILES[@]}"; do
    echo -e "  - ${CONF_DIR}/${file}"
done
echo ""

# 提示用户输入新域名
read -p "请输入新的域名（例如：example.com）: " NEW_DOMAIN

# 验证输入是否为空
if [ -z "$NEW_DOMAIN" ]; then
    echo -e "${RED}错误：域名不能为空！${NC}"
    exit 1
fi

# 确认操作
echo ""
echo -e "${YELLOW}即将执行以下替换操作：${NC}"
echo -e "  ${OLD_DOMAIN} -> ${NEW_DOMAIN}"
echo ""
read -p "确认执行？(y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${RED}操作已取消${NC}"
    exit 0
fi

# 执行替换
echo ""
echo -e "${GREEN}开始替换...${NC}"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

for file in "${CONFIG_FILES[@]}"; do
    FILE_PATH="${CONF_DIR}/${file}"
    
    # 检查文件是否存在
    if [ ! -f "$FILE_PATH" ]; then
        echo -e "${RED}✗ 文件不存在: ${file}${NC}"
        ((FAIL_COUNT++))
        continue
    fi
    
    # 执行替换（兼容 macOS 和 Linux）
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/${OLD_DOMAIN}/${NEW_DOMAIN}/g" "$FILE_PATH"
    else
        # Linux
        sed -i "s/${OLD_DOMAIN}/${NEW_DOMAIN}/g" "$FILE_PATH"
    fi
    
    # 检查替换是否成功
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 成功替换: ${file}${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✗ 替换失败: ${file}${NC}"
        ((FAIL_COUNT++))
    fi
done

# 显示结果统计
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  替换完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "成功: ${GREEN}${SUCCESS_COUNT}${NC} 个文件"
if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "失败: ${RED}${FAIL_COUNT}${NC} 个文件"
fi
echo ""
echo -e "${YELLOW}提示：修改完成后，请重启 nginx 容器使配置生效${NC}"
echo -e "${YELLOW}命令：docker-compose restart nginx${NC}"
echo ""

