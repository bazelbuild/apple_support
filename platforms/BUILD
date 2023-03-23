load("//configs:platforms.bzl", "APPLE_PLATFORMS_CONSTRAINTS")

package(default_visibility = ["//visibility:public"])

[
    platform(
        name = cpu,
        constraint_values = constraints,
    )
    for cpu, constraints in APPLE_PLATFORMS_CONSTRAINTS.items()
]

alias(
    name = "macos_x86_64",
    actual = "darwin_x86_64",
)

alias(
    name = "macos_arm64",
    actual = "darwin_arm64",
)
