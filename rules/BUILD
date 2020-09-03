load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

exports_files([
    "apple_genrule.bzl",
])

bzl_library(
    name = "build",
    srcs = [
        "@bazel_tools//tools/python:private/defs.bzl",
        "@bazel_tools//tools/python:srcs_version.bzl",
        "@bazel_tools//tools/python:toolchain.bzl",
        "@bazel_tools//tools/python:utils.bzl",
    ],
)

# Public bzl_library for anything that needs to depend on apple_genrule.bzl.
bzl_library(
    name = "apple_genrule",
    srcs = ["apple_genrule.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//lib:apple_support",
        "@bazel_skylib//lib:dicts",
        "@bazel_skylib//lib:paths",
    ],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)
