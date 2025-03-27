#!/bin/bash

set -euo pipefail

readonly binary="%{binary}s"
output=$(ar t "$binary")

if ! echo "$output" | grep -q "duplicate_a53dcba6a34993a1e83502dddc687f78.o"; then
  echo "error: missing expected object 1" >&2
  exit 1
fi

if ! echo "$output" | grep -q "duplicate_a4944a8448ca496d69aa3c2b860bef74.o"; then
  echo "error: missing expected object 2" >&2
  exit 1
fi

if ! echo "$output" | grep -q "SYMDEF"; then
  echo "error: missing expected symdef" >&2
  exit 1
fi
