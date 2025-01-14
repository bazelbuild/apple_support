load("@rules_shell//shell:sh_test.bzl", "sh_test")

cc_library(
    name = "foo",
    srcs = ["foo.cc"],
)

cc_binary(
    name = "libbar.so",
    srcs = ["bar.cc"],
    linkshared = True,
)

cc_binary(
    name = "libbaz.dylib",
    srcs = ["baz.cc"],
    linkshared = True,
)

cc_test(
    name = "test",
    srcs = [
        "test.cc",
        ":libbar.so",
        ":libbaz.dylib",
    ],
    deps = [":foo"],
)

sh_test(
    name = "test-portable",
    srcs = ["test-portable.sh"],
    data = [":test"],
)
