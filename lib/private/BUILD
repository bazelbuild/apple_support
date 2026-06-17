load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

package(
    default_visibility = ["//lib:__subpackages__"],
)

bzl_library(
    name = "providers",
    srcs = ["providers.bzl"],
    visibility = [
        "//lib:__subpackages__",
        "//test:__pkg__",
    ],
)
