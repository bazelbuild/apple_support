licenses(["notice"])

package(default_visibility = ["//visibility:public"])

sh_binary(
    name = "xcode_path_wrapper",
    srcs = ["xcode_path_wrapper.sh"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["**"]),
)
