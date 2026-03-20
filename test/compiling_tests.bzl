"""Tests for compilation behavior."""

load(
    "//test/rules:action_command_line_test.bzl",
    "make_action_command_line_test_rule",
)

default_test = make_action_command_line_test_rule()

copt_order_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:compilation_mode": "opt",
        "//command_line_option:copt": ["-DFROM_COPTS_FLAG=1"],
        "//command_line_option:cxxopt": ["-DFROM_CXX_FLAG=1"],
        "//command_line_option:objccopt": ["-DFROM_OBJCCOPTS_FLAG=1"],
        "//command_line_option:process_headers_in_dependencies": "true",
    },
)

opt_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:compilation_mode": "opt",
    },
)

ios_simulator_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:platforms": "@@//platforms:ios_sim_arm64",  # buildifier: disable=canonical-repository
    },
)

ios_device_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:platforms": "@@//platforms:ios_arm64",  # buildifier: disable=canonical-repository
    },
)

fastbuild_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:compilation_mode": "fastbuild",
    },
)

dbg_test = make_action_command_line_test_rule(
    config_settings = {
        "//command_line_option:compilation_mode": "dbg",
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
            "-DCOPTS_ENV=1",
            "-std=c++17 -DCXXOPTS_ENV=1 -std=c++20",
        ],
        not_expected_argv = [
            "-DCONLY_ENV=1",
            "-DNS_BLOCK_ASSERTIONS=1",
            "-fexceptions",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:cc_main",
    )

    default_test(
        name = "{}_default_c_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-fdebug-prefix-map=__BAZEL_EXECUTION_ROOT__=.",
            "-DCOPTS_ENV=1",
            "-DCONLY_ENV=1",
            "-std=c99",
        ],
        not_expected_argv = [
            "-std=c++17",
            "-DCXXOPTS_ENV=1",
            "-DNS_BLOCK_ASSERTIONS=1",
            "-fexceptions",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:c_main",
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

    default_test(
        name = "{}_objc_pch_test".format(name),
        tags = [name],
        expected_argv = [
            "-include",
            "test/test_data/pch.pch",
        ],
        mnemonic = "ObjcCompile",
        target_under_test = "//test/test_data:objc_pch_lib",
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

    ios_simulator_test(
        name = "{}_ios_simulator_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-DOS_IOS",
            "-fno-autolink",
            "-fexceptions",
            "-fasm-blocks",
            "-fobjc-abi-version=2",
            "-fobjc-legacy-dispatch",
            "-DFROM_BUILD_COPTS=1",
        ],
        not_expected_argv = [
            "-DOS_MACOSX",
        ],
        mnemonic = "ObjcCompile",
        target_under_test = "//test/test_data:objc_lib",
    )

    ios_device_test(
        name = "{}_ios_device_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-DOS_IOS",
            "-fno-autolink",
        ],
        not_expected_argv = [
            "-DOS_MACOSX",
            "-fexceptions",
            "-fasm-blocks",
            "-fobjc-abi-version=2",
            "-fobjc-legacy-dispatch",
        ],
        mnemonic = "ObjcCompile",
        target_under_test = "//test/test_data:objc_lib",
    )

    default_test(
        name = "{}_macos_objc_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-DOS_MACOSX",
            "-fno-autolink",
        ],
        not_expected_argv = [
            "-DOS_IOS",
            "-fexceptions",
            "-fasm-blocks",
            "-fobjc-abi-version=2",
            "-fobjc-legacy-dispatch",
        ],
        mnemonic = "ObjcCompile",
        target_under_test = "//test/test_data:objc_lib",
    )

    default_test(
        name = "{}_framework_include_paths_test".format(name),
        tags = [name],
        expected_argv = ["-Ftest/test_data/frameworks"],
        mnemonic = "ObjcCompile",
        target_under_test = "//test/test_data:objc_framework_includes_lib",
    )

    default_test(
        name = "{}_objc_no_arc_test".format(name),
        tags = [name],
        expected_argv = ["-fno-objc-arc"],
        mnemonic = "ObjcCompile",
        target_under_test = "//test/test_data:objc_no_arc_lib",
    )

    copt_order_test(
        name = "{}_objc_copt_order_test".format(name),
        tags = [name],
        expected_argv = [
            "-D_FORTIFY_SOURCE=1",
            "-fstack-protector",
            "-O2",  # From --compilation_mode=opt
            "-Werror=incompatible-sysroot",  # default warning flags
            "-DFROM_BUILD_DEFINES=1",  # TODO: This should probably be below --copts
            "-DOS_MACOSX",
            "-fno-autolink",
            "-isysroot",
            "__BAZEL_XCODE_SDKROOT__",
            "-fobjc-arc",
            "-DCOPTS_ENV=1",
            "-DFROM_COPTS_FLAG=1",
            "-DFROM_OBJCCOPTS_FLAG=1",
            "-DFROM_BUILD_COPTS=1",
            "-D__DATE__=\"redacted\"",
        ],
        not_expected_argv = [
            "-DCONLY_ENV=1",
            "-DCXXOPTS_ENV=1",
        ],
        mnemonic = "ObjcCompile",
        target_under_test = "//test/test_data:objc_lib",
    )

    copt_order_test(
        name = "{}_objcpp_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-stdlib=libc++",  # Objc++ specific opts
            "-std=gnu++17",  # Objc++ specific opts
            "-D_FORTIFY_SOURCE=1",
            "-fstack-protector",
            "-O2",  # From --compilation_mode=opt
            "-Werror=incompatible-sysroot",  # default warning flags
            "-DFROM_BUILD_DEFINES=1",  # TODO: This should probably be below --copts
            "-DOS_MACOSX",
            "-fno-autolink",
            "-isysroot",
            "__BAZEL_XCODE_SDKROOT__",
            "-fobjc-arc",
            # "-DCXXOPTS_ENV=1", # TODO: Should this affect objcpp compiles?
            "-DFROM_COPTS_FLAG=1",
            # "-DFROM_CXX_FLAG=1", # TODO: broken on bazel 7.x
            "-DFROM_OBJCCOPTS_FLAG=1",
            "-DFROM_BUILD_COPTS=1",
            "-D__DATE__=\"redacted\"",
        ],
        not_expected_argv = [
            "-DCONLY_ENV=1",
        ],
        mnemonic = "ObjcCompile",
        target_under_test = "//test/test_data:objcpp_lib",
    )

    copt_order_test(
        name = "{}_cc_copt_order_test".format(name),
        tags = [name],
        expected_argv = [
            "-O2",  # From --compilation_mode=opt
            "-DFROM_BUILD_DEFINES=1",  # TODO: This should probably be below --copts
            "-isysroot",
            "__BAZEL_XCODE_SDKROOT__",
            "-DFROM_COPTS_FLAG=1",
            "-DFROM_BUILD_COPTS=1",
            "-D__DATE__=\"redacted\"",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:cc_lib",
    )

    copt_order_test(
        name = "{}_header_parsing_copt_order_test".format(name),
        tags = [name],
        expected_argv = [
            "-xc++-header",
            "-fsyntax-only",
            "-O2",  # From --compilation_mode=opt
            "-isysroot",
            "__BAZEL_XCODE_SDKROOT__",
            "-DFROM_COPTS_FLAG=1",
            "-D__DATE__=\"redacted\"",
            "-c",
            "test/header_parsing/valid_header.h",
            "-o",
            "$(BIN_DIR)/test/header_parsing/_objs/valid_header/valid_header.h.processed",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/header_parsing:valid_header",
    )

    default_test(
        name = "{}_dependency_file_test".format(name),
        tags = [name],
        expected_argv = [
            "-MD",
            "-MF",
            "cc_lib.d",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:cc_lib",
    )

    default_test(
        name = "{}_compiler_input_output_flags_test".format(name),
        tags = [name],
        expected_argv = [
            "-c",
            "test/test_data/cc_lib.cc",
            "-o",
            "cc_lib.o",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:cc_lib",
    )

    fastbuild_test(
        name = "{}_fastbuild_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-D_FORTIFY_SOURCE=1",
            "-fstack-protector",
            "-O0",
            "-DDEBUG",
        ],
        not_expected_argv = [
            "-DNDEBUG",
            "-g",
            "-g0",
            "-O2",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:cc_main",
    )

    dbg_test(
        name = "{}_dbg_compile_test".format(name),
        tags = [name],
        expected_argv = [
            "-D_FORTIFY_SOURCE=1",
            "-fstack-protector",
            "-g",
        ],
        not_expected_argv = [
            "-DDEBUG",
            "-DNDEBUG",
            "-g0",
            "-O0",
            "-O2",
        ],
        mnemonic = "CppCompile",
        target_under_test = "//test/test_data:cc_main",
    )

    native.test_suite(
        name = name,
        tags = [name],
    )
