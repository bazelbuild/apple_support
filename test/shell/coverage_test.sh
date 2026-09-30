#!/bin/bash

set -euo pipefail

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_path"/unittest.bash

llvm_profdata=$(xcrun -f llvm-profdata)
llvm_cov=$(xcrun -f llvm-cov)

function test_gcov_coverage() {
  bazel_cmd coverage \
    --combined_report=lcov \
    --experimental_fetch_all_coverage_outputs \
    --experimental_split_coverage_postprocessing=false \
    --features=gcc_coverage_map_format \
    --features=-llvm_coverage_map_format \
    --instrument_test_targets \
    --test_env=GCOV_PREFIX_STRIP=0 \
    --test_env=VERBOSE_COVERAGE=1 \
    --test_output=all \
    --nocache_test_results \
    //test/test_data:c_test &>"$TEST_log" \
    || fail "bazel coverage failed"

  # Check the GCOV intermediate report: the final LCOV report is also produced
  # by LLVM coverage, so it cannot distinguish the instrumentation formats.
  gcov_file=bazel-testlogs/test/test_data/c_test/_coverage/_cc_coverage.gcov
  [[ -s "$gcov_file" ]] || fail "GCOV intermediate report not found at $gcov_file"
  grep -q "^file:test/test_data/test_lib.c$" "$gcov_file" || fail "GCOV report does not contain test_lib.c"
  grep -q "^lcount:3,1$" "$gcov_file" || fail "GCOV report does not contain executed line coverage"

  coverage_file=bazel-out/_coverage/_coverage_report.dat
  [[ -f "$coverage_file" ]] || fail "coverage.dat not found at $coverage_file"
  cat "$coverage_file"
  grep -q "^SF:test/test_data/test_lib.c" "$coverage_file" || fail "coverage.dat does not contain source file entries"
  grep -q "^FNDA:1,foo" "$coverage_file" || fail "coverage.dat does not contain executed function coverage"
  grep -q "^DA:3,1" "$coverage_file" || fail "coverage.dat does not contain executed line coverage"
}

function test_llvm_lcov_coverage() {
  bazel_cmd coverage \
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
  bazel_cmd coverage \
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
