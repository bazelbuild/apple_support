load("@rules_shell//shell:sh_library.bzl", "sh_library")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

exports_files([
    "verify_binary.sh",
    "verify_relative_oso.sh",
    "verify_object_hashes.sh",
])

sh_library(
    name = "bashunit",
    testonly = True,
    srcs = [
        "integration_test_setup.sh",
        "unittest.bash",
        "unittest_utils.sh",
    ],
    deps = [
        "@bazel_tools//tools/bash/runfiles",
    ],
)

sh_test(
    name = "libtool_test",
    size = "small",
    srcs = ["libtool_test.sh"],
    data = [
        ":bashunit",
        "//crosstool:apple-support-ar-wrapper",
        "@bazel_tools//tools/bash/runfiles",
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
