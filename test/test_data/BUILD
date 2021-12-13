load(
    "//rules:universal_binary.bzl",
    "universal_binary",
)

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

universal_binary(
    name = "multi_arch_cc_binary",
    binary = ":cc_test_binary",
    tags = TARGETS_UNDER_TEST_TAGS,
)
