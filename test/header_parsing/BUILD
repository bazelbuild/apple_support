load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_cc//cc:defs.bzl", "cc_library", "objc_library")

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
    name = "c_only_header_without_parse_headers_as_c",
    hdrs = ["c_only_header.h"],
    tags = ["manual"],
)

cc_library(
    name = "c_only_header",
    hdrs = ["c_only_header.h"],
    features = ["parse_headers_as_c"],
    visibility = ["//test:__subpackages__"],
)

cc_library(
    name = "valid_header",
    hdrs = ["valid_header.h"],
    visibility = ["//test:__subpackages__"],
)

objc_library(
    name = "valid_header_objc",
    hdrs = ["valid_header.h"],
)

build_test(
    name = "test",
    targets = [
        ":c_only_header",
        ":invalid_header_feature_disabled",
        ":valid_header",
        ":valid_header_objc",
    ],
)
