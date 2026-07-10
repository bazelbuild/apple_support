load("@rules_cc//cc:defs.bzl", "cc_test")

platform(
    name = "linux_x86_64",
    constraint_values = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    visibility = ["//visibility:public"],
)

toolchain(
    name = "linux_toolchain",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    target_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    toolchain = "@swift_linux_toolchain//:cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

cc_test(
    name = "smoke_test",
    srcs = ["smoke.c"],
    target_compatible_with = ["@platforms//os:linux"],
)
