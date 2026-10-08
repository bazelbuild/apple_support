#!/bin/bash
# -*- coding: utf-8 -*-

# Copyright 2026 The Bazel Authors. All rights reserved.
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

# Unit tests for the libtool wrapper.

# --- begin runfiles.bash initialization ---
# Copy-pasted from Bazel's Bash runfiles library (tools/bash/runfiles/runfiles.bash).
set -euo pipefail
if [[ ! -d "${RUNFILES_DIR:-/dev/null}" && ! -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
  if [[ -f "$0.runfiles_manifest" ]]; then
    export RUNFILES_MANIFEST_FILE="$0.runfiles_manifest"
  elif [[ -f "$0.runfiles/MANIFEST" ]]; then
    export RUNFILES_MANIFEST_FILE="$0.runfiles/MANIFEST"
  elif [[ -f "$0.runfiles/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
    export RUNFILES_DIR="$0.runfiles"
  fi
fi
if [[ -f "${RUNFILES_DIR:-/dev/null}/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
  source "${RUNFILES_DIR}/bazel_tools/tools/bash/runfiles/runfiles.bash"
elif [[ -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
  source "$(grep -m1 "^bazel_tools/tools/bash/runfiles/runfiles.bash " \
            "$RUNFILES_MANIFEST_FILE" | cut -d ' ' -f 2-)"
else
  echo >&2 "ERROR: cannot find @bazel_tools//tools/bash/runfiles:runfiles.bash"
  exit 1
fi
# --- end runfiles.bash initialization ---


# Load test environment
source "$(rlocation "apple_support/test/shell/unittest.bash")" \
  || { echo "unittest.bash not found!" >&2; exit 1; }
LIBTOOL=$(rlocation "apple_support/crosstool/libtool")

# Test that DEVELOPER_DIR and SDKROOT aren't required outside of actions of the
# C++ toolchain, e.g. when invoked via $(AR) in a genrule.
function test_no_xcode_env() {
  env -u DEVELOPER_DIR -u SDKROOT -u XCODE_VERSION_OVERRIDE \
      "${LIBTOOL}" -V >"$TEST_log" 2>&1 || fail "libtool failed"
  expect_log "Apple Inc. version"
}

function test_placeholder_without_xcode_env() {
  env -u DEVELOPER_DIR -u SDKROOT -u XCODE_VERSION_OVERRIDE \
      "${LIBTOOL}" "__BAZEL_XCODE_SDKROOT__/foo.o" \
      >"$TEST_log" 2>&1 && fail "libtool succeeded unexpectedly"
  expect_log "SDKROOT not set"
}

# Test that actions of the C++ toolchain still require DEVELOPER_DIR and SDKROOT.
function test_xcode_version_override_without_xcode_env() {
  env -u DEVELOPER_DIR -u SDKROOT XCODE_VERSION_OVERRIDE=16.0 \
      "${LIBTOOL}" -V >"$TEST_log" 2>&1 && fail "libtool succeeded unexpectedly"
  expect_log "DEVELOPER_DIR not set"
}

run_suite "libtool wrapper tests"
