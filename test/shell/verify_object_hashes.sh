#!/bin/bash

set -euo pipefail

readonly binary="%{binary}s"
output=$(ar t "$binary")

# The hash includes the full object path, including Bazel's configuration hash.
# Ignore its value, but require distinct hashes for the two duplicate.cc sources.
duplicate_object_names=$(echo "$output" | grep -E '^duplicate_[[:xdigit:]]{16}\.o$' | sort -u || true)
if [[ $(echo "$duplicate_object_names" | grep -c . || true) -ne 2 ]]; then
  echo "error: expected two distinct hashed duplicate objects: $output" >&2
  exit 1
fi

if [[ $(echo "$output" | grep -Ec '^cc_lib_[[:xdigit:]]{16}\.o$' || true) -ne 1 ]]; then
  echo "error: expected one hashed cc_lib object: $output" >&2
  exit 1
fi

if [[ $(echo "$output" | grep -c '\.o$' || true) -ne 3 ]]; then
  echo "error: expected exactly three archive objects: $output" >&2
  exit 1
fi

if ! echo "$output" | grep -q "SYMDEF"; then
  echo "error: missing expected symdef: $output" >&2
  exit 1
fi
