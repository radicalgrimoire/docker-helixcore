#!/bin/bash
# docker-build.sh: .envファイルから環境変数を読み込み、--build-argとしてdocker buildに渡す
# 使い方: ./docker-build.sh [Dockerfile名] [ビルドパス]
set -e

DOCKERFILE_NAME="${1:-Dockerfile}"
BUILD_PATH="${2:-./build}"
IMAGE_NAME="${IMAGE_NAME:-helix-p4d-test}"

echo "Building Docker image with $DOCKERFILE_NAME..."

# .envファイルとsecrets.envファイルの読み込みと--build-arg生成
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

# secrets.envファイルがあれば読み込み（機密情報用）
SECRETS_ENV_PATH="$BUILD_PATH/secrets.env"
if [ -f "$SECRETS_ENV_PATH" ]; then
    echo "DEBUG: secrets.envファイルが見つかりました: $SECRETS_ENV_PATH"
    echo "DEBUG: secrets.envの内容:"
    cat "$SECRETS_ENV_PATH"
    echo "DEBUG: secrets.envファイル読み込み開始"
    
    while IFS='=' read -r key value; do
        echo "DEBUG: 読み込み行: key='$key' value='$value'"
        # コメント・空行・export除外
        if [[ "$key" =~ ^# ]] || [[ -z "$key" ]]; then 
            echo "DEBUG: スキップ（コメントまたは空行）"
            continue
        fi
        key=$(echo "$key" | sed 's/^export //')
        value=$(echo "$value" | sed 's/^\s*//;s/\s*$//')
        echo "DEBUG: 処理後: key='$key' value='$value'"
        
        # IMAGE_NAMEの場合は環境変数も更新
        if [ "$key" = "IMAGE_NAME" ]; then
            IMAGE_NAME="$value"
            echo "DEBUG: IMAGE_NAMEを更新しました: $IMAGE_NAME"
        fi
        
        # 空の値でも--build-argとして渡す（Dockerfile側でデフォルト値を設定）
        BUILD_ARGS+=" --build-arg $key=$value"
    done < "$SECRETS_ENV_PATH"
    echo "DEBUG: secrets.envファイル読み込み完了"
else
    echo "DEBUG: secrets.envファイルが見つかりません: $SECRETS_ENV_PATH"
fi

echo "Building Docker image with $DOCKERFILE_NAME..."
docker build -t "$IMAGE_NAME" $BUILD_ARGS $EXTRA_ARGS -f "$BUILD_PATH/$DOCKERFILE_NAME" "$BUILD_PATH"