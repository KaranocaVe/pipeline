#!/bin/bash
# 测试部署脚本（不需要完整构建，可以从镜像仓库拉取）

set -e

WORKSPACE=$(cd "$(dirname "$0")" && pwd)

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              ARM64 部署测试脚本                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# 检查.env文件
if [ ! -f "${WORKSPACE}/pack/.env" ]; then
    echo "📝 创建配置文件..."
    cd "${WORKSPACE}/pack"
    cp env-template .env
    echo "⚠️  请编辑 pack/.env 文件，设置以下配置:"
    echo "   - APIKEY: 设置你的 SiliconFlow API Key"
    echo "   - VERSION: 确认镜像版本号"
    echo "   - REPO: 确认镜像仓库地址"
    echo ""
    read -p "是否现在编辑配置文件? (y/n): " edit_now
    if [ "$edit_now" = "y" ]; then
        ${EDITOR:-vi} .env
    else
        echo "请手动编辑 ${WORKSPACE}/pack/.env 后重新运行此脚本"
        exit 1
    fi
fi

echo "✅ 配置文件存在"
cd "${WORKSPACE}/pack"
source .env

echo ""
echo "📋 当前配置:"
echo "   版本: ${VERSION}"
echo "   仓库: ${REPO}"
echo "   API Key: ${APIKEY:0:10}..."
echo ""

# 询问是拉取镜像还是使用本地镜像
echo "选择测试方式:"
echo "  1) 从镜像仓库拉取 (需要网络和仓库访问权限)"
echo "  2) 使用本地构建的镜像 (需要先运行 build.sh)"
echo "  3) 只检查配置，不启动服务"
read -p "请选择 (1/2/3): " choice

case $choice in
    1)
        echo ""
        echo "🔄 拉取镜像..."
        docker-compose pull || {
            echo "❌ 镜像拉取失败，可能需要登录仓库"
            echo "   docker login ${REPO}"
            exit 1
        }
        ;;
    2)
        echo ""
        echo "📦 检查本地镜像..."
        required_images=(
            "postgres:15.2-${VERSION}"
            "app-builder:${VERSION}"
            "fit-runtime-java:${VERSION}"
            "fit-runtime-python:${VERSION}"
            "jade-web:${VERSION}"
        )
        
        missing=0
        for img in "${required_images[@]}"; do
            if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${img}$"; then
                echo "   ❌ 缺失: $img"
                missing=$((missing + 1))
            else
                echo "   ✅ 存在: $img"
            fi
        done
        
        if [ $missing -gt 0 ]; then
            echo ""
            echo "❌ 缺少 $missing 个镜像，请先运行:"
            echo "   cd ${WORKSPACE}"
            echo "   bash build.sh ${VERSION}"
            exit 1
        fi
        ;;
    3)
        echo ""
        echo "✅ 配置检查:"
        docker-compose config > /dev/null && echo "   docker-compose.yml: 有效"
        docker-compose config --services
        echo ""
        echo "📊 服务端口映射:"
        docker-compose config | grep -A1 "ports:" | grep -E "^\\s+-" | sed 's/^/   /'
        echo ""
        echo "ℹ️  仅配置检查完成，未启动服务"
        exit 0
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo "🚀 启动服务..."
echo "   这可能需要几分钟时间..."
echo ""

# 创建必要的目录
mkdir -p appengine/app-builder
mkdir -p appengine/fit-runtime
mkdir -p appengine/jade-db
mkdir -p appengine/log
mkdir -p appengine/sql

# 启动服务
docker-compose up -d

echo ""
echo "⏳ 等待服务启动..."
sleep 5

echo ""
echo "📊 服务状态:"
docker-compose ps

echo ""
echo "🔍 健康检查:"
echo "   等待 app-builder 就绪..."
for i in {1..30}; do
    if curl -sf http://localhost:8004/fit/check > /dev/null 2>&1; then
        echo "   ✅ app-builder 健康检查通过"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                     🎉 部署完成！                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📱 访问地址:"
echo "   • Web界面: http://localhost:8001"
echo "   • API服务: http://localhost:8004"
echo ""
echo "📋 常用命令:"
echo "   • 查看日志: docker-compose logs -f [服务名]"
echo "   • 查看状态: docker-compose ps"
echo "   • 停止服务: docker-compose down"
echo "   • 重启服务: docker-compose restart"
echo ""
echo "🔧 故障排查:"
echo "   • 数据库日志: docker-compose logs jade-db"
echo "   • 核心服务日志: docker-compose logs app-builder"
echo "   • 所有日志: docker-compose logs"
echo ""

