load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

package(
    default_visibility = ["//visibility:public"],
)

# Public bzl_library for anything that needs to depend on apple_genrule.bzl.
bzl_library(
    name = "apple_genrule",
    srcs = ["apple_genrule.bzl"],
    deps = [
        "//rules/private:apple_genrule",
    ],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["**"]) + [
        "//rules/private:for_bazel_tests",
    ],
    visibility = ["//:__pkg__"],
)
