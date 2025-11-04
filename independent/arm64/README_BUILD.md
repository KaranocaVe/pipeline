# ARM64 构建指南

## 📁 目录结构要求

请确保按照以下结构克隆所有仓库：

```
/your/workspace/
├── pipeline/              # 本仓库
│   └── independent/
│       ├── arm64/        # ARM64 构建脚本
│       └── x86/          # x86_64 构建脚本
├── fit-framework/        # FIT 框架仓库
├── app-platform/         # 应用平台仓库
└── elsa/                 # ELSA 工作流引擎仓库
```

## 🔧 克隆仓库

```bash
# 创建工作目录
mkdir -p ~/workspace && cd ~/workspace

# 克隆所有必需的仓库
git clone https://github.com/ModelEngine-Group/pipeline.git
git clone https://github.com/ModelEngine-Group/fit-framework.git
git clone https://github.com/ModelEngine-Group/app-platform.git
git clone https://github.com/ModelEngine-Group/elsa.git
```

## 🚀 开始构建

### 前置条件

- ARM64/aarch64 架构设备
- Docker 28.0.1+
- Maven 3.8.8+
- Java 17
- Node v20.12.1+
- npm 10.5.0+

### 构建步骤

```bash
cd ~/workspace/pipeline/independent/arm64

# 设置 Java 17 环境 (macOS)
export JAVA_HOME=$(/usr/libexec/java_home -v17)

# 或者 Linux
# export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64

# 开始构建
bash build.sh opensource-1.2.0
```

### 构建过程

脚本会自动执行以下步骤：

1. ✅ 下载 Temurin JDK 17 (ARM64) - ~182MB
2. ✅ 修改 elsa 依赖配置
3. ✅ 编译 fit-framework (Maven)
4. ✅ 编译 app-platform (Maven + npm)  
5. ✅ 构建 Docker 镜像:
   - postgres:15.2-{VERSION}
   - app-builder:{VERSION}
   - fit-runtime-java:{VERSION}
   - fit-runtime-python:{VERSION}
   - jade-web:{VERSION}

预计时间: **20-30 分钟** (首次构建)

## 📦 部署

构建完成后，进行部署：

```bash
cd pack

# 创建配置文件
cp env-template .env

# 编辑 .env 文件，设置必要的配置
# - VERSION: 镜像版本号
# - APIKEY: SiliconFlow API Key (必填)
# - REPO: 镜像仓库地址

# 启动服务
bash install_arm64.sh
```

## 🌐 访问服务

- **Web 界面**: http://localhost:8001
- **API 服务**: http://localhost:8004
- **数据库**: localhost:5432

## 🔍 常见问题

### 1. 路径错误

确保所有仓库都在同一父目录下，并且使用正确的相对路径。

### 2. Java 版本问题

构建需要 Java 17，确保 `$JAVA_HOME` 指向正确的 JDK 17。

```bash
# 验证 Java 版本
java -version
# 应该显示 "openjdk version "17.x.x"

# 查看可用的 Java 版本 (macOS)
/usr/libexec/java_home -V
```

### 3. Maven 依赖下载慢

建议配置国内镜像源：

```bash
# 编辑 ~/.m2/settings.xml
<mirrors>
  <mirror>
    <id>aliyun</id>
    <mirrorOf>central</mirrorOf>
    <url>https://maven.aliyun.com/repository/public</url>
  </mirror>
</mirrors>
```

### 4. NPM 下载慢

```bash
npm config set registry https://registry.npmmirror.com
```

## 🛠️ 管理命令

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f [服务名]

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 升级
bash upgrade_arm64.sh

# 卸载
bash uninstall_arm64.sh
```

## 📊 构建产物

构建完成后会生成以下 Docker 镜像：

| 镜像名 | 大小 | 说明 |
|--------|------|------|
| postgres:15.2-{VERSION} | ~1.3GB | PostgreSQL 数据库 |
| app-builder:{VERSION} | ~2GB | 核心应用编排服务 |
| fit-runtime-java:{VERSION} | ~1.5GB | Java 插件运行时 |
| fit-runtime-python:{VERSION} | ~2GB | Python 插件运行时 |
| jade-web:{VERSION} | ~800MB | Web 前端 |

## 💡 提示

- 首次构建需要下载大量依赖，请确保网络连接稳定
- 建议使用 tmux 或 screen 在后台运行长时间构建
- 构建日志会实时输出，可以随时监控进度
- 如果构建失败，可以重新运行 `build.sh`，已完成的步骤会被跳过

## 📝 版本信息

- 最新版本: opensource-1.2.0
- 支持架构: ARM64/aarch64
- 基础镜像: OpenEuler Latest
- JDK 版本: Temurin 17

---

更多信息请参考主 [README.md](../../../README.md)

