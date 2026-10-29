load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

package(default_visibility = ["//:__subpackages__"])

exports_files(["providers.bzli"])

bzl_library(
    name = "providers",
    srcs = ["providers.bzl"],
)

bzl_library(
    name = "toolchain_flags",
    srcs = ["toolchain_flags.bzl"],
)
