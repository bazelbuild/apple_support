# This package contains the build settings that are used by the Apple rules.
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(
    default_visibility = ["//visibility:public"],
)

licenses(["notice"])

bzl_library(
    name = "build_settings",
    srcs = ["build_settings.bzl"],
    deps = ["@bazel_skylib//rules:common_settings"],
)
