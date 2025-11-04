#！/bin/bash
set -exu

source "${WORKSPACE}"/env.sh
echo ${WORKSPACE}
SKIP_TESTS=true

# 流水线传入的参数
app=fit
image_name=app-builder
image_tag=3.5.0
VERSION=${1:-"opensource-1.0.0"}
PACKAGE_TYPE=internal
PLATFORM=aarch64
ENV_TYPE=aarch64
currentdir=$(cd $(dirname $0); pwd)
base_image="quay.io/openeuler/openeuler:latest"

# 获取服务路径
echo $(pwd)
echo "workspace: " "${WORKSPACE}"
mkdir -p ${WORKSPACE}/framework/fit/java/build
CURRENT_WORKSPACE=${WORKSPACE}/framework/fit/java
CURRENT_BUILD_DIR=${CURRENT_WORKSPACE}/build
PUBLIC_DIR=${WORKSPACE}/public
# 使用相对路径引用其他仓库
APP_PLATFORM_DIR=${WORKSPACE}/../../../app-platform
FIT_FRAMEWORK_DIR=${WORKSPACE}/../../../fit-framework
SMART_FORM_DIR=${APP_PLATFORM_DIR}/app-builder/builtin/form

mkdir -p ${CURRENT_BUILD_DIR}

# 拷贝智能表单
cp -r ${APP_PLATFORM_DIR}/examples/smart-form ${CURRENT_BUILD_DIR}/

cd "${APP_PLATFORM_DIR}/shell"
chmod -R 755 ./
./sql_build.sh
cd "${WORKSPACE}"
mkdir -p "${WORKSPACE}"/package/sql/init
mkdir -p "${WORKSPACE}"/package/sql/upgrade
# 清空并复制 SQL 文件
rm -rf "${WORKSPACE}"/package/sql/init/*
cp -rf ${APP_PLATFORM_DIR}/sql/* "${WORKSPACE}"/package/sql/init/
cp -f ${CURRENT_WORKSPACE}/upgrade.sql "${WORKSPACE}"/package/sql/upgrade/

cd "${CURRENT_BUILD_DIR}"
mkdir -p icon
rm -rf icon/*

# 拷贝应用头像
cd "${APP_PLATFORM_DIR}/shell"
./icon_build.sh
mv -f ${APP_PLATFORM_DIR}/icon/* ${CURRENT_BUILD_DIR}/icon/

MVN_CMD="mvn clean install -U"
# 定义条件命令
SKIP_TESTS_CMD=""
if [ "$SKIP_TESTS" = "true" ]; then
    SKIP_TESTS_CMD="-DskipTests"
fi

# Print the value of SKIP_TESTS_CMD
echo "SKIP_TESTS"
echo "SKIP_TESTS value: ${SKIP_TESTS}"
echo "SKIP_TESTS_CMD value: ${SKIP_TESTS_CMD}"

# 编译 FIT 框架
cd "${FIT_FRAMEWORK_DIR}"
echo "start to execute maven"
mvn -version
$MVN_CMD $SKIP_TESTS_CMD

# 编译 app-platform
cd "${APP_PLATFORM_DIR}"
echo "start to execute maven"
mvn -version
$MVN_CMD $SKIP_TESTS_CMD
mv -f ${APP_PLATFORM_DIR}/build/plugins/* ${FIT_FRAMEWORK_DIR}/build/plugins/
mv -f ${APP_PLATFORM_DIR}/build/shared/* ${FIT_FRAMEWORK_DIR}/build/shared/

packageDir="${CURRENT_BUILD_DIR}/package/"
mkdir -p ${packageDir}
rm -rf ${packageDir}/*
if [ -z "$(ls -A "${packageDir}")" ]; then
  rm -rf "${packageDir:?}"/*
fi

# 拷贝 sql
cp -r "${WORKSPACE}"/package/sql ${packageDir}/

# 删除多余插件
rm -f ${FIT_FRAMEWORK_DIR}/build/plugins/fel-tool-discoverer*
rm -f ${FIT_FRAMEWORK_DIR}/build/plugins/fel-tool-executor*
rm -f ${FIT_FRAMEWORK_DIR}/build/plugins/fel-tool-factory-repository*
rm -f ${FIT_FRAMEWORK_DIR}/build/plugins/fel-tool-repository-simple*

ls "${FIT_FRAMEWORK_DIR}/build/plugins"
mkdir -p ${packageDir}/fit
cp -r "${FIT_FRAMEWORK_DIR}/build"/* "${packageDir}/fit/"

# 替换 fitframework.yml 适配部署环境
cp "${CURRENT_WORKSPACE}/fitframework.yml" "${packageDir}/fit/conf"
cd "${packageDir}" || exit
cp "${CURRENT_WORKSPACE}"/Dockerfile "${packageDir}"
cp "${CURRENT_WORKSPACE}"/log_collect.sh "${packageDir}"

mkdir -p "${packageDir}/icon"
mv "${CURRENT_BUILD_DIR}/icon"/* "${packageDir}/icon"

mkdir -p ${packageDir}/smart-form
cp -r ${CURRENT_BUILD_DIR}/smart-form ${packageDir}
cp -r ${APP_PLATFORM_DIR}/examples/app-demo/normal-form/* ${packageDir}/smart-form/

find "${SMART_FORM_DIR}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r dir; do
  echo "正在处理目录: $dir"
  cd "$dir" || continue

  echo "  安装依赖..."
  npm install --force 2>&1 | grep -v "deprecated"

  if [ $? -ne 0 ]; then
    echo "  ⚠️  安装失败，跳过: $(basename $dir)"
    continue
  fi

  echo "  开始构建..."
  npm run build 2>&1 | tail -20

  if [ $? -ne 0 ]; then
    echo "  ⚠️  构建失败，跳过: $(basename $dir)"
    echo "  提示: smart-form 构建失败不影响核心功能"
    continue
  fi

  if [ -d "output" ]; then
    cp -rf output/* "$packageDir/smart-form/" 2>/dev/null
    echo "  ✅ 构建成功: $(basename $dir)"
  fi
done

cd "${packageDir}" || exit

cp "${CURRENT_WORKSPACE}/start.sh" "${packageDir}/fit/bin/"
chmod 700 "${packageDir}"/fit/bin/*.sh

echo "build the backend image by base image (ARM64)"

mkdir -p "${packageDir}/form"
cp ${CURRENT_WORKSPACE}/template.zip ${packageDir}/form/

# Step5 出镜像
docker build --build-arg PLAT_FORM=${ENV_TYPE} --build-arg BASE=${base_image} -t ${image_name}:${VERSION} --file=${packageDir}/Dockerfile ${packageDir}/

