"""Tests for compilation behavior."""

load(
    "//test/rules:action_command_line_test.bzl",
    "make_action_command_line_test_rule",
)

default_test = make_action_command_line_test_rule()

def compiling_test_suite(name):
    """Tests for compilation behavior.

    Args:
        name: The name to be included in test names and tags.
    """
    default_test(
        name = "{}_default_apple_macos_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-fdebug-prefix-map=__BAZEL_EXECUTION_ROOT__=.",
        ],
        not_expected_argv = [
            "-DNS_BLOCK_ASSERTIONS=1",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:cc_main",
    )

    native.test_suite(
        name = name,
        tags = [name],
    )
