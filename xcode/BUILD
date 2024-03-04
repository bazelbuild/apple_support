load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

package(
    default_visibility = ["//visibility:public"],
)

bzl_library(
    name = "available_xcodes",
    srcs = ["available_xcodes.bzl"],
    visibility = ["//visibility:private"],
)

bzl_library(
    name = "xcode_config",
    srcs = ["xcode_config.bzl"],
    visibility = ["//visibility:private"],
)

bzl_library(
    name = "xcode_config_alias",
    srcs = ["xcode_config_alias.bzl"],
    visibility = ["//visibility:private"],
)

bzl_library(
    name = "xcode_version",
    srcs = ["xcode_version.bzl"],
    visibility = ["//visibility:private"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = True,
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)
