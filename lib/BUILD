load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

# Public bzl_library for anything that needs to depend on apple_support.bzl.
bzl_library(
    name = "apple_support",
    srcs = ["apple_support.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "@bazel_skylib//lib:types",
    ],
)

bzl_library(
    name = "lipo",
    srcs = ["lipo.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        ":apple_support",
    ],
)

bzl_library(
    name = "transitions",
    srcs = ["transitions.bzl"],
    visibility = ["//visibility:public"],
)

# Public bzl_library for anything that needs to depend on xcode_support.bzl.
bzl_library(
    name = "xcode_support",
    srcs = ["xcode_support.bzl"],
    visibility = ["//visibility:public"],
)

# Public bzl_library for anything that needs to depend on repositories.bzl.
bzl_library(
    name = "repositories",
    srcs = ["repositories.bzl"],
    visibility = ["//visibility:public"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)
