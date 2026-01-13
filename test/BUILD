load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("//rules:apple_genrule.bzl", "apple_genrule")
load(":apple_support_test.bzl", "apple_support_test")
load(":available_xcodes_test.bzl", "available_xcodes_test")
load(":xcode_config_test.bzl", "xcode_config_test")
load(":xcode_support_test.bzl", "xcode_support_test")
load(":xcode_version_test.bzl", "xcode_version_test")

licenses(["notice"])

# Custom rules that test rule-context APIs. Check their implementations for more details.
apple_support_test(name = "apple_support_test")

available_xcodes_test(name = "available_xcodes_test")

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

apple_genrule(
    name = "simple_genrule",
    outs = ["simple_genrule.txt"],
    cmd = "printenv | grep \"^\\(DEVELOPER_DIR\\|SDKROOT\\)\" > $(@)",
)

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    deps = [
        "//build_settings:build_settings_bzl",
        "//lib:apple_support",
        "//lib:xcode_support",
        "//xcode:available_xcodes",
        "//xcode:xcode_config",
        "//xcode:xcode_version",
        "@bazel_skylib//lib:unittest",
    ],
)
