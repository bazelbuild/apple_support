#!/bin/bash

set -euo pipefail

readonly binary="%{binary}s"
output=$(ar t "$binary")

if ! echo "$output" | grep -q "duplicate_2d70f4b848bc9998.o"; then
  echo "error: missing expected object 1: $output" >&2
  exit 1
fi

if ! echo "$output" | grep -q "duplicate_1f8897ef5ed261d1.o"; then
  echo "error: missing expected object 2: $output" >&2
  exit 1
fi

if ! echo "$output" | grep -q "cc_lib_d94568e0aa8550aa.o"; then
  echo "error: missing expected object 3: $output" >&2
  exit 1
fi

if ! echo "$output" | grep -q "SYMDEF"; then
  echo "error: missing expected symdef: $output" >&2
  exit 1
fi
