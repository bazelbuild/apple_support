licenses(["notice"])

exports_files(["LICENSE"])

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = [
        "WORKSPACE",
        "@build_bazel_apple_support//lib:for_bazel_tests",
        "@build_bazel_apple_support//rules:for_bazel_tests",
        "@build_bazel_apple_support//tools:for_bazel_tests",
    ],
    # Exposed publicly just so other rules can use this if they set up
    # integration tests that need to copy all the support files into
    # a temporary workspace for the tests.
    visibility = ["//visibility:public"],
)
