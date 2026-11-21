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

"""Format Apple toolchain flags and paths for generated BUILD files."""

visibility([
    "//crosstool",
    "//toolchain",
])

def get_starlark_list(values):
    # type: (list[str]) -> str
    """Formats string literals for a generated list attribute."""
    return ",\n    ".join([quote_starlark_string(value) for value in values])

def quote_starlark_string(value):
    # type: (str) -> str
    """Returns a string literal that a BUILD file can read."""

    # Bazel's repr can emit \x escapes, which BUILD files do not accept.
    return '"%s"' % value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "\\r")
