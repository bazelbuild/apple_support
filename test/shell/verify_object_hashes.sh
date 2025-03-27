#!/bin/bash

set -euo pipefail

readonly binary="%{binary}s"
output=$(ar t "$binary")

if ! echo "$output" | grep -q "duplicate_a53dcba6a34993a1e83502dddc687f78.o"; then
  echo "error: missing expected object 1: $output" >&2
  exit 1
fi

if ! echo "$output" | grep -q "duplicate_a4944a8448ca496d69aa3c2b860bef74.o"; then
  echo "error: missing expected object 2: $output" >&2
  exit 1
fi

if ! echo "$output" | grep -q "cc_lib_ba2b8ebd486dc5bfc4cbfacde5538c29.o"; then
  echo "error: missing expected object 3: $output" >&2
  exit 1
fi

if ! echo "$output" | grep -q "SYMDEF"; then
  echo "error: missing expected symdef: $output" >&2
  exit 1
fi
