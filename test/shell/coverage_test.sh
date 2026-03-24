#!/bin/bash

set -euo pipefail

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_path"/unittest.bash

bazel="${BAZEL:-bazel}"

llvm_profdata=$(xcrun -f llvm-profdata)
llvm_cov=$(xcrun -f llvm-cov)

function test_llvm_lcov_coverage() {
  "$bazel" coverage \
    --experimental_fetch_all_coverage_outputs \
    --experimental_generate_llvm_lcov \
    --features=llvm_coverage_map_format \
    --instrument_test_targets \
    --test_env=LLVM_PROFDATA="$llvm_profdata" \
    --test_env=LLVM_COV="$llvm_cov" \
    --test_env=VERBOSE_COVERAGE=1 \
    --test_output=all \
    --nocache_test_results \
    //test/test_data:c_test &>"$TEST_log" \
    || fail "bazel coverage failed"

  coverage_file=bazel-out/_coverage/_coverage_report.dat
  cat "$coverage_file"
  [[ -f "$coverage_file" ]] || fail "coverage.dat not found at $coverage_file"
  grep -q "^SF:test/test_data/test_lib.c" "$coverage_file" || fail "coverage.dat does not contain source file entries"
  grep -q "^FN:3,foo" "$coverage_file" || fail "coverage.dat does not contain line coverage data"
}

function test_llvm_profdata_coverage() {
  # experimental_split_coverage_postprocessing is required for the profdata to stick around
  "$bazel" coverage \
    --experimental_fetch_all_coverage_outputs \
    --experimental_generate_llvm_lcov=false \
    --features=llvm_coverage_map_format \
    --instrument_test_targets \
    --test_env=LLVM_PROFDATA="$llvm_profdata" \
    --test_env=VERBOSE_COVERAGE=1 \
    --test_output=all \
    --nocache_test_results \
    --experimental_split_coverage_postprocessing=false \
    //test/test_data:c_test &>"$TEST_log" \
    || fail "bazel coverage failed"

  profdata=bazel-testlogs/test/test_data/c_test/_coverage/_cc_coverage.profdata
  [[ -f "$profdata" ]] || fail "_cc_coverage.profdata not found at $profdata"
  coverage_file=bazel-out/_coverage/_coverage_report.dat
  [[ -f "$coverage_file" ]] || fail "coverage.dat not found at $coverage_file"
  grep -q "^SF:test/test_data/test_lib.c" "$coverage_file" || fail "coverage.dat does not contain source file entries"
  # NOTE: This format seems to not have actually useful coverage, which appears to be coming from lcov-merger in bazel
  grep -q "^LF:" "$coverage_file" || fail "coverage.dat does not contain line coverage data"
}

run_suite "coverage tests"
