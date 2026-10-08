#!/bin/bash

# Copyright 2019 The Bazel Authors. All rights reserved.
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

set -eu

# Integration test for apple_genrule.

# The first line records the action's execution OS; the remaining lines contain
# its environment. Xcode environment variables should only be added on macOS.

INPUT_FILE="$1"

for variable in DEVELOPER_DIR SDKROOT; do
  if [[ "$(head -n 1 "$INPUT_FILE")" == Darwin ]]; then
    if ! grep -q "^${variable}=" "$INPUT_FILE"; then
      echo "FAILURE: $variable not found on macOS."
      exit 1
    fi
  elif grep -q "^${variable}=" "$INPUT_FILE"; then
    echo "FAILURE: $variable found on a non-macOS execution platform."
    exit 1
  fi
done
