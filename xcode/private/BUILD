load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

package(
    default_visibility = ["//xcode:__subpackages__"],
)

bzl_library(
    name = "providers",
    srcs = ["providers.bzl"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = True,
    srcs = glob(["**"]),
    visibility = ["//xcode:__pkg__"],
)
