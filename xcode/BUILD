load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//rules:common_settings.bzl", "bool_flag", "string_flag")
load("//xcode:xcode_config_resolver.bzl", "xcode_config_resolver")

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
    name = "xcode_config_resolver_lib",
    srcs = ["xcode_config_resolver.bzl"],
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

# TODO (b/469732626) - Rename to version_config once the migration is complete.
label_flag(
    name = "starlark_version_config",
    build_setting_default = "@bazel_tools//tools/cpp:host_xcodes",
)

# The source of truth for Xcode configuration resolution.
# Gates between the native field and the Starlark flag.
# TODO (b/469732626) - Remove this once the migration is complete.
xcode_config_resolver(
    name = "version_config",
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

string_flag(
    name = "ios_minimum_os",
    build_setting_default = "",
)

string_flag(
    name = "watchos_minimum_os",
    build_setting_default = "",
)

string_flag(
    name = "tvos_minimum_os",
    build_setting_default = "",
)

string_flag(
    name = "macos_minimum_os",
    build_setting_default = "",
)
