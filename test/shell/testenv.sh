#!/bin/bash

function setup_objc_test_support() {
  IOS_SDK_VERSION=$(xcrun --sdk iphoneos --show-sdk-version)
  export IOS_SDK_VERSION

  cat > WORKSPACE.bazel <<EOF
local_repository(
    name = 'build_bazel_apple_support',
    path = '$(rlocation build_bazel_apple_support)',
)

load("@build_bazel_apple_support//:tcsetup.bzl", "apple_cc_configure")

apple_cc_configure()
EOF

  cat > .bazelrc <<EOF
build --apple_crosstool_top=@local_config_apple_cc//:toolchain
EOF
}
