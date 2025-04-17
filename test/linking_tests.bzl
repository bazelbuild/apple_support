"""Tests for linking behavior."""

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

dead_strip_requested_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:compilation_mode": "fastbuild",
        "//command_line_option:features": [
            "dead_strip",
        ],
    },
)

disable_objc_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:features": [
            "-objc_link_flag",
        ],
    },
)

disable_implicit_frameworks_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:features": [
            "-apply_implicit_frameworks",
        ],
    },
)

dsym_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:apple_generate_dsym": True,
    },
)

def linking_test_suite(name):
    """Tests for linking behavior.

    Args:
        name: The name to be included in test names and tags.
    """
    default_test(
        name = "{}_default_apple_macos_link_test".format(name),
        tags = [name],
        expected_argv = [
            "-Xlinker",
            "-objc_abi_version",
            "-Xlinker",
            "2",
            "-ObjC",
            "-framework",
            "Foundation",
        ],
        not_expected_argv = [
            "-g",
            "DSYM_HINT_LINKED_BINARY",
            "-dead_strip",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:macos_binary",
    )
    default_test(
        name = "{}_default_apple_ios_link_test".format(name),
        tags = [name],
        expected_argv = [
            "-Xlinker",
            "-objc_abi_version",
            "-Xlinker",
            "2",
            "-ObjC",
            "-framework",
            "Foundation",
            "-framework",
            "UIKit",
        ],
        not_expected_argv = [
            "-g",
            "DSYM_HINT_LINKED_BINARY",
            "-dead_strip",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:ios_binary",
    )

    opt_test(
        name = "{}_opt_link_test".format(name),
        tags = [name],
        expected_argv = [
            "-Xlinker",
            "-objc_abi_version",
            "-Xlinker",
            "2",
            "-ObjC",
            "-dead_strip",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:macos_binary",
    )

    dead_strip_requested_test(
        name = "{}_dead_strip_requested_test".format(name),
        tags = [name],
        expected_argv = [
            "-Xlinker",
            "-objc_abi_version",
            "-Xlinker",
            "2",
            "-ObjC",
            "-dead_strip",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:macos_binary",
    )

    disable_objc_test(
        name = "{}_disable_objc_apple_link_test".format(name),
        tags = [name],
        expected_argv = [
            "-Xlinker",
            "-objc_abi_version",
            "-Xlinker",
            "2",
            "-framework",
            "Foundation",
        ],
        not_expected_argv = ["-ObjC"],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:macos_binary",
    )

    disable_implicit_frameworks_test(
        name = "{}_disable_implicit_frameworks_apple_macos_link_test".format(name),
        tags = [name],
        expected_argv = [
            "-Xlinker",
            "-objc_abi_version",
            "-Xlinker",
            "2",
            "-ObjC",
        ],
        not_expected_argv = [
            "-framework",
            "Foundation",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:macos_binary",
    )

    disable_implicit_frameworks_test(
        name = "{}_disable_implicit_frameworks_apple_ios_link_test".format(name),
        tags = [name],
        expected_argv = [
            "-Xlinker",
            "-objc_abi_version",
            "-Xlinker",
            "2",
            "-ObjC",
        ],
        not_expected_argv = [
            "-framework",
            "Foundation",
            "-framework",
            "UIKit",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:ios_binary",
    )

    dsym_test(
        name = "{}_generate_dsym_test".format(name),
        tags = [name],
        expected_argv = [
            "-g",
            "DSYM_HINT_LINKED_BINARY",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:macos_binary",
    )

    dsym_test(
        name = "{}_generate_cpp_dsym_test".format(name),
        tags = [name],
        expected_argv = [
            "DSYM_HINT_LINKED_BINARY",
            "DSYM_HINT_DSYM_PATH",
        ],
        mnemonic = "CppLink",
        target_under_test = "//test/test_data:cc_test_binary",
    )
