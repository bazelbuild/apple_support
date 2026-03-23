"""FIXME"""

def _get_copts_env_var(repository_ctx, name, default = ""):
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

def _get_starlark_list(values):
    """Convert a list of string into a string that can be passed to a rule attribute."""
    if not values:
        return ""
    return "\"" + "\",\n    \"".join(values) + "\""

def _toolchain_env_impl(repository_ctx):
    conly_opts = _get_copts_env_var(repository_ctx, "BAZEL_CONLYOPTS")
    c_opts = _get_copts_env_var(repository_ctx, "BAZEL_COPTS")
    cxx_opts = _get_copts_env_var(repository_ctx, "BAZEL_CXXOPTS", default = "-std=c++17")
    link_opts = _get_copts_env_var(repository_ctx, "BAZEL_LINKOPTS")

    repository_ctx.file(
        "BUILD.bazel",
        """\
load("@rules_cc//cc/toolchains:feature.bzl", "cc_feature")
load("@rules_cc//cc/toolchains:args.bzl", "cc_args")

package(default_visibility = ["@build_bazel_apple_support//:__subpackages__"])

cc_feature(
    name = "copts_from_env",
    feature_name = "__copts_from_env",
    args = [
        ":copts",
        ":conlyopts",
        ":cxxopts",
    ],
)

cc_args(
    name = "copts",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [{c_opts}],
)

cc_args(
    name = "conlyopts",
    actions = ["@rules_cc//cc/toolchains/actions:c_compile"],
    args = [{conly_opts}],
)

cc_args(
    name = "cxxopts",
    actions = [
        # TODO: Should more actions be here?
        "@rules_cc//cc/toolchains/actions:cpp_compile",
        "@rules_cc//cc/toolchains/actions:cpp_header_parsing",
        "@rules_cc//cc/toolchains/actions:cpp_module_compile",
        "@rules_cc//cc/toolchains/actions:linkstamp_compile",
    ],
    args = [{cxx_opts}],
)

cc_feature(
    name = "linkopts_from_env",
    feature_name = "__linkopts_from_env",
    args = [
        ":linkopts",
    ],
)

cc_args(
    name = "linkopts",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [{link_opts}],
)
""".format(
            c_opts = _get_starlark_list(c_opts),
            conly_opts = _get_starlark_list(conly_opts),
            cxx_opts = _get_starlark_list(cxx_opts),
            link_opts = _get_starlark_list(link_opts),
        ),
    )

toolchain_env = repository_rule(
    environ = [
        "BAZEL_COPTS",
        "BAZEL_CONLYOPTS",
        "BAZEL_CXXOPTS",
        "BAZEL_LINKOPTS",
    ],
    implementation = _toolchain_env_impl,
)
