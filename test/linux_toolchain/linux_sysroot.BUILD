load("@bazel_skylib//rules/directory:directory.bzl", "directory")

package(default_visibility = ["//visibility:public"])

directory(
    name = "root",
    srcs = glob(["**/*"]),
)

# NOTE: Using this is better for merkle tree performance
filegroup(
    name = "directory",
    srcs = ["."],
)
