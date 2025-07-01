# pylint: disable=g-bad-file-header
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
"""Configuring the C++ toolchain on macOS."""

load(
    "@bazel_tools//tools/cpp:lib_cc_configure.bzl",
    "escape_string",
)
load("@bazel_tools//tools/osx:xcode_configure.bzl", "run_xcode_locator")

def get_env_var(repository_ctx, name, default = None, enable_warning = True):
    """Find an environment variable in system path. Doesn't %-escape the value!

    Args:
      repository_ctx: The repository context.
      name: Name of the environment variable.
      default: Default value to be used when such environment variable is not present.
      enable_warning: Show warning if the variable is not present.
    Returns:
      value of the environment variable or default.
    """

    if name in repository_ctx.os.environ:
        return repository_ctx.os.environ[name]
    if default != None:
        if enable_warning:
            auto_configure_warning("'%s' environment variable is not set, using '%s' as default" % (name, default))
        return default
    auto_configure_fail("'%s' environment variable is not set" % name)
    return None

def auto_configure_fail(msg):
    """Output failure message when auto configuration fails."""
    red = "\033[0;31m"
    no_color = "\033[0m"
    fail("\n%sAuto-Configuration Error:%s %s\n" % (red, no_color, msg))

def auto_configure_warning(msg):
    """Output warning message during auto configuration."""
    yellow = "\033[1;33m"
    no_color = "\033[0m"

    # buildifier: disable=print
    print("\n%sAuto-Configuration Warning:%s %s\n" % (yellow, no_color, msg))

def split_escaped(string, delimiter):
    """Split string on the delimiter unless %-escaped.

    Examples:
      Basic usage:
        split_escaped("a:b:c", ":") -> [ "a", "b", "c" ]

      Delimiter that is not supposed to be splitten on has to be %-escaped:
        split_escaped("a%:b", ":") -> [ "a:b" ]

      Literal % can be represented by escaping it as %%:
        split_escaped("a%%b", ":") -> [ "a%b" ]

      Consecutive delimiters produce empty strings:
        split_escaped("a::b", ":") -> [ "a", "", "", "b" ]

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
    accumulator = []
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
    """Convert a list of string into a string that can be passed to a rule attribute."""
    if not values:
        return ""
    return "\"" + "\",\n    \"".join(values) + "\""

def _get_escaped_xcode_cxx_inc_directories(repository_ctx, xcode_toolchains):
    """Compute the list of default C++ include paths on Xcode-enabled darwin.

    Args:
      repository_ctx: The repository context.
      xcode_toolchains: A list containing the xcode toolchains available
    Returns:
      include_paths: A list of builtin include paths.
    """

    # Assume that everything is managed by Xcode / toolchain installations
    include_dirs = [
        "/Applications/",
        "/Library/",
    ]

    user = repository_ctx.os.environ.get("USER")
    if user:
        include_dirs.extend([
            "/Users/{}/Applications/".format(user),
            "/Users/{}/Library/".format(user),
        ])

    # Include extra Xcode paths in case they're installed on other volumes
    for toolchain in xcode_toolchains:
        include_dirs.append(escape_string(toolchain.developer_dir))

    return include_dirs

def _succeeds(repository_ctx, *args):
    env = repository_ctx.os.environ
    result = repository_ctx.execute([
        "env",
        "-i",
        "DEVELOPER_DIR={}".format(env.get("DEVELOPER_DIR", default = "")),
        "xcrun",
        "--sdk",
        "macosx",
    ] + list(args))

    return result.return_code == 0

def _copy_file(repository_ctx, src, dest):
    repository_ctx.file(dest, content = repository_ctx.read(src))

def configure_osx_toolchain(repository_ctx):
    """Configure C++ toolchain on macOS.

    Args:
      repository_ctx: The repository context.

    Returns:
      Whether or not configuration was successful
    """

    # All Label resolutions done at the top of the function to avoid issues
    # with starlark function restarts, see this:
    # https://github.com/bazelbuild/bazel/blob/ab71a1002c9c53a8061336e40f91204a2a32c38e/tools/cpp/lib_cc_configure.bzl#L17-L38
    # for more info
    xcode_locator = Label("@bazel_tools//tools/osx:xcode_locator.m")
    cc_toolchain_config = Label("@build_bazel_apple_support//crosstool:cc_toolchain_config.bzl")
    build_template = Label("@build_bazel_apple_support//crosstool:BUILD.tpl")

    xcode_toolchains = []
    xcodeloc_err = ""
    allow_non_applications_xcode = "BAZEL_ALLOW_NON_APPLICATIONS_XCODE" in repository_ctx.os.environ and repository_ctx.os.environ["BAZEL_ALLOW_NON_APPLICATIONS_XCODE"] == "1"
    if allow_non_applications_xcode:
        (xcode_toolchains, xcodeloc_err) = run_xcode_locator(repository_ctx, xcode_locator)
        if not xcode_toolchains:
            return False, xcodeloc_err

    _copy_file(repository_ctx, cc_toolchain_config, "cc_toolchain_config.bzl")

    enable_layering_check = repository_ctx.os.environ.get("APPLE_SUPPORT_LAYERING_CHECK_BETA") == "1"

    tool_paths = {}
    gcov_path = repository_ctx.os.environ.get("GCOV")
    if gcov_path != None:
        if not gcov_path.startswith("/"):
            gcov_path = repository_ctx.which(gcov_path)
        tool_paths["gcov"] = gcov_path

    features = []
    if _succeeds(repository_ctx, "ld", "-no_warn_duplicate_libraries", "-v"):
        features.append("no_warn_duplicate_libraries")

    escaped_include_paths = _get_escaped_xcode_cxx_inc_directories(repository_ctx, xcode_toolchains)
    escaped_cxx_include_directories = []
    for path in escaped_include_paths:
        escaped_cxx_include_directories.append(("            \"%s\"," % path))
    if xcodeloc_err:
        escaped_cxx_include_directories.append("            # Error: " + xcodeloc_err)

    conly_opts = split_escaped(get_env_var(
        repository_ctx,
        "BAZEL_CONLYOPTS",
        "",
        False,
    ), ":")
    c_opts = split_escaped(get_env_var(
        repository_ctx,
        "BAZEL_COPTS",
        "",
        False,
    ), ":")
    cxx_opts = split_escaped(get_env_var(
        repository_ctx,
        "BAZEL_CXXOPTS",
        "-std=c++17",
        False,
    ), ":")
    link_opts = split_escaped(get_env_var(
        repository_ctx,
        "BAZEL_LINKOPTS",
        "",
        False,
    ), ":")

    repository_ctx.template(
        "BUILD",
        build_template,
        {
            "%{c_flags}": get_starlark_list(c_opts),
            "%{conly_flags}": get_starlark_list(conly_opts),
            "%{cxx_builtin_include_directories}": "\n".join(escaped_cxx_include_directories),
            "%{cxx_flags}": get_starlark_list(cxx_opts),
            "%{features}": "\n".join(['"{}"'.format(x) for x in features]),
            "%{layering_check_modulemap}": "\"@build_bazel_apple_support//crosstool:generate_layering_check_modulemap\"," if enable_layering_check else "",
            "%{link_flags}": get_starlark_list(link_opts),
            "%{placeholder_modulemap}": "\"@build_bazel_apple_support//crosstool:module.modulemap\"" if enable_layering_check else "None",
            "%{tool_paths_overrides}": ",\n            ".join(
                ['"%s": "%s"' % (k, v) for k, v in tool_paths.items()],
            ),
        },
    )

    return True, ""
