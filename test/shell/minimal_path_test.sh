#!/bin/bash

set -euo pipefail

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_path"/unittest.bash

readonly generated_rules='kind(rule, @local_config_xcode//:*) + kind(rule, @local_config_apple_cc//:*)'

# Usage: query_generated_rules <bazel> <PATH> <output file>
# Writes the rules that the Xcode and C++ toolchain repository rules generate,
# as seen by a new Bazel server started with the given PATH. Bazel looks up
# programs on the server's PATH, so <bazel> must not need PATH itself. The
# output base is expunged afterwards, so the next call reruns the repository
# rules at the same path and prints the same locations.
function query_generated_rules() {
  local bazel="$1" path="$2" output="$3"
  local output_base="$TEST_TMPDIR/output_base"
  local bazel_extra_args=()
  if [[ -n "${BAZEL_EXTRA_ARGS:-}" ]]; then
    read -r -a bazel_extra_args <<< "${BAZEL_EXTRA_ARGS}"
  fi

  # Bazel puts its install base under TEST_TMPDIR when it is set and would
  # extract it again on every call, so run Bazel without it.
  (
    unset TEST_TMPDIR
    local status=0
    PATH="$path" "$bazel" --output_base="$output_base" query \
      ${bazel_extra_args[@]+"${bazel_extra_args[@]}"} \
      --output=build "$generated_rules" > "$output" 2>> "$TEST_log" \
      || status=$?
    PATH="$path" "$bazel" --output_base="$output_base" clean --expunge &>> "$TEST_log" || true
    exit "$status"
  )
}

function test_xcode_detection_does_not_need_path() {
  local bazel
  bazel="$(command -v "${BAZEL:-bazel}")" || fail "bazel not found on PATH"
  local empty_dir="$TEST_TMPDIR/empty_path"
  mkdir -p "$empty_dir"

  query_generated_rules "$bazel" "$PATH" "$TEST_TMPDIR/with_path.txt" \
    || fail "Expected the query with the host PATH to succeed"
  grep -q '^xcode_version(' "$TEST_TMPDIR/with_path.txt" \
    || fail "Expected an installed Xcode to be detected"

  query_generated_rules "$bazel" "$empty_dir" "$TEST_TMPDIR/without_path.txt" \
    || fail "Expected the query with an empty PATH to succeed"
  diff -u "$TEST_TMPDIR/with_path.txt" "$TEST_TMPDIR/without_path.txt" >> "$TEST_log" \
    || fail "Expected the same Xcode and toolchain configuration with an empty PATH"
}

run_suite "minimal PATH tests"
