load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load(":xcode_toolchain.bzl", "xcode_install_name_tool_toolchain")

licenses(["notice"])

package(default_visibility = ["//visibility:public"])

toolchain_type(name = "toolchain_type")

sh_binary(
    name = "install_name_tool_wrapper",
    srcs = ["install_name_tool_wrapper.sh"],
    visibility = ["//visibility:private"],
)

xcode_install_name_tool_toolchain(
    name = "install_name_tool_toolchain",
    tool = ":install_name_tool_wrapper",
)

toolchain(
    name = "default_toolchain",
    exec_compatible_with = ["@platforms//os:macos"],
    toolchain = ":install_name_tool_toolchain",
    toolchain_type = ":toolchain_type",
)

filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)

bzl_library(
    name = "xcode_toolchain",
    srcs = ["xcode_toolchain.bzl"],
    deps = [
        ":toolchain",
        "//lib:apple_support",
    ],
)

bzl_library(
    name = "install_name_tool",
    srcs = ["install_name_tool.bzl"],
)

bzl_library(
    name = "toolchain",
    srcs = ["toolchain.bzl"],
)
