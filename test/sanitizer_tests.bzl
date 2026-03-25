"""Tests for sanitizer behavior."""

load(
    "//test/rules:action_command_line_test.bzl",
    "make_action_command_line_test_rule",
)

default_test = make_action_command_line_test_rule()

asan_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:features": ["asan"],
    },
)

tsan_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:features": ["tsan"],
    },
)

ubsan_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:features": ["ubsan"],
    },
)

def sanitizer_test_suite(name):
    """Tests for sanitizer behavior.

    Args:
        name: The name to be included in test names and tags.
    """

    default_test(
        name = "{}_default_no_sanitizer_test".format(name),
        tags = [name],
        expected_argv = [
            "-D_FORTIFY_SOURCE=1",
        ],
        not_expected_argv = [
            "-fsanitize=address",
            "-fsanitize=thread",
            "-fsanitize=undefined",
            "-gline-tables-only",
            "-fno-sanitize-recover=all",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:cc_main",
    )

    asan_test(
        name = "{}_asan_cc_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-fsanitize=address",
            "-gline-tables-only",
            "-fno-omit-frame-pointer",
            "-fno-sanitize-recover=all",
        ],
        not_expected_argv = [
            "-D_FORTIFY_SOURCE=1",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:cc_main",
    )

    asan_test(
        name = "{}_asan_objc_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-fsanitize=address",
            "-gline-tables-only",
            "-fno-omit-frame-pointer",
            "-fno-sanitize-recover=all",
        ],
        not_expected_argv = [
            "-D_FORTIFY_SOURCE=1",
        ],
        mnemonic = "ObjcCompile",
        target_under_test = "//test/test_data:objc_lib",
    )

    asan_test(
        name = "{}_asan_link_test".format(name),
        tags = [name],
        expected_argv = [
            "-fsanitize=address",
        ],
        mnemonic = "CppLink",
        target_under_test = "//test/test_data:cc_test_binary",
    )

    asan_test(
        name = "{}_asan_objc_link_test".format(name),
        tags = [name],
        expected_argv = [
            "-fsanitize=address",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:macos_binary",
    )

    tsan_test(
        name = "{}_tsan_cc_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-D_FORTIFY_SOURCE=1",
            "-fsanitize=thread",
            "-gline-tables-only",
            "-fno-omit-frame-pointer",
            "-fno-sanitize-recover=all",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:cc_main",
    )

    tsan_test(
        name = "{}_tsan_objc_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-D_FORTIFY_SOURCE=1",
            "-fsanitize=thread",
            "-gline-tables-only",
            "-fno-omit-frame-pointer",
            "-fno-sanitize-recover=all",
        ],
        mnemonic = "ObjcCompile",
        target_under_test = "//test/test_data:objc_lib",
    )

    tsan_test(
        name = "{}_tsan_link_test".format(name),
        tags = [name],
        expected_argv = [
            "-fsanitize=thread",
        ],
        mnemonic = "CppLink",
        target_under_test = "//test/test_data:cc_test_binary",
    )

    tsan_test(
        name = "{}_tsan_objc_link_test".format(name),
        tags = [name],
        expected_argv = [
            "-fsanitize=thread",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:macos_binary",
    )

    ubsan_test(
        name = "{}_ubsan_cc_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-D_FORTIFY_SOURCE=1",
            "-fsanitize=undefined",
            "-gline-tables-only",
            "-fno-omit-frame-pointer",
            "-fno-sanitize-recover=all",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:cc_main",
    )

    ubsan_test(
        name = "{}_ubsan_objc_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-D_FORTIFY_SOURCE=1",
            "-fsanitize=undefined",
            "-gline-tables-only",
            "-fno-omit-frame-pointer",
            "-fno-sanitize-recover=all",
        ],
        mnemonic = "ObjcCompile",
        target_under_test = "//test/test_data:objc_lib",
    )

    ubsan_test(
        name = "{}_ubsan_link_test".format(name),
        tags = [name],
        expected_argv = [
            "-fsanitize=undefined",
        ],
        mnemonic = "CppLink",
        target_under_test = "//test/test_data:cc_test_binary",
    )

    ubsan_test(
        name = "{}_ubsan_objc_link_test".format(name),
        tags = [name],
        expected_argv = [
            "-fsanitize=undefined",
        ],
        mnemonic = "ObjcLink",
        target_under_test = "//test/test_data:macos_binary",
    )

    native.test_suite(
        name = name,
        tags = [name],
    )
