#!/bin/bash
# docker-build.sh: Load environment variables from .env and pass them to docker build as --build-arg values.
# Usage: ./docker-build.sh [Dockerfile name] [build path]
set -e

DOCKERFILE_NAME="${1:-Dockerfile}"
BUILD_PATH="${2:-./build}"
IMAGE_NAME="${IMAGE_NAME:-helix-p4d-test}"

echo "Building Docker image with $DOCKERFILE_NAME..."

# Build the --build-arg list from .env and environment variables.
BUILD_ARGS=""

# Load the standard .env file.
ENV_PATH="$BUILD_PATH/.env"
if [ -f "$ENV_PATH" ]; then
    while IFS='=' read -r key value; do
        # Skip comments, blank lines, and the export prefix.
        if [[ "$key" =~ ^# ]] || [[ -z "$key" ]]; then continue; fi
        key=$(echo "$key" | sed 's/^export //')
        value=$(echo "$value" | sed 's/^\s*//;s/\s*$//')
        BUILD_ARGS+=" --build-arg $key=$value"
    done < "$ENV_PATH"
fi

# Include environment variables provided by CI or other callers as build args without logging their values.
for key in P4NAME P4PORT P4USER P4PASSWD P4HOME P4ROOT CASE_INSENSITIVE; do
    value="${!key}"
    if [ -n "$value" ]; then
        BUILD_ARGS+=" --build-arg $key=$value"
    fi
done

echo "Building Docker image with $DOCKERFILE_NAME..."
docker build -t "$IMAGE_NAME" $BUILD_ARGS $EXTRA_ARGS -f "$BUILD_PATH/$DOCKERFILE_NAME" "$BUILD_PATH"
