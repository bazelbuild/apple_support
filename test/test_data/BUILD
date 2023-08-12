load(
    "//rules:universal_binary.bzl",
    "universal_binary",
)
load("//test:starlark_apple_binary.bzl", "starlark_apple_binary")

package(
    default_testonly = 1,
    default_visibility = ["//test:__subpackages__"],
)

TARGETS_UNDER_TEST_TAGS = [
    "manual",
    "notap",
]

cc_binary(
    name = "cc_test_binary",
    srcs = ["main.cc"],
    tags = TARGETS_UNDER_TEST_TAGS,
)

cc_library(
    name = "cc_main",
    srcs = ["main.cc"],
    tags = TARGETS_UNDER_TEST_TAGS,
)

universal_binary(
    name = "multi_arch_cc_binary",
    binary = ":cc_test_binary",
    tags = TARGETS_UNDER_TEST_TAGS,
)

starlark_apple_binary(
    name = "apple_binary",
    minimum_os_version = "13.0",
    platform_type = "macos",
    tags = TARGETS_UNDER_TEST_TAGS,
    deps = [":cc_main"],
)

cc_library(
    name = "cc_lib",
    srcs = ["lib.cc"],
    tags = TARGETS_UNDER_TEST_TAGS,
)

objc_library(
    name = "objc_lib",
    srcs = ["lib.m"],
    tags = TARGETS_UNDER_TEST_TAGS,
    deps = ["cc_lib"],
)

objc_library(
    name = "objc_main",
    srcs = ["main.m"],
    tags = TARGETS_UNDER_TEST_TAGS,
    deps = ["objc_lib"],
)

config_setting(
    name = "compiler_gcc",
    flag_values = {
        "@bazel_tools//tools/cpp:compiler": "gcc",
    },
)

config_setting(
    name = "supports_visionos",
    values = {"define": "supports_visionos=1"},
)

starlark_apple_binary(
    name = "visionos_binary",
    minimum_os_version = "1.0",
    platform_type = "visionos",
    tags = TARGETS_UNDER_TEST_TAGS,
    target_compatible_with = select({
        ":supports_visionos": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
    deps = [":objc_main"],
)
