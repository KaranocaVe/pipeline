# ModelEngine ARM64 部署指南

## 硬件要求

| 名称   | 规格    |
|------|-------|
| CPU架构 | ARM64/aarch64  |
| 内存   | 2GB+  |
| 磁盘空间 | 20GB+ |

## 软件要求

| 软件名    | 版本       |
|--------|----------|
| Docker | 28.0.1+  |

## 快速启动

### 1. 配置环境变量

复制 `.env.example` 为 `.env` 并修改配置：

```bash
cp .env.example .env
```

修改以下配置项：
- `VERSION`: 镜像版本号
- `APIKEY`: SiliconFlow API Key（必填）
- 其他可选配置

### 2. 启动服务

```bash
bash install_arm64.sh
```

### 3. 访问服务

访问 http://localhost:8001

## 升级

```bash
bash upgrade_arm64.sh
```

## 卸载

```bash
bash uninstall_arm64.sh
```

## 端口说明

| 服务 | 端口 | 说明 |
|-----|-----|------|
| web | 8001 | Web前端 |
| app-builder | 8004 | 核心服务 |
| jade-db | 5432 | 数据库 |
| fit-runtime-java | 8090 | Java运行时 |
| fit-runtime-python | 9666 | Python运行时 |

## 故障排查

查看服务日志：
```bash
docker-compose logs -f [service-name]
```

查看所有服务状态：
```bash
docker-compose ps
```

