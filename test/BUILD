load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_cc//cc:cc_shared_library.bzl", "cc_shared_library")
load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library", "cc_test", "objc_library")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
load("//rules:apple_genrule.bzl", "apple_genrule")
load("//rules/install_name_tool:install_name_tool.bzl", "install_name_tool")
load(":apple_support_test.bzl", "apple_support_test")
load(":available_xcodes_test.bzl", "available_xcodes_test")
load(":binary_tests.bzl", "binary_test_suite")
load(":cc_toolchain_forwarder.bzl", "cc_toolchain_forwarder")
load(":compiling_tests.bzl", "compiling_test_suite")
load(":linking_tests.bzl", "linking_test_suite")
load(":sanitizer_tests.bzl", "sanitizer_test_suite")
load(":starlark_apple_binary.bzl", "starlark_apple_binary")
load(":universal_binary_test.bzl", "universal_binary_test")
load(":xcode_config_test.bzl", "xcode_config_test")
load(":xcode_support_test.bzl", "xcode_support_test")
load(":xcode_version_test.bzl", "xcode_version_test")

licenses(["notice"])

# Custom rules that test rule-context APIs. Check their implementations for more details.
apple_support_test(name = "apple_support_test")

available_xcodes_test(name = "available_xcodes_test")

binary_test_suite(name = "binary")

compiling_test_suite(name = "compiling")

linking_test_suite(name = "linking")

sanitizer_test_suite(name = "sanitizer")

xcode_config_test(name = "xcode_config_test")

xcode_support_test(name = "xcode_support_test")

xcode_version_test(name = "xcode_version_test")

# Test to ensure the environment variable contract of apple_genrule.
sh_test(
    name = "apple_genrule_test",
    size = "small",
    srcs = ["apple_genrule_test.sh"],
    args = ["$(location simple_genrule.txt)"],
    data = ["simple_genrule.txt"],
)

build_test(
    name = "touched_test",
    targets = [":touched"],
)

apple_genrule(
    name = "simple_genrule",
    outs = ["simple_genrule.txt"],
    cmd = "printenv | grep \"^\\(DEVELOPER_DIR\\|SDKROOT\\)\" > $(@)",
)

apple_genrule(
    name = "touched",
    outs = ["genrule_touched.txt"],
    cmd = "touch $(OUTS)",
)

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    deps = [
        "//lib:apple_support",
        "//lib:xcode_support",
        "//xcode:available_xcodes",
        "//xcode:xcode_config",
        "//xcode:xcode_version",
        "@bazel_skylib//lib:unittest",
    ],
)

universal_binary_test(
    name = "universal_binary_test_x86_64",
    binary_contains_symbols = [
        "__Z19function_for_x86_64v",
        "__Z19function_for_arch64v",
    ],
    cpu = "darwin_x86_64",
    target_under_test = "//test/test_data:multi_arch_cc_binary",
)

universal_binary_test(
    name = "universal_binary_test_arm64",
    binary_contains_symbols = [
        "__Z19function_for_x86_64v",
        "__Z19function_for_arch64v",
    ],
    cpu = "darwin_arm64",
    target_under_test = "//test/test_data:multi_arch_cc_binary",
)

install_name_tool(
    name = "patched_dylib",
    testonly = True,
    src = "//test/test_data:test_dylib",
    add_rpath = ["CUSTOM_RPATH"],
    install_name = "CUSTOM_INSTALL_NAME",
)

sh_test(
    name = "install_name_tool_test",
    size = "small",
    srcs = ["install_name_tool_test.sh"],
    args = ["$(location :patched_dylib)"],
    data = [":patched_dylib"],
)

install_name_tool(
    name = "patched_dylib_changed_rpath",
    testonly = True,
    src = ":patched_dylib",
    change_rpath = {"CUSTOM_RPATH": "CUSTOM_CHANGED_RPATH"},
)

sh_test(
    name = "install_name_tool_rpath_test",
    size = "small",
    srcs = ["install_name_tool_rpath_test.sh"],
    args = ["$(location :patched_dylib_changed_rpath)"],
    data = [":patched_dylib_changed_rpath"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = True,
    srcs = glob(["**"]),
    visibility = ["//test/shell:__pkg__"],
)

cc_binary(
    name = "main_c",
    srcs = ["main.c"],
)

cc_binary(
    name = "main_cpp",
    srcs = ["main.cc"],
)

objc_library(
    name = "main_objc",
    srcs = ["main.m"],
)

starlark_apple_binary(
    name = "main_apple",
    minimum_os_version = "13.0",
    platform_type = "macos",
    deps = ["main_objc"],
)

cc_library(
    name = "underlying_lib",
    hdrs = ["underlying_lib.h"],
    tags = ["manual"],
)

objc_library(
    name = "objc_lib",
    srcs = ["objc_lib.m"],
    hdrs = ["objc_lib.h"],
    tags = ["manual"],
    deps = [":underlying_lib"],
    alwayslink = True,
)

cc_test(
    name = "cc_test_with_objc_deps",
    srcs = ["cc_test_with_objc_deps.cc"],
    deps = [":objc_lib"],
)

cc_toolchain_forwarder(
    name = "default_cc_toolchain_forwarder",
    visibility = [":__subpackages__"],
)

cc_library(
    name = "linkstamp_lib",
    hdrs = ["linkstamp.h"],
    linkstamp = "linkstamp.cc",
)

cc_test(
    name = "linkstamp_test",
    srcs = ["linkstamp_test.cc"],
    stamp = 1,
    deps = [":linkstamp_lib"],
)

cc_test(
    name = "hello_asm_test",
    srcs = ["hello.S"],
)

cc_library(
    name = "loadable_library",
    srcs = ["loadable_library.cc"],
    hdrs = ["loadable_library.h"],
)

cc_shared_library(
    name = "loadable_library_so",
    deps = [":loadable_library"],
)

cc_test(
    name = "loadable_library_test",
    srcs = ["loadable_library_test.cc"],
    dynamic_deps = [":loadable_library_so"],
    deps = [":loadable_library"],
)

cc_library(
    name = "nested_library",
    srcs = ["loadable_library.cc"],
    deps = [":loadable_library"],
)

cc_shared_library(
    name = "nested_library_so",
    dynamic_deps = [":loadable_library_so"],
    deps = [":nested_library"],
)
