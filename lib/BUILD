load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

package(
    default_visibility = ["//visibility:public"],
)

# Public bzl_library for anything that needs to depend on apple_support.bzl.
bzl_library(
    name = "apple_support",
    srcs = ["apple_support.bzl"],
    deps = [
        "//lib/private:providers",
        "@bazel_skylib//lib:types",
    ],
)

bzl_library(
    name = "providers",
    srcs = ["providers.bzl"],
    deps = [
        "//lib/private:providers",
    ],
)

bzl_library(
    name = "lipo",
    srcs = ["lipo.bzl"],
    deps = [
        ":apple_support",
        "@bazel_skylib//lib:shell",
    ],
)

# Public bzl_library for anything that needs to depend on xcode_support.bzl.
bzl_library(
    name = "xcode_support",
    srcs = ["xcode_support.bzl"],
    deps = ["//xcode:providers"],
)

# Public bzl_library for anything that needs to depend on repositories.bzl.
bzl_library(
    name = "repositories",
    srcs = ["repositories.bzl"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["**"]) + [
        "//lib/private:for_bazel_tests",
    ],
    visibility = ["//:__pkg__"],
)
