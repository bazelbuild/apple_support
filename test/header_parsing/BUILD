load("@bazel_skylib//rules:build_test.bzl", "build_test")

package(features = ["parse_headers"])

cc_library(
    name = "invalid_header",
    hdrs = ["invalid_header.h"],
    tags = ["manual"],
)

objc_library(
    name = "invalid_header_objc",
    hdrs = ["invalid_header.h"],
    tags = ["manual"],
)

cc_library(
    name = "invalid_header_feature_disabled",
    hdrs = ["invalid_header.h"],
    features = ["-parse_headers"],
)

cc_library(
    name = "valid_header",
    hdrs = ["valid_header.h"],
)

objc_library(
    name = "valid_header_objc",
    hdrs = ["valid_header.h"],
)

build_test(
    name = "test",
    targets = [
        ":invalid_header_feature_disabled",
        ":valid_header",
        ":valid_header_objc",
    ],
)
