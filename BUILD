load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

exports_files(["LICENSE"])

# A bzl_library incase anything needs to depend on this for other libraries
# (like to then use stardoc).
bzl_library(
    name = "bzl_library",
    srcs = glob(["*.bzl"]),
    visibility = ["//visibility:public"],
    deps = [
        "//lib:bzl_library",
        "//rules:bzl_library",
    ],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = [
        "WORKSPACE",
        "//lib:for_bazel_tests",
        "//rules:for_bazel_tests",
        "//tools:for_bazel_tests",
    ],
    # Exposed publicly just so other rules can use this if they set up
    # integration tests that need to copy all the support files into
    # a temporary workspace for the tests.
    visibility = ["//visibility:public"],
)
