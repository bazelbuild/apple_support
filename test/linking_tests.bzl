"""Tests for linking behavior."""

load(
    "//test/rules:action_command_line_test.bzl",
    "make_action_command_line_test_rule",
)

default_test = make_action_command_line_test_rule()

disable_strip_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:strip": "never",
    },
)

strip_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:strip": "always",
    },
)

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

pic_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:force_pic": "true",
    },
)

no_pic_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:force_pic": "false",
    },
)

stripopt_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:stripopt": ["-passed_arg"],
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
            "LINKED_BINARY",
            "-ObjC",
            "-framework",
            "Foundation",
        ],
        not_expected_argv = [
            "-g",
            "DSYM_HINT_DSYM_PATH",
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
            "LINKED_BINARY",
            "-ObjC",
            "-framework",
            "Foundation",
            "-framework",
            "UIKit",
        ],
        not_expected_argv = [
            "-g",
            "DSYM_HINT_DSYM_PATH",
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

    default_test(
        name = "{}_objc_link_sdk_frameworks_test".format(name),
        tags = [name],
        expected_argv = [
            "-framework",
            "CalendarStore",
            "-weak_framework",
            "Accounts",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:macos_binary_with_sdk_frameworks",
    )

    dsym_test(
        name = "{}_generate_dsym_test".format(name),
        tags = [name],
        expected_argv = [
            "-g",
            "DSYM_HINT_DSYM_PATH",
            "LINKED_BINARY",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:macos_binary",
    )

    dsym_test(
        name = "{}_generate_cpp_dsym_test".format(name),
        tags = [name],
        expected_argv = [
            "DSYM_HINT_DSYM_PATH",
            "LINKED_BINARY",
        ],
        mnemonic = "CppLink",
        target_under_test = "//test/test_data:cc_test_binary",
    )

    strip_test(
        name = "{}_strip_objc_test".format(name),
        tags = [name],
        expected_argv = [
            "STRIP_DEBUG_SYMBOLS",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:macos_binary",
    )

    strip_test(
        name = "{}_strip_cc_test".format(name),
        tags = [name],
        expected_argv = [
            "STRIP_DEBUG_SYMBOLS",
        ],
        mnemonic = "CppLink",
        target_under_test = "//test/test_data:cc_test_binary",
    )

    strip_test(
        name = "{}_strip_shared_library_test".format(name),
        tags = [name],
        expected_argv = [
            "STRIP_DEBUG_SYMBOLS",
        ],
        mnemonic = "CppLink",
        target_under_test = "//test:loadable_library_so",
    )

    disable_strip_test(
        name = "{}_disable_strip_objc_test".format(name),
        tags = [name],
        not_expected_argv = [
            "STRIP_DEBUG_SYMBOLS",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:macos_binary",
    )

    default_test(
        name = "{}_cc_shared_library_rpath_test".format(name),
        tags = [name],
        expected_argv = [
            "-Xlinker",
            "-rpath",
            "-Xlinker",
        ],
        mnemonic = "CppLink",
        target_under_test = "//test:nested_library_so",
    )

    default_test(
        name = "{}_cc_binary_rpath_test".format(name),
        tags = [name],
        expected_argv = [
            "-Xlinker",
            "-rpath",
            "-Xlinker",
        ],
        mnemonic = "CppLink",
        target_under_test = "//test:loadable_library_test",
    )

    pic_test(
        name = "{}_pic_test".format(name),
        tags = [name],
        expected_argv = ["-Wl,-pie"],
        mnemonic = "CppLink",
        target_under_test = "//test/test_data:cc_test_binary",
    )

    no_pic_test(
        name = "{}_no_pic_test".format(name),
        tags = [name],
        mnemonic = "CppLink",
        not_expected_argv = ["-Wl,-pie"],
        target_under_test = "//test/test_data:cc_test_binary",
    )

    stripopt_test(
        name = "{}_builtin_strip_test".format(name),
        tags = [name],
        expected_argv = [
            "-S",
            "-o",
            "$(BIN_DIR)/test/test_data/cc_test_binary.stripped",
            "-passed_arg",
            "$(BIN_DIR)/test/test_data/cc_test_binary",
        ],
        mnemonic = "CcStrip",
        target_under_test = "//test/test_data:cc_test_binary",
    )
