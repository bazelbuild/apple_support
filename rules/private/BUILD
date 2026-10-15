load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":apple_genrule.bzl", "apple_genrule_toolchain")

licenses(["notice"])

toolchain_type(
    name = "apple_genrule_toolchain_type",
    visibility = ["//visibility:public"],
)

apple_genrule_toolchain(name = "macos_toolchain")

toolchain(
    name = "macos_apple_genrule_toolchain",
    exec_compatible_with = ["@platforms//os:macos"],
    toolchain = ":macos_toolchain",
    toolchain_type = ":apple_genrule_toolchain_type",
    visibility = ["//visibility:public"],
)

# Public bzl_library for anything that needs to depend on apple_genrule.bzl.
bzl_library(
    name = "apple_genrule",
    srcs = ["apple_genrule.bzl"],
    visibility = [
        "//rules:__pkg__",
    ],
    deps = ["//lib:apple_support"],
)
