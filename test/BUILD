load("//rules:apple_genrule.bzl", "apple_genrule")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//rules:build_test.bzl", "build_test")
load(":apple_support_test.bzl", "apple_support_test")
load(":universal_binary_test.bzl", "universal_binary_test")
load(":xcode_support_test.bzl", "xcode_support_test")

licenses(["notice"])

# Custom rules that test rule-context APIs. Check their implementations for more details.
apple_support_test(name = "apple_support_test")

xcode_support_test(name = "xcode_support_test")

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
