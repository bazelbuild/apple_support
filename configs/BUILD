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
        values = {"cpu": cpu},
    )
    for cpu in APPLE_PLATFORMS_CONSTRAINTS.keys()
]

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = True,
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)
