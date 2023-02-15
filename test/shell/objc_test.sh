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

function make_lib() {
  rm -rf ios
  mkdir -p ios

  cat >ios/main.m <<EOF
#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  int retVal = UIApplicationMain(argc, argv, nil, nil);
  [pool release];
  return retVal;
}
EOF

  cat >ios/BUILD <<EOF
objc_library(name = "lib",
             non_arc_srcs = ['main.m'])
EOF
}

function test_build_app() {
  setup_objc_test_support
  make_lib

  bazel build --verbose_failures --apple_platform_type=ios \
      --noincompatible_enable_cc_toolchain_resolution \
      //ios:lib >"$TEST_log" 2>&1 || fail "should pass"
  ls bazel-out/*/bin/ios/liblib.a \
      || fail "should generate lib.a"
}

# Verifies contents of .a files do not contain timestamps -- if they did, the
# results would not be hermetic.
function test_archive_timestamps() {
  setup_objc_test_support

  mkdir -p objclib
  cat > objclib/BUILD <<EOF
objc_library(
    name = "objclib",
    srcs = ["mysrc.m"],
)
EOF

  cat > objclib/mysrc.m <<EOF
int aFunction() {
  return 0;
}
EOF

  bazel build --verbose_failures --apple_platform_type=ios \
      //objclib:objclib >"$TEST_log" 2>&1 \
      || fail "Should build objc_library"

  # Based on timezones, ar -tv may show the timestamp of the contents as either
  # Dec 31 1969 or Jan 1 1970 -- either is fine.
  # We would use 'date' here, but the format is slightly different (Jan 1 vs.
  # Jan 01).
  ar -tv bazel-out/*/bin/objclib/libobjclib.a \
      | grep "mysrc" | grep "Dec 31" | grep "1969" \
      || ar -tv bazel-out/*/bin/objclib/libobjclib.a \
      | grep "mysrc" | grep "Jan  1" | grep "1970" || \
      fail "Timestamp of contents of archive file should be zero"
}

function test_strip_symbols() {
  setup_objc_test_support

  rm -rf ios
  mkdir -p ios

  cat >ios/main.m <<EOF
#import <UIKit/UIKit.h>
/* function declaration */
int addOne(int num);
int addOne(int num) {
  return num + 1;
}
 int main(int argc, char *argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  int retVal = UIApplicationMain(argc, argv, nil, nil);
  [pool release];
  return retVal;
}
EOF

  cat >ios/BUILD <<EOF
load("@build_bazel_apple_support//test:starlark_apple_binary.bzl", "starlark_apple_binary")
starlark_apple_binary(name = 'app',
                      deps = [':main'],
                      platform_type = 'ios')
objc_library(name = 'main',
             non_arc_srcs = ['main.m'])
EOF

  bazel build --verbose_failures \
      --noincompatible_enable_cc_toolchain_resolution \
      --apple_platform_type=ios \
      --objc_enable_binary_stripping=true \
      --compilation_mode=opt \
      //ios:app >"$TEST_log" 2>&1 || fail "should pass"
  ls bazel-out/*/bin/ios/app_lipobin \
    || fail "should generate lipobin (stripped binary)"
  ! nm bazel-out/*/bin/ios/app_lipobin | grep addOne \
    || fail "should fail to find symbol addOne"
}

function test_cc_test_depending_on_objc() {
  setup_objc_test_support

  rm -rf foo
  mkdir -p foo

  cat >foo/a.cc <<EOF
#include <iostream>
int main(int argc, char** argv) {
  std::cout << "Hello! I'm a test!\n";
  return 0;
}
EOF

  cat >foo/BUILD <<EOF
cc_library(
    name = "a",
    srcs = ["a.cc"],
)

objc_library(
    name = "b",
    deps = [
        ":a",
    ],
)

cc_test(
    name = "d",
    deps = [":b"],
)
EOF

  bazel test --verbose_failures \
      //foo:d>"$TEST_log" 2>&1 || fail "should pass"
}

run_suite "objc/ios test suite"
