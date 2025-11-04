#!/bin/bash
# 构建环境检查脚本

set +e  # 允许命令失败继续执行

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           ARM64 构建环境检查工具                                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

WORKSPACE=$(cd "$(dirname "$0")" && pwd)
# 仓库应该在 /Users/karanocave/Code 目录
PARENT_DIR=/Users/karanocave/Code

# 检查计数器
PASS=0
FAIL=0

check_item() {
    local name=$1
    local command=$2
    local required=$3
    
    if eval "$command" > /dev/null 2>&1; then
        echo "✅ $name"
        PASS=$((PASS + 1))
        return 0
    else
        if [ "$required" = "required" ]; then
            echo "❌ $name (必需)"
            FAIL=$((FAIL + 1))
        else
            echo "⚠️  $name (可选)"
        fi
        return 1
    fi
}

echo "1️⃣  系统环境检查"
echo "-----------------------------------"
check_item "架构: ARM64" "[ \$(uname -m) = 'arm64' ]" "required"
check_item "操作系统: Linux/MacOS" "[ \$(uname -s) = 'Linux' ] || [ \$(uname -s) = 'Darwin' ]" "required"
echo ""

echo "2️⃣  必需工具检查"
echo "-----------------------------------"
check_item "Docker" "which docker" "required"
check_item "Docker Compose" "which docker-compose" "required"
check_item "Maven (3.8.8+)" "which mvn" "required" && mvn -version | head -1
check_item "Java (17)" "java -version 2>&1 | grep -E 'version \"17'" "required" && java -version 2>&1 | head -1
check_item "Node (v20.12.1)" "which node" "required" && node -v
check_item "NPM (10.5.0)" "which npm" "required" && npm -v
check_item "Git" "which git" "required"
check_item "wget" "which wget" "required"
echo ""

echo "3️⃣  代码仓库检查"
echo "-----------------------------------"
cd "${PARENT_DIR}" || exit 1
check_item "pipeline 仓库" "[ -d 'pipeline' ]" "required"
check_item "fit-framework 仓库" "[ -d 'fit-framework' ]" "required"
check_item "app-platform 仓库" "[ -d 'app-platform' ]" "required"
check_item "elsa 仓库" "[ -d 'elsa' ]" "required"

if [ -d "fit-framework" ]; then
    echo "   └─ $(cd fit-framework && git rev-parse --short HEAD 2>/dev/null || echo '未知版本')"
fi
if [ -d "app-platform" ]; then
    echo "   └─ $(cd app-platform && git rev-parse --short HEAD 2>/dev/null || echo '未知版本')"
fi
if [ -d "elsa" ]; then
    echo "   └─ $(cd elsa && git rev-parse --short HEAD 2>/dev/null || echo '未知版本')"
fi
echo ""

echo "4️⃣  Docker 环境检查"
echo "-----------------------------------"
check_item "Docker 服务运行中" "docker info" "required"
check_item "OpenEuler 基础镜像" "docker images | grep -q openeuler" "optional"
DOCKER_ARCH=$(docker info 2>/dev/null | grep Architecture | awk '{print $2}')
echo "   └─ Docker 架构: ${DOCKER_ARCH}"
echo ""

echo "5️⃣  磁盘空间检查"
echo "-----------------------------------"
DISK_AVAIL=$(df -h . | awk 'NR==2 {print $4}')
echo "   可用空间: ${DISK_AVAIL}"
if [ -d "${WORKSPACE}/output" ]; then
    OUTPUT_SIZE=$(du -sh "${WORKSPACE}/output" 2>/dev/null | awk '{print $1}')
    echo "   构建目录大小: ${OUTPUT_SIZE}"
fi
echo ""

echo "6️⃣  网络连接检查"
echo "-----------------------------------"
check_item "访问 GitHub" "curl -s --connect-timeout 3 https://github.com" "optional"
check_item "访问 Maven Central" "curl -s --connect-timeout 3 https://repo.maven.apache.org" "optional"
check_item "访问 NPM Registry" "curl -s --connect-timeout 3 https://registry.npmjs.org" "optional"
check_item "访问 Adoptium (JDK)" "curl -s --connect-timeout 3 https://api.adoptium.net" "optional"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "检查结果: ✅ $PASS 项通过  ❌ $FAIL 项失败"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "🎉 环境检查全部通过！可以开始构建。"
    echo ""
    echo "▶️  执行以下命令开始构建:"
    echo "   cd ${WORKSPACE}"
    echo "   bash build.sh opensource-1.2.0"
    echo ""
    exit 0
else
    echo "⚠️  环境存在 $FAIL 个问题，请先解决后再构建。"
    echo ""
    echo "📋 常见问题解决方案:"
    echo ""
    echo "1. 安装 Maven:"
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "   brew install maven"
    else
        echo "   sudo apt-get install maven  # Ubuntu/Debian"
        echo "   sudo yum install maven       # CentOS/RHEL"
    fi
    echo ""
    echo "2. 安装 Node/NPM:"
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "   brew install node@20"
    else
        echo "   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
        echo "   sudo apt-get install -y nodejs"
    fi
    echo ""
    echo "3. 克隆缺失的仓库:"
    echo "   cd ${PARENT_DIR}"
    echo "   git clone <fit-framework-repo-url>"
    echo "   git clone <elsa-repo-url>"
    echo ""
    exit 1
fi

