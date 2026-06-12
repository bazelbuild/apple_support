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

# Unit tests for libtool.

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


# This env var tells libtool to log its command instead of running.
export __LIBTOOL_LOG_ONLY=1

function assert_command() {
  local expected=$1
  assert_equals "${expected}" "$(cat "${TEST_log}")"
}

function test_libtool_args() {
  env DEVELOPER_DIR=developer SDKROOT=sdk \
      "${LIBTOOL}" -D -no_warning_for_no_symbols -static -o output.a a.o b.o \
      >"${TEST_log}" || fail "libtool failed";
  assert_command "/usr/bin/xcrun libtool -D -no_warning_for_no_symbols -static -o output.a a.o b.o"
}

function test_ar_args() {
  env DEVELOPER_DIR=developer SDKROOT=sdk \
      "${LIBTOOL}" crs output.a a.o b.o \
      >"${TEST_log}" || fail "libtool failed";
  assert_command "/usr/bin/xcrun libtool -static -D -o output.a a.o b.o"
}

function test_ar_args_in_params_file() {
  params=$(mktemp)
  {
    echo "crs"
    echo "output.a"
    echo "a.o"
    echo "b.o"
  } > "${params}"

  env DEVELOPER_DIR=developer SDKROOT=sdk \
      "${LIBTOOL}" "@${params}" \
      >"${TEST_log}" || fail "libtool failed";
  assert_command "/usr/bin/xcrun libtool -static -D -o output.a a.o b.o"
}

function test_ar_args_with_input_params_file() {
  params=$(mktemp)
  {
    echo "a.o"
    echo "b.o"
  } > "${params}"

  env DEVELOPER_DIR=developer SDKROOT=sdk \
      "${LIBTOOL}" crs output.a "@${params}" \
      >"${TEST_log}" || fail "libtool failed";
  assert_command "/usr/bin/xcrun libtool -static -D -o output.a a.o b.o"
}

function test_ar_args_require_output_archive() {
  env DEVELOPER_DIR=developer SDKROOT=sdk \
      "${LIBTOOL}" crs \
      >"${TEST_log}" 2>&1 && fail "libtool succeeded";
  expect_log "expected output archive after ar flags 'crs'"
}

function test_ar_args_require_archive_extension() {
  env DEVELOPER_DIR=developer SDKROOT=sdk \
      "${LIBTOOL}" crs output.o input.o \
      >"${TEST_log}" 2>&1 && fail "libtool succeeded";
  expect_log "expected output archive after ar flags 'crs', got 'output.o'"
}

function test_ar_args_require_input_file() {
  env DEVELOPER_DIR=developer SDKROOT=sdk \
      "${LIBTOOL}" crs output.a \
      >"${TEST_log}" 2>&1 && fail "libtool succeeded";
  expect_log "expected at least one input file after output archive 'output.a'"
}

function test_ar_args_rust() {
  env DEVELOPER_DIR=developer SDKROOT=sdk \
      "${LIBTOOL}" cq output.a a.o b.o \
      >"${TEST_log}" || fail "libtool failed";
  assert_command "/usr/bin/xcrun libtool -static -D -o output.a a.o b.o"
}

function test_deterministic_ar_args() {
  env DEVELOPER_DIR=developer SDKROOT=sdk \
      "${LIBTOOL}" crsD output.a a.o b.o \
      >"${TEST_log}" || fail "libtool failed";
  assert_command "/usr/bin/xcrun libtool -static -D -o output.a a.o b.o"
}

function test_reordered_ar_args() {
  env DEVELOPER_DIR=developer SDKROOT=sdk \
      "${LIBTOOL}" rcs output.a a.o b.o \
      >"${TEST_log}" || fail "libtool failed";
  assert_command "/usr/bin/xcrun libtool -static -D -o output.a a.o b.o"
}

function test_ar_args_reject_unsupported_flags() {
  env DEVELOPER_DIR=developer SDKROOT=sdk \
      "${LIBTOOL}" ctx output.a a.o b.o \
      >"${TEST_log}" 2>&1 && fail "libtool succeeded";
  expect_log "unsupported ar flags 'ctx'"
}

function test_ar_toc_only_existing_archive() {
  archive="${TEST_TMPDIR}/existing.a"
  touch "${archive}"
  env DEVELOPER_DIR=developer SDKROOT=sdk \
      "${LIBTOOL}" s "${archive}" \
      >"${TEST_log}" || fail "libtool failed";
  assert_command ""
}

function test_ar_toc_only_requires_existing_archive() {
  archive="${TEST_TMPDIR}/missing.a"
  env DEVELOPER_DIR=developer SDKROOT=sdk \
      "${LIBTOOL}" s "${archive}" \
      >"${TEST_log}" 2>&1 && fail "libtool succeeded";
  expect_log "archive file '${archive}' does not exist"
}

run_suite "libtool tests"
