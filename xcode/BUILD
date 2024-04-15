load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

package(
    default_visibility = ["//visibility:public"],
)

bzl_library(
    name = "available_xcodes",
    srcs = ["available_xcodes.bzl"],
)

bzl_library(
    name = "providers",
    srcs = ["providers.bzl"],
)

bzl_library(
    name = "xcode_config",
    srcs = ["xcode_config.bzl"],
)

bzl_library(
    name = "xcode_config_alias",
    srcs = ["xcode_config_alias.bzl"],
)

bzl_library(
    name = "xcode_version",
    srcs = ["xcode_version.bzl"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = True,
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)
