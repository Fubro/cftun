#!/bin/bash
# build.sh 完整修改版

set -e

APP_NAME="cftun"
VERSION="2.0.9"
BUILD_TYPE="product"
BUILD_DIR="build"
PLATFORMS=("android/arm64" "android/arm")  # 修改目标平台为Android

# 创建 build 目录
mkdir -p $BUILD_DIR

# Android ABI映射表
declare -A ABI_MAP=(
    ["arm64"]="arm64-v8a"
    ["arm"]="armeabi-v7a"
)

# 交叉编译
for PLATFORM in "${PLATFORMS[@]}"; do
    OS=${PLATFORM%%/*}
    ARCH=${PLATFORM##*/}
    ABI=${ABI_MAP[$ARCH]}
    
    OUTPUT_NAME="$APP_NAME-$ABI"
    LDFLAGS="-X main.Version=$VERSION -X main.BuildDate=$(date '+%Y-%m-%d_%H:%M:%S_%Z') -X main.BuildType=$BUILD_TYPE"
    
    # 设置ARM版本
    if [ "$ARCH" == "arm" ]; then
        export GOARM=7  # 重要：指定ARMv7指令集
    else
        unset GOARM
    fi

    echo "Building for Android $ABI..."
    
    # Android专用构建命令
    env CGO_ENABLED=0 \
    GOOS=android \
    GOARCH=$ARCH \
    go build -ldflags "$LDFLAGS" \
    -o $BUILD_DIR/$OUTPUT_NAME

    # 创建标准Android目录结构
    TARGET_DIR="$BUILD_DIR/android/$ABI"
    mkdir -p $TARGET_DIR
    mv $BUILD_DIR/$OUTPUT_NAME $TARGET_DIR/
    
    echo "Generated binary in: $TARGET_DIR/"
done

# 创建通用压缩包
tar -czvf "$BUILD_DIR/android-binaries.tar.gz" -C "$BUILD_DIR" android

echo "Android build completed! Final package: $BUILD_DIR/android-binaries.tar.gz"
