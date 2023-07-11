exports_files(["verify_binary.sh"])

filegroup(
    name = "for_bazel_tests",
    testonly = True,
    srcs = [
        "@build_bazel_apple_support//:for_bazel_tests",
    ],
)

sh_library(
    name = "bashunit",
    testonly = True,
    srcs = [
        "integration_test_setup.sh",
        "testenv.sh",
        "unittest.bash",
        "unittest_utils.sh",
    ],
    deps = [
        "@bazel_tools//tools/bash/runfiles",
    ],
)

sh_library(
    name = "apple_common",
    testonly = True,
    srcs = ["apple_common.sh"],
)

sh_test(
    name = "objc_test",
    size = "large",
    srcs = ["objc_test.sh"],
    data = [":for_bazel_tests"],
    deps = [
        ":apple_common",
        ":bashunit",
    ],
)

sh_test(
    name = "apple_test",
    srcs = ["apple_test.sh"],
    data = [":for_bazel_tests"],
    shard_count = 3,
    deps = [
        ":apple_common",
        ":bashunit",
    ],
)

sh_test(
    name = "wrapped_clang_test",
    size = "small",
    srcs = ["wrapped_clang_test.sh"],
    data = [
        ":bashunit",
        "//crosstool:wrapped_clang",
        "@bazel_tools//tools/bash/runfiles",
    ],
)
