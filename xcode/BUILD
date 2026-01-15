load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//rules:common_settings.bzl", "bool_flag", "string_flag")

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
    deps = [
        "//build_settings:build_settings_bzl",
        "//xcode/private:providers",
    ],
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

string_flag(
    name = "version",
    build_setting_default = "",
    scope = "universal",
)

bool_flag(
    name = "experimental_prefer_mutual_xcode",
    build_setting_default = True,
)

bool_flag(
    name = "include_xcode_exec_requirements",
    build_setting_default = False,
    scope = "universal",
)
