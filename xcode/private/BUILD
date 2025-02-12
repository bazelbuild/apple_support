load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    "//xcode:xcode_sdk_variant.bzl",
    "xcode_sdk_variant",
)

licenses(["notice"])

package(
    default_visibility = ["//xcode:__subpackages__"],
)

bzl_library(
    name = "providers",
    srcs = ["providers.bzl"],
)

# The `config_setting`s below are NOT intended for general use. These specific
# names have been chosen to simplify how references to them are constructed by
# the tooling that generates the `xcode_version` and `xcode_sdk_variant`
# targets.

package_group(
    name = "xcode_sdk_variant_config_setting_users",
    packages = [
        "@bazel_tools//tools/osx",
        "@bazel_tools//tools/osx/xcode_config",
    ],
)

config_setting(
    name = "is_appletvos",
    constraint_values = [
        "@platforms//os:tvos",
        "//constraints:device",
    ],
    visibility = [":xcode_sdk_variant_config_setting_users"],
)

config_setting(
    name = "is_appletvsimulator",
    constraint_values = [
        "@platforms//os:tvos",
        "//constraints:simulator",
    ],
    visibility = [":xcode_sdk_variant_config_setting_users"],
)

config_setting(
    name = "is_iphoneos",
    constraint_values = [
        "@platforms//os:ios",
        "//constraints:device",
    ],
    visibility = [":xcode_sdk_variant_config_setting_users"],
)

config_setting(
    name = "is_iphonesimulator",
    constraint_values = [
        "@platforms//os:ios",
        "//constraints:simulator",
    ],
    visibility = [":xcode_sdk_variant_config_setting_users"],
)

config_setting(
    name = "is_macosx",
    constraint_values = [
        "@platforms//os:macos",
    ],
    visibility = [":xcode_sdk_variant_config_setting_users"],
)

config_setting(
    name = "is_watchos",
    constraint_values = [
        "@platforms//os:watchos",
        "//constraints:device",
    ],
    visibility = [":xcode_sdk_variant_config_setting_users"],
)

config_setting(
    name = "is_watchsimulator",
    constraint_values = [
        "@platforms//os:watchos",
        "//constraints:simulator",
    ],
    visibility = [":xcode_sdk_variant_config_setting_users"],
)

config_setting(
    name = "is_xros",
    constraint_values = [
        "@platforms//os:visionos",
        "//constraints:device",
    ],
    visibility = [":xcode_sdk_variant_config_setting_users"],
)

config_setting(
    name = "is_xrsimulator",
    constraint_values = [
        "@platforms//os:visionos",
        "//constraints:simulator",
    ],
    visibility = [":xcode_sdk_variant_config_setting_users"],
)

# An empty SDK that is used as the default entry in `select` expressions so that
# non-configured queries/builds don't fail during analysis just because they
# touched the Xcode targets.
xcode_sdk_variant(
    name = "empty_sdk",
    visibility = [":xcode_sdk_variant_config_setting_users"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = True,
    srcs = glob(["**"]),
    visibility = ["//xcode:__pkg__"],
)
