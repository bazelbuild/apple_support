#!/bin/bash

set -euo pipefail

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_path"/unittest.bash

function test_bad_header_parsing() {
  ! bazel_cmd test -- //test/header_parsing:invalid_header &> "$TEST_log" || fail "Expected build failure"
  expect_log "test/header_parsing/invalid_header.h:2:1: error: unknown type name 'uint8_t'"
}

function test_bad_header_parsing_objc() {
  ! bazel_cmd test -- //test/header_parsing:invalid_header_objc &> "$TEST_log" || fail "Expected build failure"
  expect_log "test/header_parsing/invalid_header.h:2:1: error: unknown type name 'uint8_t'"
}

function test_c_header_without_parse_headers_as_c() {
  ! bazel_cmd build -- //test/header_parsing:c_only_header_without_parse_headers_as_c &> "$TEST_log" || fail "Expected build failure"
  expect_log 'test/header_parsing/c_only_header.h:2:2: error: "expected C header parsing"'
}

run_suite "header_parsing tests"
