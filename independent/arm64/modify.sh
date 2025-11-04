#!/bin/bash
set -eux

export WORKSPACE=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
source "${WORKSPACE}/env.sh"

# 修改 app-platform 前端的 package.json
cd "${WORKSPACE}/../../../app-platform/frontend"
${SED} 's#fit-framework#elsa#g' package.json

# 如果是 MacOS，修改 elsa 核心的 sed 命令
if [[ "${OS_TYPE}" == "Darwin" ]]; then
  cd "${WORKSPACE}/../../../elsa/elsa"
  ${SED} "s#sed -i #sed -i '' #g" package.json
fi

