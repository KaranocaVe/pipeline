#!/bin/bash

echo "=== Deploying ModelEngine ARM64 version... ==="

mkdir -p appengine/app-builder
mkdir -p appengine/fit-runtime
mkdir -p appengine/jade-db
mkdir -p appengine/log
mkdir -p appengine/sql

echo "Starting service on ARM64 architecture"
docker-compose up -d
echo "Service started"

echo "=== Finished ==="

