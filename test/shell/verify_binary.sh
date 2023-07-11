#!/bin/bash

set -euo pipefail

readonly binary="%{binary}s"
expected_platform="MACOS"
if [[ "$PLATFORM_TYPE" == "ios" && "$BUILD_TYPE" == "device" ]]; then
  expected_platform="IPHONEOS"
elif [[ "$PLATFORM_TYPE" == "ios" && "$BUILD_TYPE" == "simulator" ]]; then
  expected_platform="IPHONESIMULATOR"
fi

otool_output=$(otool -lv "$binary")
if ! echo "$otool_output" | grep -q "platform $expected_platform"; then
  echo "error: binary $binary does not contain platform $expected_platform, got: '$(echo "$otool_output" | grep platform || true)'"
  exit 1
fi

lipo_output=$(lipo -info "$binary")
if ! echo "$lipo_output" | grep -q "$CPU"; then
  echo "error: binary $binary does not contain CPU $CPU, got: '$lipo_output"
  exit 1
fi
