# Copyright 2018 The Bazel Authors. All rights reserved.
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
"""Xcode path placeholders shared by Apple support and toolchains."""

visibility([
    "//lib",
    "//toolchain",
])

XCODE_PATH_PLACEHOLDER = "__BAZEL_XCODE_DEVELOPER_DIR__"

def platform_frameworks_path(platform_name):
    # type: (str) -> str
    """Returns the platform frameworks path anchored to the Xcode placeholder."""
    return "{xcode_path}/Platforms/{platform_name}.platform/Developer/Library/Frameworks".format(
        platform_name = platform_name,
        xcode_path = XCODE_PATH_PLACEHOLDER,
    )
