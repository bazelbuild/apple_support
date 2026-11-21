load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load(":xcode_toolchain.bzl", "xcode_lipo_toolchain")

licenses(["notice"])

package(default_visibility = ["//visibility:public"])

exports_files(["toolchain.bzli"])

toolchain_type(name = "toolchain_type")

sh_binary(
    name = "lipo",
    srcs = ["lipo.sh"],
    visibility = ["//visibility:private"],
)

xcode_lipo_toolchain(
    name = "lipo_toolchain",
    tool = ":lipo",
)

toolchain(
    name = "default_lipo_toolchain",
    exec_compatible_with = ["@platforms//os:macos"],
    target_compatible_with = ["@platforms//os:macos"],
    toolchain = ":lipo_toolchain",
    toolchain_type = ":toolchain_type",
)

filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["**"]),
    visibility = ["//:__subpackages__"],
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
    name = "toolchain",
    srcs = ["toolchain.bzl"],
)
