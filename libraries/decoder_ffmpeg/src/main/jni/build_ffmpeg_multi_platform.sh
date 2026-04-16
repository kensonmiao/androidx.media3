#!/bin/bash
#
# Copyright (C) 2019 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -eu

FFMPEG_MODULE_PATH="$1"
echo "FFMPEG_MODULE_PATH is ${FFMPEG_MODULE_PATH}"
NDK_PATH="$2"
echo "NDK path is ${NDK_PATH}"
HOST_PLATFORM="$3"
echo "Host platform is ${HOST_PLATFORM}"
ENABLED_DECODERS=("${@:4}")
echo "Enabled decoders are ${ENABLED_DECODERS[@]}"
JOBS="$(nproc 2> /dev/null || sysctl -n hw.ncpu 2> /dev/null || echo 4)"
echo "Using $JOBS jobs for make"
#     --enable-decoder=h264
#    --enable-decoder=aac
COMMON_OPTIONS="
    --target-os=android
    --enable-static
    --disable-shared
    --disable-doc
    --disable-programs
    --disable-everything
    --disable-avdevice
    --disable-avformat
    --disable-swscale
    --disable-avfilter
    --disable-symver
    --enable-swresample
    --extra-ldexeflags=-pie
    --disable-v4l2-m2m
    --disable-vulkan
    "
TOOLCHAIN_PREFIX="${NDK_PATH}/toolchains/llvm/prebuilt/${HOST_PLATFORM}/bin"
if [[ ! -d "${TOOLCHAIN_PREFIX}" ]]
then
    echo "Please set correct NDK_PATH, $NDK_PATH is incorrect"
    exit 1
fi

for decoder in "${ENABLED_DECODERS[@]}"
do
    COMMON_OPTIONS="${COMMON_OPTIONS} --enable-decoder=${decoder}"
done

cd "${FFMPEG_MODULE_PATH}/jni/ffmpeg"

#"arm64-v8a" "armeabi-v7a" "x86" "x86_64"
ABIS=(${ANDROID_ABI})

for ABI in "${ABIS[@]}"; do

  if [ "$ABI" = "arm64-v8a" ]; then
    ARCH="aarch64"
    CPU="armv8-a"
    TARGET="aarch64-linux-android"
    API=23
    LIBDIR="android-libs/arm64-v8a"
    EXTRA_CFLAGS=""
    EXTRA_LDFLAGS=""
    DISABLE_ASM=""

  elif [ "$ABI" = "armeabi-v7a" ]; then
    ARCH="arm"
    CPU="armv7-a"
    TARGET="armv7a-linux-androideabi"
    API=23
    LIBDIR="android-libs/armeabi-v7a"
    EXTRA_CFLAGS="-march=armv7-a -mfloat-abi=softfp"
    EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
    DISABLE_ASM=""

  elif [ "$ABI" = "x86" ]; then
    ARCH="x86"
    CPU="i686"
    TARGET="i686-linux-android"
    API=23
    LIBDIR="android-libs/x86"
    EXTRA_CFLAGS=""
    EXTRA_LDFLAGS=""
    DISABLE_ASM="--disable-asm"

  elif [ "$ABI" = "x86_64" ]; then
    ARCH="x86_64"
    CPU="x86-64"
    TARGET="x86_64-linux-android"
    API=23
    LIBDIR="android-libs/x86_64"
    EXTRA_CFLAGS=""
    EXTRA_LDFLAGS=""
    DISABLE_ASM="--disable-asm"
  fi

  ARMV7_CLANG="${TOOLCHAIN_PREFIX}/${TARGET}${API}-clang"
  if [[ ! -e "$ARMV7_CLANG" ]]
  then
    echo "AVM Clang compiler with path $ARMV7_CLANG does not exist"
    echo "It's likely your NDK version doesn't support ANDROID_ABI $ABI"
    echo "Either use older version of NDK or raise ANDROID_ABI (be aware that ANDROID_ABI must not be greater than your application's minSdk)"
    exit 1
  fi

  echo "===== Building for $ABI ====="

  ./configure \
    --libdir=$LIBDIR \
    --arch=$ARCH \
    --cpu=$CPU \
    --target-os=android \
    --enable-cross-compile \
    --cross-prefix="${TOOLCHAIN_PREFIX}/${TARGET}${API}-" \
    --nm="${TOOLCHAIN_PREFIX}/llvm-nm" \
    --ar="${TOOLCHAIN_PREFIX}/llvm-ar" \
    --ranlib="${TOOLCHAIN_PREFIX}/llvm-ranlib" \
    --strip="${TOOLCHAIN_PREFIX}/llvm-strip" \
    --extra-cflags="$EXTRA_CFLAGS" \
    --extra-ldflags="$EXTRA_LDFLAGS" \
    ${COMMON_OPTIONS} \
    $DISABLE_ASM

  make -j$JOBS
  make install-libs
  make clean

done
