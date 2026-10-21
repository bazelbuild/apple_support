# Copyright 2016 The Bazel Authors. All rights reserved.
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
"""Environment flag parsing shared by Apple toolchain repositories."""

visibility([
    "//crosstool",
    "//toolchain",
])

def get_copts_env_var(repository_ctx, name, default = ""):
    # type: (repository_ctx, str, str) -> list[str]
    """Get an environment variable and split it on ":" to be used as copts.

    Args:
      repository_ctx: The repository context.
      name: Name of the environment variable.
      default: Default value to be used when the environment variable is not present.
    Returns:
      Escaped value of the environment variable or default.
    """

    if name in repository_ctx.os.environ:
        return _split_escaped(repository_ctx.os.environ[name], ":")
    return _split_escaped(default, ":")

def _split_escaped(string, delimiter):
    # type: (str, str) -> list[str]
    """Split string on the delimiter unless %-escaped.

    Examples:
      Basic usage:
        split_escaped("a:b:c", ":") -> [ "a", "b", "c" ]

      Delimiter that is not supposed to be splitten on has to be %-escaped:
        split_escaped("a%:b", ":") -> [ "a:b" ]

      Literal % can be represented by escaping it as %%:
        split_escaped("a%%b", ":") -> [ "a%b" ]

      Consecutive delimiters produce empty strings:
        split_escaped("a::b", ":") -> [ "a", "", "b" ]

    Args:
      string: The string to be split.
      delimiter: Non-empty string not containing %-sign to be used as a
          delimiter.

    Returns:
      A list of substrings.
    """
    if delimiter == "":
        fail("Delimiter cannot be empty")
    if delimiter.find("%") != -1:
        fail("Delimiter cannot contain %-sign")

    i = 0
    result = []
    accumulator = []  # type: list[str]
    length = len(string)
    delimiter_length = len(delimiter)

    if not string:
        return []

    # Iterate over the length of string since Starlark doesn't have while loops
    for _ in range(length):
        if i >= length:
            break
        if i + 2 <= length and string[i:i + 2] == "%%":
            accumulator.append("%")
            i += 2
        elif (i + 1 + delimiter_length <= length and
              string[i:i + 1 + delimiter_length] == "%" + delimiter):
            accumulator.append(delimiter)
            i += 1 + delimiter_length
        elif i + delimiter_length <= length and string[i:i + delimiter_length] == delimiter:
            result.append("".join(accumulator))
            accumulator = []
            i += delimiter_length
        else:
            accumulator.append(string[i])
            i += 1

    # Append the last group still in accumulator
    result.append("".join(accumulator))
    return result

def get_starlark_list(values):
    # type: (list[str]) -> str
    """Convert a list of string into a string that can be passed to a rule attribute."""
    return ",\n    ".join([quote_starlark_string(value) for value in values])

def quote_starlark_string(value):
    # type: (str) -> str
    # Bazel's repr can emit \x escapes, which BUILD files do not accept.
    return '"%s"' % value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "\\r")
