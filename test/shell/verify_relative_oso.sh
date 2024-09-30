#!/bin/bash

set -euo pipefail

readonly binary="%{binary}s"

# [    51] 00001016 66 (N_OSO        ) 00     0001   0000000000000000 'bazel-out/darwin_arm64-dbg-macos-arm64-min13.0-applebin_macos-ST-659b080861c8/bin/test/test_data/libcc_main.a(main.o)'
output=$(dsymutil -s "$binary" | grep N_OSO)
echo "$output" | grep " 'bazel-out" \
  || (echo "has non-relative N_OSO entries: $output" >&2 && exit 1)
