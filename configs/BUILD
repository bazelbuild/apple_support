load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//lib:selects.bzl", "selects")
load(":platforms.bzl", "APPLE_DEVICE_CPUS", "APPLE_PLATFORMS_CONSTRAINTS", "APPLE_SIMULATOR_CPUS")

package(default_visibility = ["//visibility:public"])

selects.config_setting_group(
    name = "apple",
    match_any = [
        cpu
        for cpu in APPLE_PLATFORMS_CONSTRAINTS.keys()
    ] + [
        "@apple_support//constraints:apple",
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
    match_any = APPLE_DEVICE_CPUS,
)

selects.config_setting_group(
    name = "any_simulator",
    match_any = APPLE_SIMULATOR_CPUS,
)

bzl_library(
    name = "platforms",
    srcs = ["platforms.bzl"],
    visibility = ["//visibility:public"],
)
