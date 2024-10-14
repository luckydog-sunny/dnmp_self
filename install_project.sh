#!/bin/bash

# 检查是否传入了项目名称
if [ -z "$1" ]; then
  echo "请传入项目名称"
  exit 1
fi

# 项目名称参数
PROJECT_NAME=$1

# 克隆代码并重命名目录
git clone https://gitee.com/yxx_brightdawn/admintemplete.git "$PROJECT_NAME"

# 进入刚拉取的项目目录
cd "$PROJECT_NAME" || exit

# 执行cp .env.example .env
cp .env.example .env

# 修改.env文件中的APP_NAME和DB_DATABASE
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i "" "1s/^APP_NAME=.*/APP_NAME=${PROJECT_NAME}/" .env
  sed -i "" "8s/^DB_DATABASE=.*/DB_DATABASE=${PROJECT_NAME}/" .env
else
  sed -i "1s/^APP_NAME=.*/APP_NAME=${PROJECT_NAME}/" .env
  sed -i "8s/^DB_DATABASE=.*/DB_DATABASE=${PROJECT_NAME}/" .env
fi

cd web || exit

cp .env.example .env

if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i "" "1s/^VITE_APP_TITLE =.*/VITE_APP_TITLE = ${PROJECT_NAME}/" .env
else
  sed -i "1s/^VITE_APP_TITLE =.*/VITE_APP_TITLE = ${PROJECT_NAME}/" .env
fi

echo "项目已成功克隆并配置，项目名称为: $PROJECT_NAME"
