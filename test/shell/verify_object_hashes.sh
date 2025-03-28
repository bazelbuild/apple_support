#!/bin/bash

set -euo pipefail

readonly binary="%{binary}s"
output=$(ar t "$binary")

if ! echo "$output" | grep -q "duplicate_3e0a6abe8af91e33.o"; then
  echo "error: missing expected object 1: $output" >&2
  exit 1
fi

if ! echo "$output" | grep -q "duplicate_f47fea066e30c006.o"; then
  echo "error: missing expected object 2: $output" >&2
  exit 1
fi

if ! echo "$output" | grep -q "cc_lib_bd9e12793f4560a2.o"; then
  echo "error: missing expected object 3: $output" >&2
  exit 1
fi

if ! echo "$output" | grep -q "SYMDEF"; then
  echo "error: missing expected symdef: $output" >&2
  exit 1
fi
