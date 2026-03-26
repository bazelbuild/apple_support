#!/bin/bash

set -euo pipefail

readonly binary="%{binary}s"
output=$(ar t "$binary")

# NOTE: The first character of the transition hash is enough to verify they're unique
if ! echo "$output" | grep -q "duplicate_f.*.o"; then
  echo "error: missing expected object 1: $output" >&2
  exit 1
fi

if ! echo "$output" | grep -q "duplicate_3.*.o"; then
  echo "error: missing expected object 2: $output" >&2
  exit 1
fi

if ! echo "$output" | grep -q "cc_lib_c.*.o"; then
  echo "error: missing expected object 3: $output" >&2
  exit 1
fi

if ! echo "$output" | grep -q "SYMDEF"; then
  echo "error: missing expected symdef: $output" >&2
  exit 1
fi
