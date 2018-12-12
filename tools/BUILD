licenses(["notice"])

package(default_visibility = ["//visibility:public"])

# Additional files, such as tools, that should be present in a test's runfiles
# during coverage collection.
filegroup(name = "coverage_support")

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
