"""Tests for compilation behavior."""

load(
    "//test/rules:action_command_line_test.bzl",
    "make_action_command_line_test_rule",
)

default_test = make_action_command_line_test_rule()

opt_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:compilation_mode": "opt",
    },
)

disable_ns_block_assertions_feature_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:compilation_mode": "opt",
        "//command_line_option:features": [
            "-ns_block_assertions",
        ],
    },
)

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
            "-std=c++17 -std=c++20",
        ],
        not_expected_argv = [
            "-DNS_BLOCK_ASSERTIONS=1",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:cc_main",
    )

    opt_test(
        name = "{}_opt_link_test".format(name),
        tags = [name],
        expected_argv = [
            "-DNDEBUG",
            "-DNS_BLOCK_ASSERTIONS=1",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:cc_main",
    )

    disable_ns_block_assertions_feature_test(
        name = "{}_disable_ns_block_assertions_feature_test".format(name),
        tags = [name],
        expected_argv = [
            "-DNDEBUG",
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
