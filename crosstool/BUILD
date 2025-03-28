load("@build_bazel_apple_support//rules:apple_genrule.bzl", "apple_genrule")
load("@rules_cc//cc:defs.bzl", "cc_binary")

package(default_visibility = ["//visibility:public"])

# Files which shouldn't be publicly visible and dependencies of all objc_* or ios_* rules should be excluded.
exports_files(glob(
    ["**"],
))

# TODO: Remove when we drop bazel 6.x
filegroup(
    name = "xcrunwrapper",
    srcs = [":xcrunwrapper.sh"],
)

cc_binary(
    name = "wrapped_clang",
    testonly = True,
    srcs = [
        "wrapped_clang.cc",
    ],
    copts = ["-std=c++17"],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = True,
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)

apple_genrule(
    name = "generate_layering_check_modulemap",
    outs = ["layering_check.modulemap"],
    cmd = "$(location generate-modulemap.sh) > $(OUTS)",
    tags = ["manual"],
    tools = ["generate-modulemap.sh"],
)
