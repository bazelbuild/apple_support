# This package contains the build settings that are used by the Apple rules.
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(
    default_visibility = ["//visibility:public"],
)

licenses(["notice"])

bzl_library(
    name = "build_settings_bzl",
    srcs = ["build_settings.bzl"],
    parse_tests = True,
    deps = ["@bazel_skylib//rules:common_settings"],
)

filegroup(
    name = "for_bazel_tests",
    srcs = ["BUILD"],
    visibility = ["//:__pkg__"],
)
