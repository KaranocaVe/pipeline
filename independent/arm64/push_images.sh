#!/bin/bash
set -eux

VERSION=${1:-"opensource-1.0.0"}
REPO_PASSWD=${2}
REPO=${3:-"swr.cn-south-1.myhuaweicloud.com/modelengine"}

if [ -n "${REPO_PASSWD}" ]; then
  echo "Pushing images to repository (ARM64)..."
  
  docker tag postgres:15.2-${VERSION} ${REPO}/postgres:15.2-${VERSION}-arm64
  docker tag app-builder:${VERSION} ${REPO}/app-builder:${VERSION}-arm64
  docker tag fit-runtime-java:${VERSION} ${REPO}/fit-runtime-java:${VERSION}-arm64
  docker tag fit-runtime-python:${VERSION} ${REPO}/fit-runtime-python:${VERSION}-arm64
  docker tag jade-web:${VERSION} ${REPO}/jade-web:${VERSION}-arm64
  
  echo "${REPO_PASSWD}" | docker login ${REPO} -u cn-south-1@YIZHPFQAWEVKDIMB5KZP --password-stdin
  
  docker push ${REPO}/postgres:15.2-${VERSION}-arm64
  docker push ${REPO}/app-builder:${VERSION}-arm64
  docker push ${REPO}/fit-runtime-java:${VERSION}-arm64
  docker push ${REPO}/fit-runtime-python:${VERSION}-arm64
  docker push ${REPO}/jade-web:${VERSION}-arm64
  
  echo "Images pushed successfully!"
else
  echo "No repository password provided, skipping push."
fi

