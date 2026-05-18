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

"""Allowlist of targets that analyze Apple rules without active platform constraints."""

visibility("public")

ALLOWED_USERS_OF_MISSING_PLATFORM_FALLBACK = [
    # keep sorted
    "@build_bazel_rules_apple//apple:default_cc_toolchain_forwarder",
    "@build_bazel_rules_apple//apple/internal:environment_plist_ios",
    "@build_bazel_rules_apple//apple/internal:environment_plist_macos",
    "@build_bazel_rules_apple//apple/internal:environment_plist_tvos",
    "@build_bazel_rules_apple//apple/internal:environment_plist_visionos",
    "@build_bazel_rules_apple//apple/internal:environment_plist_watchos",
]
