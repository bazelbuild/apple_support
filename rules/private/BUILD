load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":apple_genrule.bzl", "execution_platform_info")

licenses(["notice"])

execution_platform_info(name = "execution_platform")

# Public bzl_library for anything that needs to depend on apple_genrule.bzl.
bzl_library(
    name = "apple_genrule",
    srcs = ["apple_genrule.bzl"],
    visibility = [
        "//rules:__pkg__",
    ],
    deps = ["//lib:apple_support"],
)
