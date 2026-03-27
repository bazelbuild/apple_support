load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load(":xcode_lipo_toolchain.bzl", "xcode_lipo_toolchain")

licenses(["notice"])

package(
    default_visibility = ["//visibility:public"],
)

toolchain_type(
    name = "toolchain_type",
)

sh_binary(
    name = "lipo",
    srcs = ["lipo.sh"],
)

xcode_lipo_toolchain(
    name = "lipo_toolchain",
    lipo = ":lipo",
)

toolchain(
    name = "default_lipo_toolchain",
    exec_compatible_with = ["@platforms//os:macos"],
    toolchain = ":lipo_toolchain",
    toolchain_type = ":toolchain_type",
)

bzl_library(
    name = "lipo_toolchain_lib",
    srcs = ["lipo_toolchain.bzl"],
)

bzl_library(
    name = "xcode_lipo_toolchain_lib",
    srcs = ["xcode_lipo_toolchain.bzl"],
    deps = [":lipo_toolchain_lib"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)
