load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

package(
    default_visibility = ["//visibility:public"],
)

bzl_library(
    name = "available_xcodes",
    srcs = ["available_xcodes.bzl"],
    deps = ["//xcode/private:providers"],
)

bzl_library(
    name = "providers",
    srcs = ["providers.bzl"],
)

bzl_library(
    name = "xcode_config",
    srcs = ["xcode_config.bzl"],
    deps = ["//xcode/private:providers"],
)

bzl_library(
    name = "xcode_config_alias",
    srcs = ["xcode_config_alias.bzl"],
    deps = ["//xcode/private:providers"],
)

bzl_library(
    name = "xcode_version",
    srcs = ["xcode_version.bzl"],
    deps = [
        ":providers",
        "//xcode/private:providers",
    ],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = True,
    srcs = glob(["**"]) + [
        "//xcode/private:for_bazel_tests",
    ],
    visibility = ["//:__pkg__"],
)
