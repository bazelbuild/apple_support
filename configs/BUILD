load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//lib:selects.bzl", "selects")
load(":platforms.bzl", "APPLE_PLATFORMS_CONSTRAINTS")

package(default_visibility = ["//visibility:public"])

selects.config_setting_group(
    name = "apple",
    match_any = [
        cpu
        for cpu in APPLE_PLATFORMS_CONSTRAINTS.keys()
    ],
)

[
    config_setting(
        name = cpu,
        constraint_values = constraints,
    )
    for cpu, constraints in APPLE_PLATFORMS_CONSTRAINTS.items()
]

selects.config_setting_group(
    name = "any_device",
    match_any = [
        cpu
        for cpu, constraints in APPLE_PLATFORMS_CONSTRAINTS.items()
        if "@build_bazel_apple_support//constraints:device" in constraints
    ],
)

selects.config_setting_group(
    name = "any_simulator",
    match_any = [
        cpu
        for cpu, constraints in APPLE_PLATFORMS_CONSTRAINTS.items()
        if "@build_bazel_apple_support//constraints:simulator" in constraints
    ],
)

bzl_library(
    name = "platforms",
    srcs = ["platforms.bzl"],
    visibility = ["//visibility:public"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = True,
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)
