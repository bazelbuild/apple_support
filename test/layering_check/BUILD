load("@bazel_skylib//rules:build_test.bzl", "build_test")

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
