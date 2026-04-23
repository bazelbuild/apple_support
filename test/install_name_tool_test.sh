#!/bin/bash

# Copyright 2026 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

binary="$1"

fail() {
  echo "FAILURE: $1" >&2
  exit 1
}

otool_output=$(otool -l "$binary")

# Verify install name was changed
if ! echo "$otool_output" | grep -q "CUSTOM_INSTALL_NAME"; then
  fail "install name 'CUSTOM_INSTALL_NAME' not found in binary"
fi

# Verify rpath was added
if ! echo "$otool_output" | grep -q "CUSTOM_RPATH"; then
  fail "rpath 'CUSTOM_RPATH' not found in binary"
fi

echo "PASS"
