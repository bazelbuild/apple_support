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

# LINT.IfChange
set -eu

# SYNOPSIS
#   Rewrites any Bazel placeholder strings in the given argument string,
#   echoing the result.
#
# USAGE
#   rewrite_argument <argument>
function rewrite_argument {
  ARG="$1"
  ARG="${ARG//__BAZEL_XCODE_DEVELOPER_DIR__/$DEVELOPER_DIR}"
  ARG="${ARG//__BAZEL_XCODE_SDKROOT__/$SDKROOT}"
  echo "$ARG"
}

TOOLNAME="$1"
shift

ARGS=()

for ARG in "$@" ; do
  ARGS+=("$(rewrite_argument "$ARG")")
done

exec "$TOOLNAME" "${ARGS[@]}"
# LINT.ThenChange(apple_support.bzl:xcode_processor_args)
