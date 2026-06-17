load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

exports_files(["LICENSE"])

# An umbrella bzl_library for anything that needs it (like to then use stardoc),
# but odds are using the specific sub bzl_library to with the public bzl files
# are a better choice to get the proper subset of dependencies.
bzl_library(
    name = "apple_support",
    visibility = ["//visibility:public"],
    deps = [
        "//lib:apple_support",
        "//lib:lipo",
        "//lib:xcode_support",
        "//rules:apple_genrule",
    ],
)
