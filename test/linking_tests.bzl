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
    framework_flags = {
        "macos": ["-framework", "Foundation"],
        "ios": ["-framework", "Foundation", "-framework", "UIKit"],
    }

    for platform in ["macos", "ios"]:
        for apply_implicit_frameworks in [True, False]:
            framework_flags_case = framework_flags[platform] if apply_implicit_frameworks else []  # type: list[string]
            framework_flags_case_inverse = framework_flags[platform] if not apply_implicit_frameworks else []  # type: list[string

            apply_implicit_frameworks_name = "" if apply_implicit_frameworks else "_without_implicit_frameworks"
            case_name = "{}_{}{}".format(name, platform, apply_implicit_frameworks_name)
            target_under_test = "//test/test_data:{}{}_binary".format(platform, apply_implicit_frameworks_name)

            default_test(
                name = "{}_default_apple_link_test".format(case_name),
                tags = [name],
                expected_argv = [
                    "-Xlinker",
                    "-objc_abi_version",
                    "-Xlinker",
                    "2",
                    "-ObjC",
                ] + framework_flags_case,
                not_expected_argv = [
                    "-g",
                    "DSYM_HINT_LINKED_BINARY",
                    "-dead_strip",
                ] + framework_flags_case_inverse,
                mnemonic = "ObjcLink",
                target_under_test = target_under_test,
            )

            opt_test(
                name = "{}_opt_link_test".format(case_name),
                tags = [name],
                expected_argv = [
                    "-Xlinker",
                    "-objc_abi_version",
                    "-Xlinker",
                    "2",
                    "-ObjC",
                    "-dead_strip",
                ] + framework_flags_case,
                not_expected_argv = framework_flags_case_inverse,
                mnemonic = "ObjcLink",
                target_under_test = target_under_test,
            )

            dead_strip_requested_test(
                name = "{}_dead_strip_requested_test".format(case_name),
                tags = [name],
                expected_argv = [
                    "-Xlinker",
                    "-objc_abi_version",
                    "-Xlinker",
                    "2",
                    "-ObjC",
                    "-dead_strip",
                ] + framework_flags_case,
                not_expected_argv = framework_flags_case_inverse,
                mnemonic = "ObjcLink",
                target_under_test = target_under_test,
            )

            disable_objc_test(
                name = "{}_disable_objc_apple_link_test".format(case_name),
                tags = [name],
                expected_argv = [
                    "-Xlinker",
                    "-objc_abi_version",
                    "-Xlinker",
                    "2",
                ] + framework_flags_case,
                not_expected_argv = ["-ObjC"] + framework_flags_case_inverse,
                mnemonic = "ObjcLink",
                target_under_test = target_under_test,
            )

            dsym_test(
                name = "{}_generate_dsym_test".format(case_name),
                tags = [name],
                expected_argv = [
                    "-g",
                    "DSYM_HINT_LINKED_BINARY",
                ],
                mnemonic = "ObjcLink",
                target_under_test = target_under_test,
            )
