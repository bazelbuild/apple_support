#!/bin/bash

set -euo pipefail

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_path"/unittest.bash

bazel="${BAZEL:-bazel}"

function test_good_header_parsing() {
  "$bazel" test --process_headers_in_dependencies -- //test/header_parsing/... &>"$TEST_log"
}

function test_bad_header_parsing() {
  ! "$bazel" test --process_headers_in_dependencies -- //test/header_parsing:invalid_header &> "$TEST_log" || fail "Expected build failure"
  expect_log "test/header_parsing/invalid_header.h:2:1: error: unknown type name 'uint8_t'"
}

function test_bad_header_parsing_objc() {
  ! "$bazel" test --process_headers_in_dependencies -- //test/header_parsing:invalid_header_objc &> "$TEST_log" || fail "Expected build failure"
  expect_log "test/header_parsing/invalid_header.h:2:1: error: unknown type name 'uint8_t'"
}

run_suite "header_parsing tests"
