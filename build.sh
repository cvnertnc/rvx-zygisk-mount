#!/usr/bin/env bash

set -euo pipefail

NDK_VERSION="r27c"
API=21

if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
    echo "Error: ANDROID_NDK_HOME is not set."
    exit 1
fi

TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"

mkdir -p module/zygisk
mkdir -p module/bin/arm
mkdir -p module/bin/arm64
mkdir -p module/bin/x86
mkdir -p module/bin/x64

build_zygisk() {
    local ABI="$1"
    local TARGET="$2"

    echo "Building Zygisk (${ABI})..."

    "$TOOLCHAIN/${TARGET}${API}-clang++" \
        -std=c++20 \
        -fPIC \
        -shared \
        -O2 \
        -Wall \
        -Wextra \
        zygisk/jni/module.cpp \
        -llog \
        -o "module/zygisk/${ABI}.so"
}

build_profile() {
    local OUTDIR="$1"
    local TARGET="$2"

    echo "Building ksu_profile (${OUTDIR})..."

    "$TOOLCHAIN/${TARGET}${API}-clang" \
        -O2 \
        -s \
        ksu_profile/jni/ksu_profile.c \
        -o "module/bin/${OUTDIR}/ksu_profile"
}

build_zygisk armeabi-v7a armv7a-linux-androideabi
build_zygisk arm64-v8a aarch64-linux-android
build_zygisk x86 i686-linux-android
build_zygisk x86_64 x86_64-linux-android

build_profile arm armv7a-linux-androideabi
build_profile arm64 aarch64-linux-android
build_profile x86 i686-linux-android
build_profile x64 x86_64-linux-android

chmod 755 module/bin/*/ksu_profile

echo "Creating module archive..."

(
    cd module
    zip -r ../rvx-zygisk-mount.zip .
)

echo "Done: rvx-zygisk-mount.zip"
