#!/bin/bash
#
# Copyright 2015 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---

source "$(rlocation build_bazel_apple_support/test/shell/integration_test_setup.sh)" \
  || { echo "integration_test_setup.sh not found!" >&2; exit 1; }

function set_up() {
  setup_objc_test_support
}

function test_apple_binary_crosstool_watchos() {
  rm -rf package
  mkdir -p package

  cat > package/BUILD <<EOF
load("@build_bazel_apple_support//test:starlark_apple_binary.bzl", "starlark_apple_binary")
genrule(
  name = "lipo_run",
  srcs = [":main_binary_lipobin"],
  outs = ["lipo_out"],
  cmd =
      "set -e && " +
      "lipo -info \$(location :main_binary_lipobin) > \$(@)",
  tags = ["requires-darwin"],
)

starlark_apple_binary(
    name = "main_binary",
    deps = [":main_lib"],
    platform_type = "watchos",
    minimum_os_version = '8.0',
)
objc_library(
    name = "main_lib",
    srcs = ["main.m"],
    deps = [":lib_a"],
)
cc_library(
    name = "cc_lib",
    srcs = ["cc_lib.cc"],
)
# By depending on a library which requires it is built for watchos, this test
# verifies that dependencies of starlark_apple_binary are compiled for the
# specified platform_type.
objc_library(
    name = "lib_a",
    srcs = ["a.m"],
    deps = [":cc_lib"],
)
EOF
  cat > package/main.m <<EOF
#import <WatchKit/WatchKit.h>

// Note that WKExtensionDelegate is only available in Watch SDK.
@interface TestInterfaceMain : NSObject <WKExtensionDelegate>
@end

int main() {
  return 0;
}
EOF
  cat > package/a.m <<EOF
#import <WatchKit/WatchKit.h>

// Note that WKExtensionDelegate is only available in Watch SDK.
@interface TestInterfaceA : NSObject <WKExtensionDelegate>
@end

int aFunction() {
  return 0;
}
EOF
  cat > package/cc_lib.cc << EOF
#include <string>

std::string GetString() { return "h3ll0"; }
EOF

  bazel build --verbose_failures //package:lipo_out \
      --noincompatible_enable_cc_toolchain_resolution \
      --watchos_cpus=armv7k \
      || fail "should build watch binary"

  grep "armv7k" bazel-bin/package/lipo_out \
      || fail "expected output binary to be for armv7k architecture"

  bazel build --verbose_failures //package:lipo_out \
      --noincompatible_enable_cc_toolchain_resolution \
      --watchos_cpus=i386 \
      || fail "should build watch binary"

  grep "i386" bazel-bin/package/lipo_out \
      || fail "expected output binary to be for i386 architecture"
}

function test_apple_static_library() {
  rm -rf package
  mkdir -p package

  cat > package/BUILD <<EOF
load("@build_bazel_apple_support//test:starlark_apple_static_library.bzl", "starlark_apple_static_library")
starlark_apple_static_library(
    name = "static_lib",
    deps = [":dummy_lib"],
    platform_type = "ios",
    minimum_os_version = "10.0",
)
objc_library(
    name = "dummy_lib",
    srcs = ["dummy.m"],
)
EOF
  cat > "package/dummy.m" <<EOF
static int dummy __attribute__((unused,used)) = 0;
EOF

  bazel build --verbose_failures //package:static_lib \
      --noincompatible_enable_cc_toolchain_resolution \
      --ios_multi_cpus=i386,x86_64 \
      --ios_minimum_os=8.0 \
      || fail "should build starlark_apple_static_library"
}

function test_apple_binary_dsym_builds() {
  rm -rf package
  mkdir -p package

  cat > package/BUILD <<EOF
load("@build_bazel_apple_support//test:starlark_apple_binary.bzl", "starlark_apple_binary")
starlark_apple_binary(
    name = "main_binary",
    deps = [":main_lib"],
    platform_type = "macos",
    minimum_os_version = "12.0",
)
objc_library(
    name = "main_lib",
    srcs = ["main.m"],
)
EOF
  cat > package/main.m <<EOF
int main() {
  return 0;
}
EOF

  bazel build --verbose_failures //package:main_binary \
      --noincompatible_enable_cc_toolchain_resolution \
      --apple_generate_dsym=true \
      || fail "should build starlark_apple_binary with dSYMs"
}

function test_additive_cpus_flag() {
  rm -rf package
  mkdir -p package

  cat > package/BUILD <<EOF
load("@build_bazel_apple_support//test:starlark_apple_binary.bzl", "starlark_apple_binary")
objc_library(
    name = "lib_a",
    srcs = ["a.m"],
)
objc_library(
    name = "lib_b",
    srcs = ["b.m"],
)
starlark_apple_binary(
    name = "main_binary",
    deps = [":lib_a", ":lib_b"],
    platform_type = "ios",
    minimum_os_version = "10.0",
)
genrule(
  name = "lipo_run",
  srcs = [":main_binary_lipobin"],
  outs = ["lipo_out"],
  cmd =
      "set -e && " +
      "lipo -info \$(location :main_binary_lipobin) > \$(@)",
  tags = ["requires-darwin"],
)
EOF
  touch package/a.m
  cat > package/b.m <<EOF
int main() {
  return 0;
}
EOF

  bazel build --verbose_failures \
      //package:lipo_out \
      --noincompatible_enable_cc_toolchain_resolution \
      --ios_multi_cpus=i386 --ios_multi_cpus=x86_64 \
      || fail "should build starlark_apple_binary and obtain info via lipo"

  grep "i386 x86_64" bazel-bin/package/lipo_out \
    || fail "expected output binary to contain 2 architectures"
}

function test_apple_binary_spaces() {
  rm -rf package
  mkdir -p package

  cat > package/BUILD <<EOF
load("@build_bazel_apple_support//test:starlark_apple_binary.bzl", "starlark_apple_binary")
starlark_apple_binary(
    name = "main_binary",
    deps = [":main_lib"],
    platform_type = "ios",
    minimum_os_version = "10.0",
)
objc_library(
    name = "main_lib",
    srcs = ["the main.m"],
)
EOF
  cat > "package/the main.m" <<EOF
int main() {
  return 0;
}
EOF

  bazel build --verbose_failures //package:main_binary \
      --noincompatible_enable_cc_toolchain_resolution \
      --ios_multi_cpus=i386,x86_64 \
      --apple_generate_dsym=true \
      || fail "should build starlark_apple_binary with dSYMs"
}

function test_apple_binary_crosstool_ios() {
  rm -rf package
  mkdir -p package

  cat > package/BUILD <<EOF
load("@build_bazel_apple_support//test:starlark_apple_binary.bzl", "starlark_apple_binary")
objc_library(
    name = "lib_a",
    srcs = ["a.m"],
)
objc_library(
    name = "lib_b",
    srcs = ["b.m"],
    deps = [":cc_lib"],
)
cc_library(
    name = "cc_lib",
    srcs = ["cc_lib.cc"],
)
starlark_apple_binary(
    name = "main_binary",
    deps = [":main_lib"],
    platform_type = "ios",
    minimum_os_version = "10.0",
)
objc_library(
    name = "main_lib",
    deps = [":lib_a", ":lib_b"],
    srcs = ["main.m"],
)
genrule(
  name = "lipo_run",
  srcs = [":main_binary_lipobin"],
  outs = ["lipo_out"],
  cmd =
      "set -e && " +
      "lipo -info \$(location :main_binary_lipobin) > \$(@)",
  tags = ["requires-darwin"],
)
EOF
  touch package/a.m
  touch package/b.m
  cat > package/main.m <<EOF
int main() {
  return 0;
}
EOF
  cat > package/cc_lib.cc << EOF
#include <string>

std::string GetString() { return "h3ll0"; }
EOF

  bazel build --verbose_failures //package:lipo_out \
    --noincompatible_enable_cc_toolchain_resolution \
    --ios_multi_cpus=i386,x86_64 \
    || fail "should build starlark_apple_binary and obtain info via lipo"

  grep "i386 x86_64" bazel-bin/package/lipo_out \
    || fail "expected output binary to be for x86_64 architecture"
}

function test_apple_binary_dsym_builds() {
  rm -rf package
  mkdir -p package

  cat > package/BUILD <<EOF
load("@build_bazel_apple_support//test:starlark_apple_binary.bzl", "starlark_apple_binary")
starlark_apple_binary(
    name = "main_binary",
    deps = [":main_lib"],
    platform_type = "ios",
    minimum_os_version = "10.0",
)
objc_library(
    name = "main_lib",
    srcs = ["main.m"],
)
EOF
  cat > package/main.m <<EOF
int main() {
  return 0;
}
EOF

  bazel build --verbose_failures //package:main_binary \
      --noincompatible_enable_cc_toolchain_resolution \
      --apple_generate_dsym=true \
      || fail "should build starlark_apple_binary with dSYMs"
}

function test_fat_binary_no_srcs() {
  rm -rf package
  mkdir -p package

  cat > package/BUILD <<EOF
load("@build_bazel_apple_support//test:starlark_apple_binary.bzl", "starlark_apple_binary")
objc_library(
    name = "lib_a",
    srcs = ["a.m"],
)
objc_library(
    name = "lib_b",
    srcs = ["b.m"],
)
starlark_apple_binary(
    name = "main_binary",
    deps = [":lib_a", ":lib_b"],
    platform_type = "ios",
    minimum_os_version = "10.0",
)
genrule(
  name = "lipo_run",
  srcs = [":main_binary_lipobin"],
  outs = ["lipo_out"],
  cmd =
      "set -e && " +
      "lipo -info \$(location :main_binary_lipobin) > \$(@)",
  tags = ["requires-darwin"],
)
EOF
  touch package/a.m
  cat > package/b.m <<EOF
int main() {
  return 0;
}
EOF

  bazel build --verbose_failures \
      //package:lipo_out --ios_multi_cpus=i386,x86_64 \
      --noincompatible_enable_cc_toolchain_resolution \
      || fail "should build starlark_apple_binary and obtain info via lipo"

  cat bazel-bin/package/lipo_out | grep "i386 x86_64" \
    || fail "expected output binary to contain 2 architectures"
}

run_suite "apple_tests"
