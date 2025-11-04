#!/bin/bash
set -eux

export WORKSPACE=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
source "${WORKSPACE}/env.sh"

IMAGE_VERSION=${1:-"opensource-1.0.0"}
REPO_PASSWD=${2:-""}

cd ${WORKSPACE}

# 修改 elsa 依赖路径
bash modify.sh

mkdir -p ${WORKSPACE}/output

# 下载 ARM64 架构的 JDK17 (Temurin)
mkdir -p ${WORKSPACE}/public
# 使用 Temurin (Eclipse Adoptium) JDK 17 for ARM64
wget -O ${WORKSPACE}/public/temurin-jdk-17-aarch64.tar.gz https://api.adoptium.net/v3/binary/latest/17/ga/linux/aarch64/jdk/hotspot/normal/eclipse

cd ${WORKSPACE}
echo "=== Building app-builder (ARM64)... ==="
bash framework/fit/java/build.sh ${IMAGE_VERSION}
echo "=== Finished app-builder ==="

echo "=== Building fit-runtime-java (ARM64)... ==="
bash framework/fit/fit-java/build.sh ${IMAGE_VERSION}
echo "=== Finished fit-runtime-java ==="

echo "=== Building fit-runtime-python (ARM64)... ==="
bash framework/fit/fit-python/build.sh ${IMAGE_VERSION}
echo "=== Finished fit-runtime-python ==="

echo "=== Building web (ARM64)... ==="
bash frontend/build.sh ${IMAGE_VERSION}
echo "=== Finished web ==="

echo "=== Building db (ARM64)... ==="
bash db/postgresql/aarch64/build.sh ${IMAGE_VERSION}
echo "=== Finished db ==="

bash push_images.sh ${IMAGE_VERSION} ${REPO_PASSWD}

