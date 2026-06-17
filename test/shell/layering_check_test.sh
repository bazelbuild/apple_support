#!/bin/bash

set -euo pipefail

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_path"/unittest.bash

function test_bad_layering_checks() {
  ! bazel_cmd test -- //test/layering_check:bad_layering_check &> "$TEST_log" || fail "Expected build failure"

  expect_log_once "does not depend on a module exporting"
  expect_log "test/layering_check/c.cpp:3:10: error: module //test/layering_check:bad_layering_check does not depend on a module exporting 'a.h'" "failed wrong layering_check"
}

function test_bad_layering_checks_objc() {
  ! bazel_cmd test -- //test/layering_check:bad_layering_check_objc_test &> "$TEST_log" || fail "Expected build failure"

  expect_log_once "does not depend on a module exporting"
  expect_log "test/layering_check/c.m:3:10: error: module @@//test/layering_check:bad_layering_check_objc does not depend on a module exporting 'a.h'" "failed wrong layering_check"
}

run_suite "layering_check tests"
