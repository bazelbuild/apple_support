#!/bin/bash

set -euo pipefail

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_path"/unittest.bash

function test_quoted_copts_reach_the_compiler() {
  (
    unset TEST_TMPDIR
    bazel_cmd aquery --repo_env=$'BAZEL_COPTS=-DAPPLE_SUPPORT_QUOTE="value":-DAPPLE_SUPPORT_CTRL=alpha\fbeta' --output=textproto \
      'mnemonic("CppCompile", //test/test_data:cc_lib)'
  ) &> "$TEST_log" || fail "Expected C++ action analysis to succeed"
  grep -Fq 'arguments: "-DAPPLE_SUPPORT_QUOTE=\"value\""' "$TEST_log" || fail "Expected the quoted compiler flag"
  grep -Fq 'arguments: "-DAPPLE_SUPPORT_CTRL=alpha\fbeta"' "$TEST_log" || fail "Expected the control character in the compiler flag"
}

run_suite "toolchain flags tests"
