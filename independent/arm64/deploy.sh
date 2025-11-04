#!/bin/bash
set -eux

export WORKSPACE=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
cd ${WORKSPACE}/pack

echo "=== Deploying ARM64 version... ==="

mkdir -p appengine/app-builder
mkdir -p appengine/fit-runtime
mkdir -p appengine/jade-db
mkdir -p appengine/log

echo "Starting service on ARM64 architecture"
docker-compose up -d
echo "Service started"

echo "=== Finished ==="

