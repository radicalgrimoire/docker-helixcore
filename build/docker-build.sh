#!/bin/bash
# docker-build.sh: .envファイルから環境変数を読み込み、--build-argとしてdocker buildに渡す
# 使い方: ./docker-build.sh [Dockerfile名] [ビルドパス]
set -e

DOCKERFILE_NAME="${1:-Dockerfile}"
BUILD_PATH="${2:-./build}"
IMAGE_NAME="${IMAGE_NAME:-helix-p4d-test}"

echo "Building Docker image with $DOCKERFILE_NAME..."

# .envファイルと環境変数の読み込みで--build-arg生成
BUILD_ARGS=""

# 通常の.envファイルを読み込み
ENV_PATH="$BUILD_PATH/.env"
if [ -f "$ENV_PATH" ]; then
    while IFS='=' read -r key value; do
        # コメント・空行・export除外
        if [[ "$key" =~ ^# ]] || [[ -z "$key" ]]; then continue; fi
        key=$(echo "$key" | sed 's/^export //')
        value=$(echo "$value" | sed 's/^\s*//;s/\s*$//')
        BUILD_ARGS+=" --build-arg $key=$value"
    done < "$ENV_PATH"
fi

# CIなどで渡された環境変数をbuild-argへ反映（値はログ出力しない）
for key in P4NAME P4PORT P4USER P4PASSWD P4HOME P4ROOT CASE_INSENSITIVE; do
    value="${!key}"
    if [ -n "$value" ]; then
        BUILD_ARGS+=" --build-arg $key=$value"
    fi
done

echo "Building Docker image with $DOCKERFILE_NAME..."
docker build -t "$IMAGE_NAME" $BUILD_ARGS $EXTRA_ARGS -f "$BUILD_PATH/$DOCKERFILE_NAME" "$BUILD_PATH"
