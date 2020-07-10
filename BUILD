load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

exports_files(["LICENSE"])

# An umbrella bzl_library for anything that needs it (like to then use stardoc),
# but odds are using the specific sub bzl_library to with the public bzl files
# are a better choice to get the proper subset of dependencies.
bzl_library(
    name = "apple_support",
    visibility = ["//visibility:public"],
    deps = [
        "//lib:apple_support",
        "//lib:xcode_support",
        "//rules:apple_genrule",
    ],
)

alias(
    name = "bzl_library",
    actual = ":apple_support",
    deprecation = (
        "bzl_library will go away in the future, please directly depend on the" +
        " public file's bzl_library being used: lib:apple_support," +
        " lib:xcode_support, or rules:apple_genrule."
    ),
    visibility = ["//visibility:public"],
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
