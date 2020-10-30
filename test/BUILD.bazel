load("//rules:apple_genrule.bzl", "apple_genrule")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":apple_support_test.bzl", "apple_support_test")
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

apple_genrule(
    name = "simple_genrule",
    outs = ["simple_genrule.txt"],
    cmd = "printenv | grep \"^\\(DEVELOPER_DIR\\|SDKROOT\\)\" > $(@)",
)

bzl_library(
    name = "starlark_tests_bzls",
    srcs = glob(["*.bzl"]),
    deps = [
        "//lib:apple_support",
        "//lib:xcode_support",
    ],
)
