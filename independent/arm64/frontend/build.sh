#！/bin/bash
set -ex
node -v
npm -v

ELSA_DIR=${WORKSPACE}/../../../elsa
APP_PLATFORM_DIR=${WORKSPACE}/../../../app-platform
elsa_core_dir=${ELSA_DIR}/elsa
elsa_react_dir=${ELSA_DIR}/agent-flow
appdir=${APP_PLATFORM_DIR}
workdir=${WORKSPACE}/frontend
CURRENT_BUILD_DIR=${workdir}/build
mkdir -p ${CURRENT_BUILD_DIR}
tag=prod
ssoApi=/jober/v1/user/sso_login_info
base_image="quay.io/openeuler/openeuler:latest"
echo "workspace: " "${WORKSPACE}"

arch_type=aarch64
ENV_TYPE=aarch64
PLATFORM=aarch64
VERSION=${1:-"opensource-1.0.0"}
rm -rf $appdir/frontend/build
rm -rf $appdir/frontend/node_modules
cd $workdir

echo "workdir: " "${workdir}"
cd $workdir

npm config set strict-ssl false
npm cache clean -f

# npm install agent-flow
cd ${appdir}/agent-flow
npm install --legacy-peer-deps  --registry=https://registry.npmmirror.com
npm run build
npm link

# npm install
cd ${appdir}/frontend
npm install --legacy-peer-deps --force --registry=https://registry.npmmirror.com

# 打包静态资源
npm run build:$tag

# 打包产物
ls -l

mkdir -p $workdir/output
rm -rf $workdir/output/*
cp -r build/* $workdir/output/

cd $workdir

echo "Building frontend image for ARM64..."
docker build --build-arg BASE=${base_image} --build-arg PLAT_FORM=${ENV_TYPE} -t jade-web:${VERSION} .

