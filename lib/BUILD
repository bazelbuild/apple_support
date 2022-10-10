load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

# This target is mainly for use by rules_apple and rules_swift.
# When this target is linked into an XCTest binary, and the
# `BUILD_WORKSPACE_DIRECTORY` environment variable is set, the relative paths of
# `XCTSourceCodeLocation` are made absolute, fixing Test Issue navigation in
# Xcode.
objc_library(
    name = "swizzle_absolute_xcttestsourcelocation",
    testonly = True,
    srcs = ["swizzle_absolute_xcttestsourcelocation.m"],
    target_compatible_with = select({
        "@platforms//os:ios": [],
        "@platforms//os:macos": [],
        "@platforms//os:tvos": [],
        "@platforms//os:watchos": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
    visibility = ["//visibility:public"],
    alwayslink = True,
)

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
        "@bazel_skylib//lib:shell",
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
