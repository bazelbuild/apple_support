#!/bin/bash

set -euo pipefail

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_path"/unittest.bash

bazel="${BAZEL:-bazel}"

function test_good_layering_checks() {
  "$bazel" test --repo_env=APPLE_SUPPORT_LAYERING_CHECK_BETA=1 -- //test/layering_check/... -//test/layering_check:bad_layering_check &>"$TEST_log"
}

function test_bad_layering_checks() {
  ! "$bazel" test --repo_env=APPLE_SUPPORT_LAYERING_CHECK_BETA=1 -- //test/layering_check:bad_layering_check &> "$TEST_log" || fail "Expected build failure"

  expect_log_once "does not depend on a module exporting"
  expect_log "test/layering_check/c.cpp:1:10: error: module //test/layering_check:bad_layering_check does not depend on a module exporting 'a.h'" "failed wrong layering_check"
}

run_suite "layering_check tests"
