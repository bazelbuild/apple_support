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
