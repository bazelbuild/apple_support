load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

# For the bzl_library at the root of the apple_support.
bzl_library(
    name = "bzl_library",
    srcs = glob(["*.bzl"]),
    visibility = ["//:__pkg__"],
    deps = ["@bazel_skylib//lib:types"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)
