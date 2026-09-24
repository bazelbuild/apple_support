load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_cc//cc:defs.bzl", "cc_library", "cc_test", "objc_library")
load(":compile_without_module_maps.bzl", "compile_without_module_maps")

package(features = ["layering_check"])

cc_library(
    name = "a",
    hdrs = ["a.h"],
)

cc_library(
    name = "b",
    hdrs = ["b.h"],
    deps = [":a"],
)

cc_test(
    name = "bad_layering_check",
    srcs = ["c.cpp"],
    tags = ["manual"],
    deps = [":b"],
)

cc_test(
    name = "disabled_bad_layering_check",
    srcs = ["c.cpp"],
    features = ["-layering_check"],
    deps = [":b"],
)

cc_test(
    name = "good_layering_check",
    srcs = ["c.cpp"],
    deps = [
        ":a",
        ":b",
    ],
)

objc_library(
    name = "bad_layering_check_objc",
    srcs = ["c.m"],
    tags = ["manual"],
    deps = [":b"],
)

build_test(
    name = "bad_layering_check_objc_test",
    tags = ["manual"],
    targets = [":bad_layering_check_objc"],
)

objc_library(
    name = "disabled_bad_layering_check_objc",
    srcs = ["c.m"],
    features = ["-layering_check"],
    deps = [":b"],
)

build_test(
    name = "disabled_bad_layering_check_objc_test",
    targets = [":disabled_bad_layering_check_objc"],
)

objc_library(
    name = "good_layering_check_objc",
    srcs = ["c.m"],
    deps = [
        ":a",
        ":b",
    ],
)

build_test(
    name = "good_layering_check_objc_test",
    targets = [":good_layering_check_objc"],
)

# layering_check is requested for the whole package, but must be dropped for rules that declare
# module_maps as unsupported instead of failing on the missing module map variables.
compile_without_module_maps(
    name = "compile_without_module_maps",
)

build_test(
    name = "compile_without_module_maps_test",
    targets = [":compile_without_module_maps"],
)
