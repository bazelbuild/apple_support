load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

exports_files(["rules.doc.bzl"])

# Public bzl_library for anything that needs to depend on apple_genrule.bzl.
bzl_library(
    name = "apple_genrule",
    srcs = ["apple_genrule.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//rules/private:apple_genrule",
    ],
)

bzl_library(
    name = "universal_binary",
    srcs = ["universal_binary.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//lib:apple_support",
        "//lib:lipo",
        "//lib:transitions",
        "@bazel_skylib//lib:dicts",
    ],
)

bzl_library(
    name = "rules",
    srcs = ["rules.doc.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        ":universal_binary",
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
