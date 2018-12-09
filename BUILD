package(default_visibility = ["//visibility:public"])

licenses(["notice"])

exports_files(["LICENSE"])

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = [
        "WORKSPACE",
        "@build_bazel_apple_support//lib:for_bazel_tests",
        "@build_bazel_apple_support//tools:for_bazel_tests",
    ],
)
