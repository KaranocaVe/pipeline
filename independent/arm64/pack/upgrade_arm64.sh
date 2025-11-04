#!/bin/bash

echo "=== Upgrading ModelEngine ARM64 version... ==="

# 停止服务
docker-compose down

# 设置升级标志
export IS_UPGRADE=true

# 启动服务
docker-compose up -d

echo "=== Upgrade finished ==="

