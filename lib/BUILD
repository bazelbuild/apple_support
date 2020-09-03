load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

exports_files([
    "apple_support.bzl",
    "repositories.bzl",
    "xcode_support.bzl",
])

# Public bzl_library for anything that needs to depend on apple_support.bzl.
bzl_library(
    name = "apple_support",
    srcs = ["apple_support.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "@bazel_skylib//lib:types",
    ],
)

# Public bzl_library for anything that needs to depend on xcode_support.bzl.
bzl_library(
    name = "xcode_support",
    srcs = ["xcode_support.bzl"],
    visibility = ["//visibility:public"],
)

# Declared here since bazel_tools does not have bzl_library targets
bzl_library(
    name = "bazel_tools",
    srcs = ["@bazel_tools//tools:bzl_srcs"],
)

# Public bzl_library for anything that needs to depend on repositories.bzl.
bzl_library(
    name = "repositories",
    srcs = ["repositories.bzl"],
    visibility = ["//visibility:public"],
    deps = [":bazel_tools"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)
